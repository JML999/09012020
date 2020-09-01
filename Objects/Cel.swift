//
//  Cel.swift
//  AR_Camera
//
//  Created by Justin Lee on 6/4/20.
//  Copyright © 2020 com.lee. All rights reserved.
//

import Foundation
import UIKit
import Firebase

public class Cel {
    var isVideo = false
    var isPicture = false
    var isGif = false
    
    var url: URL?
    var urlString = ""
    
    var username = ""
    var userID = ""
    var stripID: String?
    
    var timeStamp: Timestamp?
    
    var picture: UIImage?
    var gif: [UIImage]?
}
