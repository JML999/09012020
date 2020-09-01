//
//  AppVariables.swift
//  AR_Camera
//
//  Created by Justin Lee on 3/26/20.
//  Copyright © 2020 com.lee. All rights reserved.
//

import Foundation
import UIKit

var screenWidth:CGFloat = CGFloat();
var screenHeight:CGFloat = CGFloat();

var cameraButtonDimension:CGFloat = CGFloat();
var cameraButtonMinY: CGFloat = CGFloat();

public func instantiateVariables() {
    cameraButtonDimension = screenWidth*0.2
    cameraButtonMinY = screenHeight*0.9 - cameraButtonDimension
}
