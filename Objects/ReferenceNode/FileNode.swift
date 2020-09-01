//
//  FileNode.swift
//  AR_Camera
//
//  Created by Justin Lee on 2/29/20.
//  Copyright © 2020 com.lee. All rights reserved.
//

import Foundation
import SceneKit
import ARKit

class FileNode : ReferenceNode {
    
    
    override var modelName: String {
        
        if isBackground {
            return self.name!
        }
        return referenceURL.lastPathComponent.replacingOccurrences(of: ".scn", with: "")
    }
    
    override func update() { }
}

extension FileNode {
    
    // Loads all the model objects within `Models.scnassets`.
   static let availableObjects: [FileNode] = {
        let modelsURL = Bundle.main.url(forResource: "Models.scnassets", withExtension: nil)!

        let fileEnumerator = FileManager().enumerator(at: modelsURL, includingPropertiesForKeys: [])!

        return fileEnumerator.compactMap { element in
            let url = element as! URL

            guard url.pathExtension == "scn" && !url.path.contains("lighting") else { return nil }

            return FileNode(url: url)
        }
    }()
    
}
