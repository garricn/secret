//
//  AppDelegate.swift
//  FLYR
//
//  Created by Garric Nahapetian on 8/1/16.
//  Copyright © 2016 Garric Nahapetian. All rights reserved.
//

import UIKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject : AnyObject]?) -> Bool {
        let frame = screenBounds
        window = UIWindow(frame: frame)
        window?.backgroundColor = .whiteColor()
        window?.rootViewController = AppCoordinator.sharedInstance.rootViewController(from: launchOptions)
        window?.makeKeyAndVisible()
        return true
    }
}
