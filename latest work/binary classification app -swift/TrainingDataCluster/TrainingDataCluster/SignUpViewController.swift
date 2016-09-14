//
//  SignUpViewController.swift
//  Panda
//
//  Created by Xuefeng Peng on 29/07/2016.
//  Copyright © 2016 XFOffice. All rights reserved.
//

import UIKit
import NVActivityIndicatorView

class SignUpViewController: UIViewController, UITextFieldDelegate {
    
    @IBOutlet weak var emailField: UITextField!
    @IBOutlet weak var passwordField: UITextField!
    
    var loadingIndicator: NVActivityIndicatorView!
    
    @IBOutlet weak var SignUpButton: UIButton!

    override func viewWillAppear(animated: Bool) {
        self.navigationController?.setNavigationBarHidden(false, animated: false)
    }
    
    override func viewDidLoad() {
        
        super.viewDidLoad()
        
        // first responder
        emailField.becomeFirstResponder()
        SignUpButton.addTarget(self, action: #selector(SignUpViewController.SignUpHanlder), forControlEvents: .TouchUpInside)
        
        loadingIndicator = NVActivityIndicatorView(frame: CGRectMake(self.view.center.x - 20, self.view.center.y - 20, 40, 40), type: .BallClipRotateMultiple, color: UIColor(red: 143/255.0, green: 179/255.0, blue: 247/255.0, alpha: 1), padding: 0)
        self.view.addSubview(loadingIndicator)
        self.view.bringSubviewToFront(loadingIndicator)
        
        emailField.delegate = self
        passwordField.delegate = self
        
        let tap = UITapGestureRecognizer(target: self, action: #selector(SignInViewController.dismissKeyboard))
        self.view.addGestureRecognizer(tap)
    }
    
    func textFieldShouldReturn(textField: UITextField) -> Bool {
        if textField.returnKeyType == UIReturnKeyType.Next {
            passwordField.becomeFirstResponder()
        }else{
            //Go
            SignUpHanlder()
        }
        return true
    }
    
    func SignUpHanlder() {
        
        loadingIndicator.startAnimation()
       
        let user = AVUser()
        user.email = emailField.text
        user.username = emailField.text
        user.password = passwordField.text
    
        user.signUpInBackgroundWithBlock { (succeed: Bool, error: NSError!) in
            self.loadingIndicator.stopAnimation()
            if succeed {
                let mainNav = self.storyboard?.instantiateViewControllerWithIdentifier("mainNav") as! UINavigationController
                self.presentViewController(mainNav, animated: true, completion: nil)
            }else{
                Utils.showMsg("Alert", msg: "Sign up failed with error: \(error.localizedDescription)", vc: self)
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
