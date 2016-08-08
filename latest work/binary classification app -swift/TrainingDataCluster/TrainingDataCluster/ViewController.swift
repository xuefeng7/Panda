//
//  ViewController.swift
//  TrainingDataCluster
//
//  Created by Xuefeng Peng on 16/4/2.
//  Copyright © 2016 XFOffice. All rights reserved.
//

import UIKit
import NVActivityIndicatorView
import JTSImageViewController
import StepSlider
import JTMaterialSwitch
import SVWebViewController

class ViewController: UIViewController {
    
    var data = Array<AVObject>()
    var ratings = NSMutableArray()
    
    //assessed observation count
    var assessedObservation: Int = 0
    //image UI
    var mainImageView: UIImageView = UIImageView()
    var mainLabel: UILabel = UILabel()
    
    //assessment elements
    var slider: StepSlider!
    var numLabel: UILabel!
    var pohSwitcher: JTMaterialSwitch!
    var ppSwitcher: JTMaterialSwitch!
    //move to the next observation button
    var nextBtn: UIButton!
    //image viwer
    var imageViewer: JTSImageViewController!
    var loadingIndicator: NVActivityIndicatorView!
    var refreshBtn: UIButton!
    
    override func viewDidLoad() {
        
        super.viewDidLoad()
        
        assessedObservation = NSUserDefaults.standardUserDefaults().objectForKey("assessed") as! Int
        
        // UI setup
        UIComponents()
        
        // Load source
        loadData()
        
        // bar buttons
        let openInfoButton = UIButton(type: .InfoLight)
        openInfoButton.addTarget(self, action: #selector(ViewController.openInfo), forControlEvents: .TouchUpInside)
        let infoBarButton = UIBarButtonItem(customView: openInfoButton)
        
        let signOutBarButton = UIBarButtonItem(title: "Log out", style: .Done, target: self, action: #selector(ViewController.SignOut))
        
        self.navigationItem.setLeftBarButtonItem(infoBarButton, animated: true)
        self.navigationItem.setRightBarButtonItem(signOutBarButton, animated: true)
    }
    
    /// download source data from cloud
    func loadData() {
        
        loadingIndicator.startAnimation()
        let query = AVQuery(className:"Face")
        query.whereKey("name", containsString: "_fa") //only show majors
        query.orderByAscending("name")
        query.limit = 100
        //read the assessed observation count
        //and set it as skip in query
        query.skip = AVUser.currentUser().objectForKey("assessed") as! Int
      
        query.findObjectsInBackgroundWithBlock {
            (objects: [AnyObject]?, error: NSError?) -> Void in
            if error == nil {
                if let objects = objects {
                    //the assessment is done
                    if objects.count == 0 {
                        Utils.showMsg("Thank you", msg: "You have finished the survey, thanks sincerely for your paticipation", vc: self)
                    }else{
                        
                        for object in objects {
                            self.data.append(object as! AVObject)
                        }
                        self.displayImage()
                    }
                }
            } else {
                // Log details of the failure
                print("Error: \(error!) \(error!.userInfo)")
                Utils.showMsg("Alert", msg: "load data failed with error: \(error)", vc: self)
            }
        }
    }
    
    func displayImage() {
        if data.count == 0 {
            //load more
            loadData()
        }else{
            if let picFile = data[0]["picture"] {
                self.loadingIndicator.startAnimation()
            (picFile as! AVFile).getDataInBackgroundWithBlock {
                (imageData: NSData?, error: NSError?) -> Void in
                self.loadingIndicator.stopAnimation()
                if error == nil {
                    if let imageData = imageData {
                        self.refreshBtn.alpha = 0
                        UIView.animateWithDuration(0.2, animations: { 
                            self.mainImageView.image = UIImage(data: imageData)
                        })
                        if let name = self.data[0]["name"] {
                            self.mainLabel.text = name as! String
                        }else{
                            self.mainLabel.text = "unknown"
                        }
                        //enable the move to next button
                        self.nextBtn.userInteractionEnabled = true
                    }
                }else{
                    Utils.showMsg("Alert", msg: "load image failed with error: \(error)", vc: self)
                    self.refreshBtn.alpha = 1
                }
            }
            }
        }
    }
    
    /// UI elements setup
    func UIComponents() {
        mainImageView.frame = CGRectMake(0, 60, self.view.frame.width, (1/2)*self.view.frame.height)
        mainImageView.contentMode = .ScaleToFill
        self.view.addSubview(mainImageView)
        //add tap gesture
        let imageTap = UITapGestureRecognizer(target: self, action:#selector(ViewController.tapToViewImage))
        mainImageView.userInteractionEnabled = true
        mainImageView.addGestureRecognizer(imageTap)
        //image loading indicator
        loadingIndicator = NVActivityIndicatorView(frame: CGRectMake(mainImageView.center.x - 20, mainImageView.center.y - 20, 40, 40), type: .BallClipRotateMultiple, color: UIColor(red: 143/255.0, green: 179/255.0, blue: 247/255.0, alpha: 1), padding: 0)
        self.view.addSubview(loadingIndicator)
        self.view.bringSubviewToFront(loadingIndicator)
        //refresh button
        refreshBtn = UIButton()
        refreshBtn.center = mainImageView.center
        refreshBtn.frame.size = CGSizeMake(30, 30)
        refreshBtn.setImage(UIImage(named: "refresh"), forState: .Normal)
        refreshBtn.alpha = 0
        refreshBtn.addTarget(self, action: #selector(ViewController.displayImage), forControlEvents: .TouchUpInside)
        self.view.addSubview(refreshBtn)
        self.view.bringSubviewToFront(refreshBtn)
        
        mainLabel.frame = CGRectMake(0, 60 + mainImageView.frame.height + 10, self.view.frame.width, 21)
        mainLabel.textAlignment = .Center
        mainLabel.font = UIFont.systemFontOfSize(14)
        self.view.addSubview(mainLabel)
        
        //label of sleepiness level
        let levelLabel =  UILabel(frame: CGRectMake(20, 40 + mainLabel.frame.origin.y + mainLabel.frame.height + 10, 80,20))
        levelLabel.textColor = UIColor.darkGrayColor()
        levelLabel.font = UIFont.systemFontOfSize(13)
        levelLabel.text = "sleepiness"
        //step slider
        slider = StepSlider(frame: CGRectMake(100, 40 + mainLabel.frame.origin.y + mainLabel.frame.height + 10, self.view.frame.width - 110 - 50, 20))
        slider.maxCount = 4
        slider.sliderCircleColor = UIColor(red: 52/255.0, green: 109/255.0, blue: 241/255.0, alpha: 1)
        slider.setIndex(0, animated: true)
        slider.tintColor = UIColor(red: 143/255.0, green: 179/255.0, blue: 247/255.0, alpha: 1)
        slider.addTarget(self, action: #selector(ViewController.sliderValueChanged(_:)), forControlEvents: .ValueChanged)
        //level # label
        numLabel =  UILabel(frame: CGRectMake(slider.frame.origin.x + slider.frame.width + 10, 40 + mainLabel.frame.origin.y + mainLabel.frame.height + 10, 50, 20))
        numLabel.textColor = UIColor(red: 70/255.0, green: 130/255.0, blue: 180/255.0, alpha: 0.8)
        numLabel.font = UIFont.systemFontOfSize(14)
        numLabel.text = "level 0"
        numLabel.textAlignment = .Center
        self.view.addSubview(levelLabel)
        self.view.addSubview(slider)
        self.view.addSubview(numLabel)
        //swither for POH or PP
        //label of poh
        let pohLabel =  UILabel(frame: CGRectMake(20, 40 + mainLabel.frame.origin.y + mainLabel.frame.height + 10 + levelLabel.frame.height + 20, 80 ,20))
        pohLabel.textColor = UIColor.darkGrayColor()
        pohLabel.font = UIFont.systemFontOfSize(14)
        pohLabel.text = "dark circle"
        //poh switcher
        pohSwitcher = JTMaterialSwitch()
        pohSwitcher.center = CGPoint(x: 120, y: pohLabel.center.y)
        pohSwitcher.isOn = false
        self.view.addSubview(pohLabel)
        self.view.addSubview(pohSwitcher)
        //label of pp
        let ppLabel =  UILabel(frame: CGRectMake(20, 40 + mainLabel.frame.origin.y + mainLabel.frame.height + 10 + levelLabel.frame.height + 20 + pohLabel.frame.height + 20, 80 ,20))
        ppLabel.textColor = UIColor.darkGrayColor()
        ppLabel.font = UIFont.systemFontOfSize(14)
        ppLabel.text = "eye bag"
        //pp switcher
        ppSwitcher = JTMaterialSwitch()
        ppSwitcher.center = CGPoint(x: 120, y: ppLabel.center.y)
        ppSwitcher.isOn = false
        self.view.addSubview(ppLabel)
        self.view.addSubview(ppSwitcher)
        
        //move to the next button
        nextBtn = UIButton(frame: CGRectMake(0, self.view.frame.height - 50, self.view.frame.width, 50))
        nextBtn.backgroundColor = UIColor(red: 70/255.0, green: 130/255.0, blue: 180/255.0, alpha: 1.0)
        nextBtn.setTitle("Next", forState: .Normal)
        nextBtn.titleLabel?.textColor = UIColor.whiteColor()
        nextBtn.addTarget(self, action: #selector(ViewController.saveThenMoveToNext), forControlEvents: .TouchUpInside)
        self.view.addSubview(nextBtn)

    }
    
    /// tap to view the enlarged image
    func tapToViewImage() {
        
        let image = mainImageView.image
        let imageInfo = JTSImageInfo()
        imageInfo.image = image
        imageInfo.referenceRect = self.view.frame;
        imageInfo.referenceView = self.view.superview;
        imageViewer = JTSImageViewController(imageInfo: imageInfo, mode: .Image, backgroundStyle: .Blurred)
        imageViewer.showFromViewController(self, transition: .FromOffscreen)
    }
    
    func sliderValueChanged(slider: StepSlider) {
        self.numLabel.text = "level \(slider.index)"
    }

    ///next button action listener
    func saveThenMoveToNext() {
        //change button title
        nextBtn.setTitle("Saving...", forState: .Normal)
        //disable the button temporarily
        //to prevent duplicate tap
        nextBtn.userInteractionEnabled = false
        if data.count > 0 {
            let currentObj = data.first!
            // periorbital hyperpigmentation
            let username = AVUser.currentUser().username
            currentObj.addObject("\(pohSwitcher.isOn)(\(username))", forKey: "PH")
            // periorbital puffiness
            currentObj.addObject("\(ppSwitcher.isOn)(\(username))", forKey: "PP")
            // fatigue level
            currentObj.addObject("\(slider.index)(\(username))", forKey: "FL")
            currentObj.saveInBackgroundWithBlock {
                (success: Bool, error: NSError?) -> Void in
                if (success) {
                    
                    // The object has been saved.
                    // increment the assessed number for user
                    // local
                    self.assessedObservation += 1
                    NSUserDefaults.standardUserDefaults().setInteger(self.assessedObservation, forKey: "assessed")
                    // remote
                    AVUser.currentUser().incrementKey("assessed")
                    AVUser.currentUser().saveEventually()
                    
                    //move to the next
                    self.data.removeFirst()
                    self.displayImage()
                    //change back button title
                    self.nextBtn.setTitle("Next", forState: .Normal)
                    //change switcher and slider to default value
                    self.slider.setIndex(0, animated: false)
                    self.pohSwitcher.setOn(false, animated: false)
                    self.ppSwitcher.setOn(false, animated: false)
                } else {
                    // There was a problem, check error.description
                    Utils.showMsg("Save Failed", msg: "\(error?.description)", vc: self)
                }
            }
        }else {
            Utils.showMsg("Warning", msg: "Data set is empty", vc: self)
        }
    }
    
    func openInfo() {
        let webViewer = SVModalWebViewController(address: "https://s3.amazonaws.com/avos-cloud-xvnufxdmg3zx/K7ORiRbC3IScCDUotgBy7WnvIYkxI7WzkiaApCcf.html")
        self.presentViewController(webViewer, animated: true, completion: nil)
    }
    
    func SignOut() {
        AVUser.logOut()
        AVFile.clearAllCachedFiles()
        let registerNav = self.storyboard?.instantiateViewControllerWithIdentifier("registerNav") as! UINavigationController
        self.presentViewController(registerNav, animated: true, completion: nil)
    }
    
    /// steper delegate
    func sliderValueChanged() {
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

}

