//
//  DetailViewController.swift
//  InstaPrynt
//
//  Created by Brian Endo on 6/23/16.
//  Copyright © 2016 Brian Endo. All rights reserved.
//

import UIKit
import Alamofire
import SwiftyJSON
import Haneke
import FMMosaicLayout

class DetailViewController: UIViewController, UICollectionViewDelegate, UICollectionViewDataSource {
    
    // MARK: - Variables
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var profileImageView: UIImageView!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var likesLabel: UILabel!
    @IBOutlet weak var dateLabel: UILabel!
    @IBOutlet weak var portfolioButton: UIButton!
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var moreFromLabel: UILabel!
    
    var picture: Picture?
    var pictureArray = [Picture]()
    
    
    // MARK: - viewDidLoad
    override func viewDidLoad() {
        super.viewDidLoad()
        
        collectionView.delegate = self
        collectionView.dataSource = self
        
        // Circle border for profileImage
        profileImageView.layer.borderWidth = 1.0
        profileImageView.layer.masksToBounds = false
        profileImageView.layer.borderColor = UIColor.whiteColor().CGColor
        profileImageView.layer.cornerRadius = self.profileImageView.frame.size.height/2
        profileImageView.clipsToBounds = true
        
        
        if let username = picture?.username {
            self.loadPersonalData(username)
        }
        if let imageUrl = picture?.regularImageURL {
            if let nsImageUrl = NSURL(string: imageUrl) {
                imageView.hnk_setImageFromURL(nsImageUrl)
            }
        }
        if let profileImageUrl = picture?.creatorPic {
            if let nsProfileUrl = NSURL(string: profileImageUrl) {
                profileImageView.hnk_setImageFromURL(nsProfileUrl)
            }
        }
        if let name = picture?.creator {
            nameLabel.text = name
            moreFromLabel.text = "More from \(name)"
        }
        if let likes = picture?.likes {
            likesLabel.text = "\(likes) likes"
        }
        if let date = picture?.createdAt {
            let formattedDate = timeAgoSinceDate(date, numericDates: true)
            dateLabel.text = "\(formattedDate) ago"
        }
        
        if picture?.portfolioURL == "" {
            portfolioButton.hidden = true
        }
        
    }

    // Remove status bar
    override func prefersStatusBarHidden() -> Bool {
        return true
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // MARK: - collectionViewDataSource
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier("detailCell", forIndexPath: indexPath) as! DetailCollectionViewCell
        
        cell.imageView.image = nil
        if let pictureUrl = NSURL(string:pictureArray[indexPath.row].regularImageURL) {
            // Asynchronously loads images, caches images, and pulls from cache
            cell.imageView.hnk_setImageFromURL(pictureUrl)
        }
        
        return cell
    }
    
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return pictureArray.count
    }
    
    func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
        self.picture = pictureArray[indexPath.row]
        self.viewDidLoad()
    }
    
    // MARK: - IBAction
    @IBAction func dismissButton(sender: UIButton) {
        self.dismissViewControllerAnimated(true, completion: nil)
    }
    
    
    @IBAction func portfolioButtonPressed(sender: UIButton) {
        if let portfolioUrl = picture?.portfolioURL {
            UIApplication.sharedApplication().openURL(NSURL(string: portfolioUrl)!)
        }
    }
    
    // MARK: - Functions
    // Load photos from a particular username
    func loadPersonalData(username: String) {
        
        let url = "https://api.unsplash.com/users/" + username + "/photos/"
        let headers = [
            "Authorization": "Client-ID " + "\(applicationID)"
        ]
        
        Alamofire.request(.GET, url, parameters: nil, headers: headers)
            .responseJSON { response in
                
                if let value = response.result.value {
                    let json = JSON(value)
//                    print(json)
                    for (_,subJson):(String, SwiftyJSON.JSON) in json {
                        var picture = Picture()
                        
                        if let id = subJson["id"].string {
                            if id == self.picture!.id {
                                continue
                            }
                            picture.id = id
                        }
                        if let createdAt = subJson["created_at"].string {
                            let dateFor: NSDateFormatter = NSDateFormatter()
                            dateFor.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZ"
                            if let picDate: NSDate = dateFor.dateFromString(createdAt) {
                                picture.createdAt = picDate
                            }
                            
                        }
                        if let likes = subJson["likes"].int {
                            picture.likes = likes
                        }
                        if let creator = subJson["user"]["name"].string {
                            picture.creator = creator
                        }
                        if let creatorPic = subJson["user"]["profile_image"]["medium"].string {
                            picture.creatorPic = creatorPic
                        }
                        if let portfolioURL = subJson["user"]["portfolio_url"].string {
                            picture.portfolioURL = portfolioURL
                        }
                        if let fullImageURL = subJson["urls"]["full"].string {
                            picture.fullImageURL = fullImageURL
                        }
                        if let regularImageURL = subJson["urls"]["regular"].string {
                            picture.regularImageURL = regularImageURL
                        }
                        if let smallImageURL = subJson["urls"]["small"].string {
                            picture.smallImageURL = smallImageURL
                        }
                        if let username = subJson["user"]["username"].string {
                            picture.username = username
                        }
                        
                        self.pictureArray.append(picture)
                        
                    }
                } else {
                    print("No value loaded")
                }
                if self.pictureArray.count == 0 {
                    self.moreFromLabel.hidden = true
                }
                self.collectionView.reloadData()
        }
    }
    
    // Format time to be time ago
    func timeAgoSinceDate(date:NSDate, numericDates:Bool) -> String {
        let calendar = NSCalendar.currentCalendar()
        let unitFlags: NSCalendarUnit = [NSCalendarUnit.Minute, NSCalendarUnit.Hour, NSCalendarUnit.Day, NSCalendarUnit.WeekOfYear, NSCalendarUnit.Month, NSCalendarUnit.Year, NSCalendarUnit.Second]
        let now = NSDate()
        let earliest = now.earlierDate(date)
        let latest = (earliest == now) ? date : now
        let components:NSDateComponents = calendar.components(unitFlags, fromDate: earliest, toDate: latest, options: [])
        
        
        if (components.year >= 2) {
            return "\(components.year)y"
        } else if (components.year >= 1){
            if (numericDates){
                return "1y"
            } else {
                return "Last year"
            }
        } else if (components.month >= 2) {
            return "\(components.month)mo"
        } else if (components.month >= 1){
            if (numericDates){
                return "1mo"
            } else {
                return "Last month"
            }
        } else if (components.weekOfYear >= 2) {
            return "\(components.weekOfYear)w"
        } else if (components.weekOfYear >= 1){
            if (numericDates){
                return "1w"
            } else {
                return "Last week"
            }
        } else if (components.day >= 2) {
            return "\(components.day)d"
        } else if (components.day >= 1){
            if (numericDates){
                return "1d"
            } else {
                return "Yesterday"
            }
        } else if (components.hour >= 2) {
            return "\(components.hour)h"
        } else if (components.hour >= 1){
            if (numericDates){
                return "1h"
            } else {
                return "An hour ago"
            }
        } else if (components.minute >= 2) {
            return "\(components.minute)m"
        } else if (components.minute >= 1){
            if (numericDates){
                return "1m"
            } else {
                return "A minute ago"
            }
        } else if (components.second >= 3) {
            return "\(components.second)s"
        } else {
            return "1s"
        }
        
    }

}
