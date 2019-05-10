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

    enum ClassificationCameraViewType {
        case camera
        case photo
    }
    
    private let visionModel: VNCoreMLModel
    
    private let session = AVCaptureSession()
    
    private let captureQueue = DispatchQueue(label: "captureQueue")
    
    private var visionRequests: [VNRequest] = []
    
    private var photoButton: UIButton = {
        let button = UIButton()
        
        button.setTitle("Take photo", for: .normal)
        button.setTitleColor(.blue, for: .normal)
        button.layer.cornerRadius = 5
        button.layer.borderWidth = 1
        button.layer.borderColor = UIColor.blue.cgColor
        
        return button
    }()
    
    private var imageView: UIImageView = {
        let imageView = UIImageView()
        
        imageView.contentMode = .scaleAspectFit
        
        return imageView
    }()
    
    
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
    
    init(type: ClassificationCameraViewType) {
        guard let visionModel = try? VNCoreMLModel(for: BirthmarksClassifier().model) else {
            fatalError("Could not load model")
        }
        self.visionModel = visionModel
        super.init(frame: .zero)
        
        switch type {
        case .camera:
            setupCamera()
        case .photo:
            setupPhoto()
        }
    }
    
    private func setupPhoto() {
        backgroundColor = .white
        
        photoButton.addTarget(self, action: #selector(takePhotoButtonTap), for: .touchUpInside)
        
        [photoButton, imageView].forEach(addSubview)
        
        imageView.snp.makeConstraints { make in
            make.top.left.right.equalToSuperview()
            make.height.equalTo(imageView.snp.width)
        }
        
        photoButton.snp.makeConstraints { make in
            make.top.equalTo(imageView.snp.bottom).offset(15)
            make.centerX.equalToSuperview()
            make.height.equalTo(42)
            make.width.equalTo(120)
        }
        
        self.snp.makeConstraints { make in
            make.bottom.equalTo(photoButton).offset(10)
        }
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
    
    
    @objc private func takePhotoButtonTap() {
        let imagePickerVC = UIImagePickerController()
        imagePickerVC.sourceType = .camera
        imagePickerVC.allowsEditing = true
        imagePickerVC.delegate = self
        
        let vc = (UIApplication.shared.delegate as? AppDelegate)?.getCurrentViewController()
        vc?.present(imagePickerVC, animated: true)
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
        
        DispatchQueue.global(qos: .userInitiated).async {
            let imageRequestHandler = VNImageRequestHandler(
                cvPixelBuffer: pixelBuffer,
                orientation: .up ,
                options: requestOptions)
            
            DispatchQueue.global(qos: .userInitiated).async {
                do {
                    try imageRequestHandler.perform(self.visionRequests)
                } catch {
                    print("Failed to perform classification.\n\(error.localizedDescription)")
                }
            }
        }
    }
}

extension ClassificationCameraView: UIImagePickerControllerDelegate & UINavigationControllerDelegate  {
    func imagePickerController(_ picker: UIImagePickerController,
                               didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        picker.dismiss(animated: true)
        
        guard let image = info[.editedImage] as? UIImage,
            let ciImage = CIImage(image: image),
            let orientation = CGImagePropertyOrientation(rawValue: UInt32(image.imageOrientation.rawValue))
            else {
                imageView.image = .none
                fatalError("Unable to create \(CIImage.self).")
        }
        
        imageView.image = image
        
        DispatchQueue.global(qos: .userInitiated).async {
            let handler = VNImageRequestHandler(ciImage: ciImage, orientation: orientation)
            do {
                try handler.perform(self.visionRequests)
            } catch {
                print("Failed to perform classification.\n\(error.localizedDescription)")
                self.imageView.image = .none
            }
        }
    }
}
