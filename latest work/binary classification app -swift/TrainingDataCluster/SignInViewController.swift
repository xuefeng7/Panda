//
//  SignInViewController.swift
//  Panda
//
//  Created by Xuefeng Peng on 29/07/2016.
//  Copyright © 2016 XFOffice. All rights reserved.
//

import UIKit
import NVActivityIndicatorView

class SignInViewController: UIViewController, UITextFieldDelegate {

    @IBOutlet weak var emailField: UITextField!
    @IBOutlet weak var passwordField: UITextField!
    
    var loadingIndicator: NVActivityIndicatorView!
    
    @IBAction func SignIn(sender: AnyObject) {
        SignInHandler()
    }
    
    override func viewWillAppear(animated: Bool) {
        self.navigationController?.setNavigationBarHidden(false, animated: false)
    }
    
    override func viewDidLoad() {
        
        super.viewDidLoad()
        
        // first responder
        emailField.becomeFirstResponder()
        
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
        }else {
           SignInHandler() // Go
        }
        
        return true
    }
    
    // Sign in handler
    func SignInHandler() {
        
        loadingIndicator.startAnimation()
        
        let username = emailField.text
        let password = passwordField.text
        AVUser.logInWithUsernameInBackground(username, password: password) { (user: AVUser!, error: NSError!) in
            self.loadingIndicator.stopAnimation()
            if user != nil {
                let mainNav = self.storyboard?.instantiateViewControllerWithIdentifier("mainNav") as! UINavigationController
               self.presentViewController(mainNav, animated: true, completion: nil)
            }else{
                Utils.showMsg("Alert", msg: "Sign in falied with error: \(error.localizedDescription)", vc: self)
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
