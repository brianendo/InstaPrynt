//
//  ViewController.swift
//  InstaPrynt
//
//  Created by Brian Endo on 6/23/16.
//  Copyright © 2016 Brian Endo. All rights reserved.
//

import UIKit
import SwiftyJSON
import Alamofire
import FMMosaicLayout
import Haneke

let applicationID = "7e37ba481f6ff06d733967c071d2a5bfeb337a13161d6540551dee1d73387c88"

class ViewController: UIViewController, UICollectionViewDelegate, UICollectionViewDataSource, FMMosaicLayoutDelegate {
    
    // MARK: - Variables
    @IBOutlet weak var collectionView: UICollectionView!
    
    var page = 1
    var index = 0
    var pictureArray = [Picture]()
    private var lastContentOffset: CGFloat = 0
    var isLoading = false
    
    // MARK: - viewDidLoad
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        // Set up collectionView with the mosaicLayout
        let mosaicLayout: FMMosaicLayout = FMMosaicLayout.init()
        collectionView.collectionViewLayout = mosaicLayout
        
        collectionView.delegate = self
        collectionView.dataSource = self
        
        self.loadData()
    }

    // Remove Status bar
    override func prefersStatusBarHidden() -> Bool {
        return true
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // MARK: - collectionViewDataSource
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return pictureArray.count
    }
    
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier("pictureCell", forIndexPath: indexPath) as! PictureCollectionViewCell
        
        let pictureUrl = NSURL(string: pictureArray[indexPath.row].regularImageURL)
        // If this image is already cached, don't re-download
        
        cell.imageView.image = nil
        // Asynchronously loads images, caches images, and pulls from cache
        cell.imageView.hnk_setImageFromURL(pictureUrl!)
        
        return cell
    }
    
    // MARK: - collectionViewDelegate
    func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
        index = indexPath.row
        self.performSegueWithIdentifier("segueToDetail", sender: self)
    }
    
    
    // MARK: - FMMosaicLayoutDelegate
    func collectionView(collectionView: UICollectionView!, layout collectionViewLayout: FMMosaicLayout!, numberOfColumnsInSection section: Int) -> Int {
        return 2
    }
    
    func collectionView(collectionView: UICollectionView!, layout collectionViewLayout: FMMosaicLayout!, insetForSectionAtIndex section: Int) -> UIEdgeInsets {
        return UIEdgeInsets(top: 2.0, left: 2.0, bottom: 2.0, right: 2.0)
    }
    
    func collectionView(collectionView: UICollectionView!, layout collectionViewLayout: FMMosaicLayout!, interitemSpacingForSectionAtIndex section: Int) -> CGFloat {
        return 3.0
    }
    
    func collectionView(collectionView: UICollectionView!, layout collectionViewLayout: FMMosaicLayout!, mosaicCellSizeForItemAtIndexPath indexPath: NSIndexPath!) -> FMMosaicCellSize {
        return indexPath.item % 4 == 0 ? FMMosaicCellSize.Big : FMMosaicCellSize.Small
    }
    
    
    // MARK: - Segues
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "segueToDetail" {
            let detailVC: DetailViewController = segue.destinationViewController as! DetailViewController
            detailVC.picture = pictureArray[index]
        }
    }
    
    
    
    // MARK: - Pagination functions
    // Used function to find an offset between the bounds and size
    func scrollViewDidScroll(scrollView: UIScrollView) {
        
        if (self.lastContentOffset > scrollView.contentOffset.y) {
            // move up
        }
        else if (self.lastContentOffset < scrollView.contentOffset.y) {
            // move down
            let offset = scrollView.contentOffset
            let bounds = scrollView.bounds
            let size = scrollView.contentSize
            let inset = scrollView.contentInset
            let y: CGFloat = offset.y + bounds.size.height - inset.bottom
            let h: CGFloat = size.height
            let reload_distance: CGFloat = 10
            if(y > h + reload_distance) {
                self.page += 1
                self.loadNextPage()
            }
        }
        self.lastContentOffset = scrollView.contentOffset.y
        
    }
    
    // Loads next page of data
    func loadNextPage() {
        
        // Check if loadData is being called
        if self.isLoading {
            return
        }
        print("Reached")
        self.isLoading = true
        self.loadData()
    }
    
    
    // Load all the data from the api
    func loadData() {
        let url = "https://api.unsplash.com/photos/"
        let headers = [
            "Authorization": "Client-ID " + "\(applicationID)"
        ]
        let parameters = [
            "page": page,
            "per_page": 30
        ]
        
        Alamofire.request(.GET, url, parameters: parameters, headers: headers)
            .responseJSON { response in
                
                if let value = response.result.value {
                    let json = JSON(value)
                    //                    print(json)
                    for (_,subJson):(String, SwiftyJSON.JSON) in json {
                        var picture = Picture()
                        
                        if let id = subJson["id"].string {
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
                self.collectionView.reloadData()
                self.isLoading = false
        }
    }


}

