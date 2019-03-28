//
//  AppDelegate.swift
//  CoreMLTest
//
//  Created by Ilya Sysoi on 11/19/18.
//  Copyright © 2018 BeSmart-Mobile. All rights reserved.
//

import UIKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?


    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        
        window = UIWindow(frame: UIScreen.main.bounds)
        let rootVC = ViewController()
        window?.rootViewController = rootVC
        window!.makeKeyAndVisible()
        
        return true
    }

}

extension AppDelegate {
    
    func getCurrentViewController() -> UIViewController? {
        var currentController: UIViewController? = .none
        if let rootController = UIApplication.shared.keyWindow?.rootViewController {
            currentController = rootController
            while( currentController?.presentedViewController != nil ) {
                currentController = currentController?.presentedViewController
            }
        }
        return currentController
    }
    
}
