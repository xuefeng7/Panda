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
import CHTCollectionViewWaterfallLayout

class MainRatingViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, UICollectionViewDelegate, UICollectionViewDataSource, CHTCollectionViewDelegateWaterfallLayout {
    
    @IBOutlet weak var mainImageView: UICollectionView!
      
    var images: NSMutableArray = NSMutableArray() //images
   
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
        
        evaluateCategories = ["dark circle", "red eye", "glazed eye", "hanging eyelid", "swollen eye", "wrinkles around eye", "droopy corner mouse", "pale skin"]
        
        mainImageView.backgroundColor = UIColor.clearColor()
        mainImageView.delegate = self
        mainImageView.dataSource = self
        
        self.mainImageView.autoresizingMask = [UIViewAutoresizing.FlexibleHeight, UIViewAutoresizing.FlexibleWidth]
        self.mainImageView.alwaysBounceVertical = true
        
        // Configure spacing between cells
        //let layout = UICollectionViewFlowLayout()
        let layout = CHTCollectionViewWaterfallLayout()
        layout.minimumInteritemSpacing = 2.0
        layout.minimumColumnSpacing = 2.0
        layout.sectionInset = UIEdgeInsetsMake(10.0, 5.0, 5.0, 5.0)
        
        // Add the waterfall layout to your collection view
        mainImageView.collectionViewLayout = layout
        
        
        evaluateTable.delegate = self
        evaluateTable.dataSource = self
        
        assessedObservation = NSUserDefaults.standardUserDefaults().objectForKey("assessed") as! Int
        
        UIConfig()
        
        loadData()
        
        //initialize rating array
        ratings = NSMutableArray(array: [0,0,0,0,0,0,0,0])
        
    }
    
    /// download source data from cloud
    func loadData() {
        
        loadingIndicator.startAnimation()
        let query = AVQuery(className:"Face")
        //query.whereKey("name", containsString: "_fa") //only show majors
        query.orderByAscending("fid")
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
            // load all images from url to array
            if let pathes = data[0]["pathes"] as? NSArray {
                if let fid = data[0]["fid"] as? String {
                    self.photoNameLabel.text = "subject id: \(fid)"
                }else{
                    self.photoNameLabel.text = "subject id: unknown"
                }
    
                for path in pathes {
                    if let url = path[1] {
                        if let data = NSData(contentsOfURL: NSURL(string: url as! String)!) {
                            self.images.addObject([UIImage(data: data)!, path[0]!])
                        }else{
                            self.images.addObject([UIImage(named: "placeholder")!,""])
                        }
                        
                    }else{
                         self.images.addObject([UIImage(named: "placeholder")!, ""])
                    }
                }
                // reload collection view
                self.mainImageView.reloadData()
                self.loadingIndicator.stopAnimation()
            }
        }
    }
    
    /// collection view data source
    func numberOfSectionsInCollectionView(collectionView: UICollectionView) -> Int {
        return 1
    }
    
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return images.count
    }
    
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier("Cell", forIndexPath: indexPath) as! ImageCollectionViewCell
        cell.backgroundColor = UIColor.clearColor()
        //cell.ImageBox.contentMode = .ScaleAspectFit
        cell.ImageBox.frame = CGRectMake(0, 0, cell.frame.width, cell.frame.height)
        
        let img = images[indexPath.row][0] as? UIImage
        //let name =  images[indexPath.item][1] as! String
        if let img = img {
            cell.ImageBox.image = img
        }else{
            cell.ImageBox.image = UIImage(named: "placeholder")
        }
        
        return cell
    }
    
    /// pragma mark - UICollectionViewDelegateFlowLayout
    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAtIndexPath indexPath: NSIndexPath) -> CGSize {
        
        let asset = images[indexPath.item][0] as? UIImage
        let name =  images[indexPath.item][1] as! String
        
        if let asset = asset {
            if name.rangeOfString("_fa") != nil {
                // primary
                switch(images.count) {
                case 5:
                    return CGSizeMake(asset.size.width * 0.5, asset.size.height * 0.5);
                case 4:
                    return CGSizeMake(asset.size.width * 0.5, asset.size.height * 0.5);
                case 3:
                    return CGSizeMake(asset.size.width * 0.5, asset.size.height * 0.25);
                case 2:
                    return CGSizeMake(asset.size.width * 0.5, asset.size.height * 0.5);
                default:
                    return CGSizeMake( UIImage(named: "placeholder")!.size.width * 0.1,  UIImage(named: "placeholder")!.size.height * 0.1);
                }
            }else{
                switch(images.count) {
                case 5:
                    return CGSizeMake(asset.size.width * 0.5, asset.size.height * 0.25);
                case 4:
                    return CGSizeMake(asset.size.width * 0.5, asset.size.height * 0.33);
                case 3:
                    return CGSizeMake(asset.size.width * 0.5, asset.size.height * 0.25);
                case 2:
                    return CGSizeMake(asset.size.width * 0.5, asset.size.height * 0.5);
                default:
                    return CGSizeMake( UIImage(named: "placeholder")!.size.width * 0.1,  UIImage(named: "placeholder")!.size.height * 0.1);
                }
            }
        }
        
        return CGSizeMake( UIImage(named: "placeholder")!.size.width * 0.1,  UIImage(named: "placeholder")!.size.height * 0.1);
    }
    
    func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
        let image = self.images[indexPath.item][0] as! UIImage
        let imageInfo = JTSImageInfo()
        imageInfo.image = image
        imageInfo.referenceRect = self.view.frame;
        imageInfo.referenceView = self.view.superview;
        imageViewer = JTSImageViewController(imageInfo: imageInfo, mode: .Image, backgroundStyle: .Blurred)
        imageViewer.showFromViewController(self, transition: .FromOffscreen)

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
        
        //image loading indicator
        loadingIndicator = NVActivityIndicatorView(frame: CGRectMake(self.view.center.x - 20, self.view.center.y - 20, 30, 30), type: .BallClipRotateMultiple, color: UIColor(red: 143/255.0, green: 179/255.0, blue: 247/255.0, alpha: 1), padding: 0)
        self.view.addSubview(loadingIndicator)
        self.view.bringSubviewToFront(loadingIndicator)
        print("loading frame: \(loadingIndicator.frame)")
        
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
            
            //evaluateCategories = ["dark circle", "red eye", "glazed eye", "hanging eyelid", "swollen eye", "wrinkles around eye", "droopy corner mouse", "pale skin"]

            currentObj.addObject("\(ratings[0])(\(username))", forKey: evaluateCategories[0])
            // dark circle
            currentObj.addObject("\(ratings[1])(\(username))", forKey: evaluateCategories[1])
            // red eye
            currentObj.addObject("\(ratings[2])(\(username))", forKey: evaluateCategories[2])
            // glazed eye
            currentObj.addObject("\(ratings[3])(\(username))", forKey: evaluateCategories[3])
            // hanging eyelid
            currentObj.addObject("\(ratings[4])(\(username))", forKey: evaluateCategories[4])
            // sowllen eye
            currentObj.addObject("\(ratings[5])(\(username))", forKey: evaluateCategories[5])
            // wrinkles around eyes
            currentObj.addObject("\(ratings[6])(\(username))", forKey: evaluateCategories[6])
            // droopy mouth
            currentObj.addObject("\(ratings[7])(\(username))", forKey: evaluateCategories[6])
            // pale skin
            
            //currentObj.addObject("\(ratings[6])(\(username))", forKey: evaluateCategories[6])
            
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
                    //self.displayImage()
                   
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
