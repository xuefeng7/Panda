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

class ViewController: UIViewController, ZLSwipeableViewDataSource, ZLSwipeableViewDelegate {
    
    var swipeView: ZLSwipeableView!
    var data = Array<PFObject>()
    var dataIndex = 0
    var swipeCount = 0
    
    /// undo previous action
    @IBAction func undo(sender: AnyObject) {
            swipeCount -= 1
            dataIndex = swipeCount
            swipeView.discardAllViews()
            swipeView.loadViewsIfNeeded()
            undoClassify()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        loadData()
        
        swipeView = ZLSwipeableView(frame: self.view.frame)
        self.swipeView.dataSource = self
        self.swipeView.delegate = self;
        
        //add negative button
        let neg = UIButton(frame: CGRectMake(0, self.view.frame.height - 50, self.view.frame.width/2, 50))
        neg.setImage(UIImage(named: "negativeIcon"), forState: .Normal)
        neg.addTarget(self, action: #selector(ViewController.classifyToNeg), forControlEvents: .TouchUpInside)
        //add positive button
        let pos = UIButton(frame: CGRectMake(self.view.frame.width/2, self.view.frame.height - 50, self.view.frame.width/2, 50))
        pos.setImage(UIImage(named: "positiveIcon"), forState: .Normal)
        pos.addTarget(self, action: #selector(ViewController.classifyToPos), forControlEvents: .TouchUpInside)
        self.view.addSubview(swipeView)
        self.view.addSubview(neg)
        self.view.addSubview(pos)
    }
    
    /// download source data from cloud
    func loadData() {
        SVProgressHUD.show()
        let query = PFQuery(className:"Faces")
        query.whereKey("set", notContainedIn: ["positive", "negative"])
        query.limit = 50
        query.findObjectsInBackgroundWithBlock {
            (objects: [PFObject]?, error: NSError?) -> Void in
            SVProgressHUD.dismiss()
            if error == nil {
                if let objects = objects {
                    for object in objects {
                        self.data.append(object)
                    }
                    //print(self.data)
                    self.swipeView.loadViewsIfNeeded()
                }
            } else {
                // Log details of the failure
                print("Error: \(error!) \(error!.userInfo)")
                self.showMsg("load data failed with error: \(error)")
            }
        }
    }
    
    ///pragma mark - ZLSwipeableViewDataSource
    func nextViewForSwipeableView(swipeableView: ZLSwipeableView!) -> UIView! {
        //print(dataIndex)
        if dataIndex >= data.count {
            //reload the data
            dataIndex = 0
            swipeView.discardAllViews()
            loadData()
        }else if dataIndex < 0 {
            dataIndex = 0
        }
        let content = UIImageView()
        if let picFile = data[dataIndex]["picture"] {
            (picFile as! PFFile).getDataInBackgroundWithBlock ({
                (imageData: NSData?, error: NSError?) -> Void in
                if error == nil {
                    if let imageData = imageData {
                        content.image = UIImage(data: imageData)
                    }
                }else{
                    self.showMsg("load image failed with error: \(error)")
                }
            }, progressBlock: {
            (percentDone: Int32) -> Void in
                //SVProgressHUD.showProgress(Float(percentDone))
//                if percentDone == 100 {
//                    SVProgressHUD.dismiss()
//                }
            })
        }
        content.frame = CGRectMake(0, 0, self.view.frame.width, (2/3)*self.view.frame.height)
        content.contentMode = .ScaleToFill
        dataIndex += 1
        return content
    }
    
    ///pragma mark - ZLSwipeableViewDelegate
    func swipeableView(swipeableView: ZLSwipeableView!, didSwipeView view: UIView!, inDirection direction: ZLSwipeableViewDirection) {
        swipeCount += 1
        if direction == ZLSwipeableViewDirection.Left || direction == ZLSwipeableViewDirection.Down {
            //negative
            classifyToNeg()
        }else if direction == ZLSwipeableViewDirection.Right || direction == ZLSwipeableViewDirection.Up {
            //positive
            classifyToPos()
        }
    }
    
    ///classify to positive set
    func classifyToPos() {
        let currentObj = data[dataIndex]
        currentObj.setObject("positive", forKey: "set")
        currentObj.saveInBackground()
    }
    ///classify to negative set
    func classifyToNeg() {
        let currentObj = data[dataIndex]
        currentObj.setObject("negative", forKey: "set")
        currentObj.saveInBackground()
    }
    ///undo to the previous classification action
    func undoClassify() {
        let currentObj = data[dataIndex]
        currentObj.setObject("", forKey: "set")
        currentObj.saveInBackground()
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

