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

    private let visionModel: VNCoreMLModel
    private let session = AVCaptureSession()
    private let captureQueue = DispatchQueue(label: "captureQueue")
    private var visionRequests: [VNRequest] = []
    
    var previewLayer: AVCaptureVideoPreviewLayer!
    
    var handleClassifications: ((VNRequest, Error?) -> ())! {
        didSet {
            let classificationRequest = VNCoreMLRequest(model: visionModel,
                                                        completionHandler: handleClassifications)
            classificationRequest.imageCropAndScaleOption = .centerCrop
            visionRequests = [classificationRequest]
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    init() {
        guard let visionModel = try? VNCoreMLModel(for: Inceptionv3().model) else {
            fatalError("Could not load model")
        }
        self.visionModel = visionModel
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
            
        } catch {
            fatalError(error.localizedDescription)
        }
    }
}


// MARK:- ClassificationCameraView: AVCaptureVideoDataOutputSampleBufferDelegate
extension ClassificationCameraView: AVCaptureVideoDataOutputSampleBufferDelegate {
    
    func captureOutput(_ output: AVCaptureOutput,
                       didOutput sampleBuffer: CMSampleBuffer,
                       from connection: AVCaptureConnection) {
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else {
            return
        }
        
        var requestOptions: [VNImageOption: Any] = [:]
        if let cameraIntrinsicData = CMGetAttachment(sampleBuffer,
                                                     key: kCMSampleBufferAttachmentKey_CameraIntrinsicMatrix,
                                                     attachmentModeOut: nil) {
            requestOptions = [.cameraIntrinsics: cameraIntrinsicData]
        }
        
        let imageRequestHandler = VNImageRequestHandler(
            cvPixelBuffer: pixelBuffer,
            orientation: .up ,
            options: requestOptions)
        
        do {
            try imageRequestHandler.perform(visionRequests)
        } catch {
            print(error)
        }
    }
}
