//
//  Picture.swift
//  InstaPrynt
//
//  Created by Brian Endo on 6/23/16.
//  Copyright © 2016 Brian Endo. All rights reserved.
//

import Foundation

struct Picture {
    var id: String
    var creator: String
    var creatorPic: String
    var createdAt: NSDate
    var likes: Int
    var portfolioURL: String
    var fullImageURL: String
    var regularImageURL: String
    var smallImageURL: String
    var username: String
    
    init() {
        self.id = ""
        self.creator = ""
        self.creatorPic = ""
        self.createdAt = NSDate()
        self.likes = 0
        self.portfolioURL = ""
        self.fullImageURL = ""
        self.regularImageURL = ""
        self.smallImageURL = ""
        self.username = ""
    }
    
}