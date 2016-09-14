//
//  AppDelegate.swift
//  TrainingDataCluster
//
//  Created by Xuefeng Peng on 16/4/2.
//  Copyright © 2016 XFOffice. All rights reserved.
//

import UIKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?
    let storyboard = UIStoryboard(name: "Main", bundle: nil)
    
    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
        
        // Connect to server (US)
        AVOSCloud.setServiceRegion(.US)
        AVOSCloud.setApplicationId(Constant.AVServer.appId, clientKey: Constant.AVServer.appKey)
        
        // Analytics
        AVAnalytics.trackAppOpenedWithLaunchOptions(launchOptions)
        
        // Config local assessed observations count
        if NSUserDefaults.standardUserDefaults().objectForKey("assessed") == nil  {
            // haven't initialized yet, initiate
            NSUserDefaults.standardUserDefaults().setInteger(0, forKey: "assessed")
        }
        
        // Authentication
        let user = AVUser.currentUser()
        if user != nil {
            
            // refresh the user
            user.fetch()
        
            // have initialized.
            // compare with remote one
//            let localAssessed = NSUserDefaults.standardUserDefaults().objectForKey("assessed") as! Int
//            if localAssessed > user.objectForKey("assessed") as! Int {
//                // update the remote one
//                user.setObject(localAssessed, forKey: "assessed")
//                user.save()
//            }else if localAssessed < user.objectForKey("assessed") as! Int {
//                // this case happens if user delete the app
//                 let remoteAssessed = user.objectForKey("assessed") as! Int
//                 NSUserDefaults.standardUserDefaults().setInteger(remoteAssessed, forKey: "assessed")
//            }

            // Main view
            let mainNav = storyboard.instantiateViewControllerWithIdentifier("mainNav") as! UINavigationController
            self.window?.rootViewController = mainNav
            self.window?.makeKeyAndVisible()
            
        }else{
            // Sign in/ Sign up
            let registerNav = storyboard.instantiateViewControllerWithIdentifier("registerNav") as! UINavigationController
            self.window?.rootViewController = registerNav
            self.window?.makeKeyAndVisible()
        }
        
        // make all textfield has radius degree
        UITextField.appearance().layer.cornerRadius = 10.0
        
        return true
    }

    func applicationWillResignActive(application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }

    func applicationWillEnterForeground(application: UIApplication) {
        // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
    }

    func applicationDidBecomeActive(application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }

    func applicationWillTerminate(application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }

}

