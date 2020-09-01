//
//  SCN.swift
//  AR_Camera
//
//  Created by Justin Lee on 2/26/20.
//  Copyright © 2020 com.lee. All rights reserved.
//

import Foundation
import SceneKit
import ARKit

extension SCNScene {
    func update(){
        rootNode.update()
    }
}

extension SCNNode {
    @objc func update() {
       for child in childNodes {
            child.update()
        }
    }
    
    func cleanup() {
         for child in childNodes {
             child.cleanup()
         }
         geometry = nil
     }
}
