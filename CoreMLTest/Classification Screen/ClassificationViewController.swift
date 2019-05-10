//
//  ViewController.swift
//  CoreMLTest
//
//  Created by Ilya Sysoi on 11/19/18.
//  Copyright © 2018 BeSmart-Mobile. All rights reserved.
//

import UIKit
import Vision
import SnapKit

class ClassificationViewController: UIViewController {

    private var resultLabel: UILabel!
    private var classificationView: ClassificationCameraView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        initAndConfigureSubviews()
    }
    
    private func initAndConfigureSubviews() {
        resultLabel = UILabel()
        classificationView = ClassificationCameraView(type: .photo)
        
        classificationView.handleClassifications = handleClassifications
         
        resultLabel.numberOfLines = 0
        resultLabel.font = UIFont.boldSystemFont(ofSize: 25)
        resultLabel.textColor = #colorLiteral(red: 0, green: 0, blue: 0, alpha: 1)
        resultLabel.backgroundColor = #colorLiteral(red: 1, green: 1, blue: 1, alpha: 1)
        resultLabel.textAlignment = .center
        
        view.backgroundColor = #colorLiteral(red: 1, green: 1, blue: 1, alpha: 1)
        
        [classificationView, resultLabel].forEach {
            view.addSubview($0)
        }
        resultLabel.snp.makeConstraints { make in
            make.left.right.equalToSuperview().inset(15)
            make.top.equalTo(classificationView.snp.bottom).offset(15)
            make.bottom.equalTo(view.safeAreaLayoutGuide.snp.bottomMargin)
        }
        
        classificationView.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide.snp.topMargin)
            make.left.right.equalToSuperview()
            make.bottom.equalTo(resultLabel.snp.top).inset(10)
        }

    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        classificationView.previewLayer?.frame = classificationView.bounds
    }
    
    override var preferredStatusBarStyle : UIStatusBarStyle {
        return .lightContent
    }
    
    private func handleClassifications(request: VNRequest, error: Error?) {
        if let error = error {
            print(error.localizedDescription)
            return
        }
        guard let classifications = request.results as? [VNClassificationObservation] else {
            print("No results")
            return
        }
        
        //Malignant
        //Benign
        let descriptions = classifications.prefix(2).map { classification in
            return String(format: "  (%.2f) %@", classification.confidence, classification.identifier)
        }
        DispatchQueue.main.async {
            self.resultLabel.text = "Classification:\n" + descriptions.joined(separator: "\n")
        }
    }
    
}
