//
//  ViewController.swift
//  TrainingDataCluster
//
//  Created by Xuefeng Peng on 16/4/2.
//  Copyright © 2016 XFOffice. All rights reserved.
//

import UIKit
import ZLSwipeableView
import SVProgressHUD
import Parse

class ViewController: UIViewController {
    
    var swipeView: ZLSwipeableView!
    var data = Array<PFObject>()
    
    var mainImageView: UIImageView = UIImageView()
    var mainLabel: UILabel = UILabel()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        mainImageView.frame = CGRectMake(0, 100, self.view.frame.width, (2/3)*self.view.frame.height)
        mainImageView.contentMode = .ScaleToFill
        self.view.addSubview(mainImageView)
        
        mainLabel.frame = CGRectMake(0, 100 + mainImageView.frame.height + 10, self.view.frame.width, 21)
        mainLabel.textAlignment = .Center
        self.view.addSubview(mainLabel)
        
        loadData()
        
        //add negative button
        let neg = UIButton(frame: CGRectMake(0, self.view.frame.height - 50, self.view.frame.width/2, 50))
        neg.setImage(UIImage(named: "negativeIcon"), forState: .Normal)
        neg.addTarget(self, action: #selector(ViewController.clickToNeg), forControlEvents: .TouchUpInside)
        //add positive button
        let pos = UIButton(frame: CGRectMake(self.view.frame.width/2, self.view.frame.height - 50, self.view.frame.width/2, 50))
        pos.setImage(UIImage(named: "positiveIcon"), forState: .Normal)
        pos.addTarget(self, action: #selector(ViewController.clickToPos), forControlEvents: .TouchUpInside)
        //self.view.addSubview(swipeView)
        self.view.addSubview(neg)
        self.view.addSubview(pos)
    }
    
    /// download source data from cloud
    func loadData() {
        SVProgressHUD.show()
        let query = PFQuery(className:"Faces")
        query.whereKey("class", notContainedIn: ["pos", "neg"])
        query.orderByAscending("name")
        query.limit = 50
        query.findObjectsInBackgroundWithBlock {
            (objects: [PFObject]?, error: NSError?) -> Void in
            SVProgressHUD.dismiss()
            if error == nil {
                if let objects = objects {
                    for object in objects {
                        //print(object)
                        self.data.append(object)
                    }
                    self.displayImage()
                }
            } else {
                // Log details of the failure
                print("Error: \(error!) \(error!.userInfo)")
                self.showMsg("load data failed with error: \(error)")
            }
        }
    }
    
    func displayImage() {
        if data.count == 0 {
            //load more
            loadData()
        }else{
            if let picFile = data[0]["picture"] {
            (picFile as! PFFile).getDataInBackgroundWithBlock {
                (imageData: NSData?, error: NSError?) -> Void in
                if error == nil {
                    if let imageData = imageData {
                        self.mainImageView.image = UIImage(data: imageData)
                        if let name = self.data[0]["name"] {
                            self.mainLabel.text = name as! String
                        }else{
                            self.mainLabel.text = "unknown"
                        }
                    }
                }else{
                    self.showMsg("load image failed with error: \(error)")
                }
            }
            }
        }
    }

    func clickToPos() {
        if data.count > 0 {
            let currentObj = data.first!
            currentObj.setObject("pos", forKey: "class")
            currentObj.saveInBackground()
            data.removeFirst()
            displayImage()
        }
    }
    
    func clickToNeg() {
        if data.count > 0 {
            let currentObj = data.first!
            currentObj.setObject("neg", forKey: "class")
            currentObj.saveInBackground()
            data.removeFirst()
            displayImage()
        }
    }
    
    ///show alert
    func showMsg(msg: String) {
        let alert = UIAlertController(title: "Alert", message: msg, preferredStyle: UIAlertControllerStyle.Alert)
        alert.addAction(UIAlertAction(title: "Ok", style: UIAlertActionStyle.Default, handler: nil))
        self.presentViewController(alert, animated: true, completion: nil)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


}

