//
//  MainRatingViewController.swift
//  Panda
//
//  Created by Xuefeng Peng on 04/08/2016.
//  Copyright © 2016 XFOffice. All rights reserved.
//

import UIKit
import NVActivityIndicatorView
import JTSImageViewController
import SVWebViewController
import StepSlider

class MainRatingViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {

    @IBOutlet weak var mainImageView: UIImageView!
    @IBOutlet weak var evaluateTable: UITableView!
    @IBOutlet weak var photoNameLabel: UILabel!
    
    var data = Array<AVObject>()
    var ratings: NSMutableArray!
    //assessed observation count
    var assessedObservation: Int = 0
    
    //move to the next observation button
    var nextBtn: UIButton!
    
    //image viwer
    var imageViewer: JTSImageViewController!
    var loadingIndicator: NVActivityIndicatorView!
    var refreshBtn: UIButton!
    
    // datasource
    var evaluateCategories: [String] = []
    
    override func viewDidLoad() {
        
        super.viewDidLoad()
        
        evaluateCategories = ["dark circle", "red eye", "glazed eye", "hanging eyelid", "swollen eye", "pale skin", "dropping mouth"]
        
        mainImageView.contentMode = .ScaleAspectFit
        
        evaluateTable.delegate = self
        evaluateTable.dataSource = self
        
        assessedObservation = NSUserDefaults.standardUserDefaults().objectForKey("assessed") as! Int
        
        UIConfig()
        
        loadData()
        
        //initialize rating array
        ratings = NSMutableArray(array: [0,0,0,0,0,0,0])
        
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
                        Utils.showMsg("Thank you", msg: "You have finished the rating, thanks sincerely for your paticipation", vc: self)
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
                            if let name = self.data[0]["name"] as? String {
                                self.photoNameLabel.text = name
                            }else{
                                self.photoNameLabel.text = "unknown"
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
    
    /// tableview datasource method
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return evaluateCategories.count
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 1
    }
    
    /// tableview delegate method
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        
        print(ratings)
        let cell = tableView.dequeueReusableCellWithIdentifier("RatingCell", forIndexPath: indexPath) as! RatingCell
        cell.steper.tag = indexPath.section
        
        let rating = ratings[indexPath.section] as! UInt
        cell.steper.index = rating
        cell.detailTextLabel?.text = "\(rating)"
        // steper action
        cell.steper.addTarget(self, action: #selector(MainRatingViewController.sliderValueChanged), forControlEvents: .ValueChanged)
       
             
        cell.selectionStyle = .None
            
        return cell
    }
    
    func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return evaluateCategories[section]
    }
    
    func UIConfig() {
        
        // mainimageview tap gesture
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
        
        //tableview
        evaluateTable.separatorColor = UIColor.clearColor()
        evaluateTable.tableFooterView?.frame = CGRectZero
        evaluateTable.contentInset = UIEdgeInsetsMake(0, 0, 50, 0)
        
        //move to the next button
        nextBtn = UIButton(frame: CGRectMake(0, self.view.frame.height - 50, self.view.frame.width, 50))
        nextBtn.backgroundColor = UIColor(red: 70/255.0, green: 130/255.0, blue: 180/255.0, alpha: 1.0)
        nextBtn.setTitle("Next", forState: .Normal)
        nextBtn.titleLabel?.textColor = UIColor.whiteColor()
        nextBtn.addTarget(self, action: #selector(ViewController.saveThenMoveToNext), forControlEvents: .TouchUpInside)
        self.view.addSubview(nextBtn)
        
        // bar buttons
        let openInfoButton = UIButton(type: .InfoLight)
        openInfoButton.addTarget(self, action: #selector(ViewController.openInfo), forControlEvents: .TouchUpInside)
        let infoBarButton = UIBarButtonItem(customView: openInfoButton)
        
        let signOutBarButton = UIBarButtonItem(title: "Log out", style: .Done, target: self, action: #selector(ViewController.SignOut))
        
        self.navigationItem.setLeftBarButtonItem(infoBarButton, animated: true)
        self.navigationItem.setRightBarButtonItem(signOutBarButton, animated: true)
        
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
    
    /// next button action listener
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
            
            /// core ratings
            currentObj.addObject("\(ratings[0])(\(username))", forKey: evaluateCategories[0])
            // periorbital puffiness
            currentObj.addObject("\(ratings[1])(\(username))", forKey: evaluateCategories[1])
            // fatigue level
            currentObj.addObject("\(ratings[2])(\(username))", forKey: evaluateCategories[2])
            // fatigue level
            currentObj.addObject("\(ratings[3])(\(username))", forKey: evaluateCategories[3])
            // fatigue level
            currentObj.addObject("\(ratings[4])(\(username))", forKey: evaluateCategories[4])
            // fatigue level
            currentObj.addObject("\(ratings[5])(\(username))", forKey: evaluateCategories[5])
            // fatigue level
            currentObj.addObject("\(ratings[6])(\(username))", forKey: evaluateCategories[6])
            
            currentObj.saveInBackgroundWithBlock {
                (success: Bool, error: NSError?) -> Void in
                
                //change back button title
                self.nextBtn.setTitle("Next", forState: .Normal)
                
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
                   
                } else {
                    // There was a problem, check error.description
                    Utils.showMsg("Save Failed", msg: "\(error?.description)", vc: self)
                }
            }
        }else {
            Utils.showMsg("Warning", msg: "Data set is empty", vc: self)
        }
    }
    
    /// after moving to next observation, set the step to default value
    func setCellSteperToDefault() {
        for section in 0...(evaluateCategories.count - 1) {
            let cell = evaluateTable.cellForRowAtIndexPath(NSIndexPath(forRow: 0, inSection: section)) as! RatingCell
            (cell.viewWithTag(section) as! StepSlider).index = 0
        }
        // reload table
        evaluateTable.reloadData()
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
    func sliderValueChanged(sender: StepSlider) {
        ratings[sender.tag] = sender.index
        let cell = evaluateTable.cellForRowAtIndexPath(NSIndexPath(forRow: 0, inSection: sender.tag)) as? RatingCell
        if let cell = cell {
             cell.detailTextLabel?.text = "\(sender.index)"
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
}
