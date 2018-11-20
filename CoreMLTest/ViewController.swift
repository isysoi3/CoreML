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
    private var classificationView: ClassificationCameraView!
    private var segmentedControl: UISegmentedControl!
    
    private let classificationItems: [String : String] = ["часы" : "clock",
                                                          "кот" : "cat",
                                                          "мышь" : "mouse",
                                                          "кошелек" : "wallet"]
    
    private var selectedItem = (name: "часы", classification: "clock") {
        didSet {
            classificationView.handleClassifications = handleClassificationsClock
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        initAndConfigureSubviews()
    }
    
    private func initAndConfigureSubviews() {
        resultLabel = UILabel()
        segmentedControl = UISegmentedControl(items: classificationItems.map({ $0.key }))
        classificationView = ClassificationCameraView()
        
        classificationView.handleClassifications = handleClassificationsClock
        
        segmentedControl.selectedSegmentIndex = classificationItems.map({ $0.key }).firstIndex(of: selectedItem.name)!
        segmentedControl.addTarget(self, action: #selector(segmentedControlValueChanged), for: .valueChanged)
        segmentedControl.backgroundColor = #colorLiteral(red: 0, green: 0, blue: 0, alpha: 1)
        segmentedControl.tintColor = #colorLiteral(red: 1, green: 1, blue: 1, alpha: 1)
         
        resultLabel.numberOfLines = 0
        resultLabel.font = UIFont.boldSystemFont(ofSize: 40)
        resultLabel.backgroundColor = #colorLiteral(red: 0, green: 0, blue: 0, alpha: 1)
        resultLabel.textColor = #colorLiteral(red: 1, green: 1, blue: 1, alpha: 1)
        resultLabel.textAlignment = .center
        
       
        [segmentedControl, classificationView, resultLabel].forEach {
            view.addSubview($0)
        }
        
        segmentedControl.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide.snp.topMargin)
            make.left.right.equalToSuperview().inset(30)
        }
        
        resultLabel.snp.makeConstraints { make in
            make.left.right.equalToSuperview()
            make.bottom.equalTo(view.safeAreaLayoutGuide.snp.bottomMargin)
            make.height.equalTo(60)
        }
        
        classificationView.snp.makeConstraints { make in
            make.top.equalTo(segmentedControl.snp.bottom).offset(10)
            make.left.right.equalToSuperview()
            make.bottom.equalTo(resultLabel.snp.top).inset(10)
        }

    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        classificationView.previewLayer.frame = classificationView.bounds
    }
    
    @objc func segmentedControlValueChanged(sender: UISegmentedControl) {
        let selectedKey = classificationItems.map({ $0.key })[sender.selectedSegmentIndex]
        guard let selectedValue = classificationItems[selectedKey] else {
                return
        }
        selectedItem = (selectedKey, selectedValue)
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
            format: "Это%@%@",
            results[0...3]
                .map {
                    $0.identifier.lowercased()
                }
                .filter {
                    print($0)
                    return $0.range(of: selectedItem.classification) != nil
                }.count == 0 ? " не " : " ", selectedItem.name)
        
        DispatchQueue.main.async {
            self.resultLabel.text = resultString
        }
    }
    
}
