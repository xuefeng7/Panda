//
//  ForgotPasswordViewController.swift
//  Panda
//
//  Created by Xuefeng Peng on 29/07/2016.
//  Copyright © 2016 XFOffice. All rights reserved.
//

import UIKit
import NVActivityIndicatorView

class ForgotPasswordViewController: UIViewController, UITextFieldDelegate {
    
    @IBOutlet weak var emailField: UITextField!
    var loadingIndicator: NVActivityIndicatorView!
   
    @IBOutlet weak var resetButotn: UIButton!
    
    override func viewWillAppear(animated: Bool) {
        self.navigationController?.setNavigationBarHidden(false, animated: false)
    }
    
    override func viewDidLoad() {
        
        super.viewDidLoad()
        
        // first responder
        emailField.becomeFirstResponder()
        resetButotn.addTarget(self, action: #selector(ForgotPasswordViewController.resetHandler), forControlEvents: .TouchUpInside)
        
        loadingIndicator = NVActivityIndicatorView(frame: CGRectMake(self.view.center.x - 20, self.view.center.y - 20, 40, 40), type: .BallClipRotateMultiple, color: UIColor(red: 143/255.0, green: 179/255.0, blue: 247/255.0, alpha: 1), padding: 0)
        self.view.addSubview(loadingIndicator)
        self.view.bringSubviewToFront(loadingIndicator)
        
        emailField.delegate = self
        
        let tap = UITapGestureRecognizer(target: self, action: #selector(SignInViewController.dismissKeyboard))
        self.view.addGestureRecognizer(tap)
    }
    
    func textFieldShouldReturn(textField: UITextField) -> Bool {
        resetHandler()
        return true
    }
    
    func resetHandler() {
        
        loadingIndicator.startAnimation()
        
        AVUser.requestPasswordResetForEmailInBackground(emailField.text) { (succeed: Bool, error: NSError!) in
            self.loadingIndicator.stopAnimation()
            if succeed {
                Utils.showMsg("Succeed", msg: "Your request has been well received, please check your email and reset your password through the given link.", vc: self)
                self.emailField.text = ""
            }else{
                Utils.showMsg("Alert", msg: "request password reset failed with error: \(error.localizedDescription)", vc: self)
            }
        }
    }
    
    func dismissKeyboard() {
        self.view.endEditing(true)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
}
