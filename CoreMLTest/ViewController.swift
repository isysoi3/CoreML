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

class ViewController: UIViewController {

    private var resultLabel: UILabel!
    private var resultView: ClassificationCameraView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        initAndConfigureSubviews()
    }
    
    private func initAndConfigureSubviews() {
        resultLabel = UILabel()
        resultView = ClassificationCameraView(handleClassifications: handleClassificationsClock)
        
        resultLabel.numberOfLines = 0
        resultLabel.font = UIFont.boldSystemFont(ofSize: 40)
        resultLabel.backgroundColor = #colorLiteral(red: 0, green: 0, blue: 0, alpha: 1)
        resultLabel.textColor = #colorLiteral(red: 1, green: 1, blue: 1, alpha: 1)
        resultLabel.textAlignment = .center
        
        [resultView, resultLabel].forEach {
            view.addSubview($0)
        }
        
        resultLabel.snp.makeConstraints { make in
            make.left.right.equalToSuperview()
            make.bottom.equalTo(view.safeAreaLayoutGuide.snp.bottomMargin)
            make.height.equalTo(60)
        }
        
        resultView.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide.snp.topMargin)
            make.left.right.equalToSuperview()
            make.bottom.equalTo(resultView.snp.top)
        }

    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        resultView.previewLayer.frame = view.frame
    }
    
    private func handleClassificationsClock(request: VNRequest, error: Error?) {
        if let error = error {
            print(error.localizedDescription)
            return
        }
        guard let results = request.results as? [VNClassificationObservation] else {
            print("No results")
            return
        }
        
        let resultString = String(
            format: "Это%@часы",
            results[0...3]
                .map {
                    $0.identifier.lowercased()
                }
                .filter {
                    print($0)
                    return $0.range(of: "clock") != nil
                }.count == 0 ? " не " : " ")
        
        DispatchQueue.main.async {
            self.resultLabel.text = resultString
        }
    }
    
}
