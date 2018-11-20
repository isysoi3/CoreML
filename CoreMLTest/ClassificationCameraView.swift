//
//  View.swift
//  CoreMLTest
//
//  Created by Ilya Sysoi on 11/20/18.
//  Copyright © 2018 BeSmart-Mobile. All rights reserved.
//

import UIKit
import AVFoundation
import Vision

class ClassificationCameraView: UIView {

    let session = AVCaptureSession()
    var previewLayer: AVCaptureVideoPreviewLayer!
    let captureQueue = DispatchQueue(label: "captureQueue")
    var visionRequests = [VNRequest]()
    let handleClassifications: (VNRequest, Error?) -> ()
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    init(handleClassifications: @escaping (VNRequest, Error?) -> ()) {
        self.handleClassifications = handleClassifications
        super.init(frame: .zero)
        
        setupCamera()
    }
    
    private func setupCamera() {
        guard let camera = AVCaptureDevice.default(for: .video) else {
            return
        }
        do {
            previewLayer = AVCaptureVideoPreviewLayer(session: session)
            layer.addSublayer(previewLayer)
            
            let cameraInput = try AVCaptureDeviceInput(device: camera)
            let videoOutput = AVCaptureVideoDataOutput()
            videoOutput.setSampleBufferDelegate(self,
                                                queue: captureQueue)
            videoOutput.alwaysDiscardsLateVideoFrames = true
            videoOutput.videoSettings = [kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA]
            
            session.sessionPreset = .high
            session.addInput(cameraInput)
            session.addOutput(videoOutput)
            
            let connection = videoOutput.connection(with: .video)
            connection?.videoOrientation = .portrait
            session.startRunning()
            
            guard let visionModel = try? VNCoreMLModel(for: Inceptionv3().model) else {
                fatalError("Could not load model")
            }
            
            let classificationRequest = VNCoreMLRequest(model: visionModel, completionHandler: handleClassifications)
            classificationRequest.imageCropAndScaleOption = VNImageCropAndScaleOption.centerCrop
            visionRequests = [classificationRequest]
        } catch {
            let alertController = UIAlertController(title: nil, message: error.localizedDescription, preferredStyle: .alert)
            alertController.addAction(UIAlertAction(title: "Ok", style: .default, handler: nil))
//            present(alertController, animated: true, completion: nil)
        }
    }
}


// MARK:- CameraView: AVCaptureVideoDataOutputSampleBufferDelegate
extension ClassificationCameraView: AVCaptureVideoDataOutputSampleBufferDelegate {
    
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else {
            return
        }
        
        var requestOptions: [VNImageOption: Any] = [:]
        if let cameraIntrinsicData = CMGetAttachment(sampleBuffer, key: kCMSampleBufferAttachmentKey_CameraIntrinsicMatrix, attachmentModeOut: nil) {
            requestOptions = [.cameraIntrinsics: cameraIntrinsicData]
        }
        
        let imageRequestHandler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, orientation: CGImagePropertyOrientation.up, options: requestOptions)
        do {
            try imageRequestHandler.perform(visionRequests)
        } catch {
            print(error)
        }
    }
}
