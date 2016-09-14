//
//  Utils.swift
//  Panda
//
//  Created by Xuefeng Peng on 29/07/2016.
//  Copyright © 2016 XFOffice. All rights reserved.
//

import UIKit

class Utils: NSObject {
    /// show alert view
    class func showMsg(title: String, msg: String, vc: UIViewController) {
        let alert = UIAlertController(title: title, message: msg, preferredStyle: UIAlertControllerStyle.Alert)
        alert.addAction(UIAlertAction(title: "Ok", style: UIAlertActionStyle.Default, handler: nil))
        vc.presentViewController(alert, animated: true, completion: nil)    
    }
    
    class func dismissKeyboard(textfield: UITextField) {
        textfield.resignFirstResponder()
    }
    
    class func shuffleArray(array: NSMutableArray) {
        if array.count < 2 {
            // ignore
        }
        for idx in 0...(array.count - 1) {
            let randInt = Int(arc4random_uniform(UInt32(array.count - idx))) + idx
           swap(&array[idx], &array[randInt])
        }
    }

}
