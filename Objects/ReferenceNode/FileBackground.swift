import Foundation
import ARKit

class FileBackground: ReferenceNode {
    var index : Int = 0
    var counter: Int = 0
    
    var slowNums: [Int] = [30, 60]
    var nums: [Int] = [15,30,45,50,65]
    var fastNums = [15,30,45,50,65]
    
    var textureURLs = [URL]()
    var orderedURLs = [URL]()
    
    var textures = [SCNMaterial]()
    var activeTexture = [SCNMaterial]()
    var firstTexture: SCNMaterial?

    var textureCount: Int?
    var imageCount: Int?
    var isPortrait = false
    var isLandscape = true
    
    let refURL: URL?
    let node = SCNNode()
    
    
    override init?(url referenceURL: URL) {
        self.refURL = referenceURL
        super.init(url: referenceURL)
        self.loadingPolicy = .onDemand
        buildObject()
       
        textureURLs.sort(by: {$0.absoluteString < $1.absoluteString})
        
        for image in orderedURLs {
            print("Sorted???: \(image.absoluteString)")
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func buildObject() {
        isBackground = true
    
        geometry = SCNPlane(width: 4, height: 2)
        self.geometry = geometry
    
        textureURLs = loadTextureURLs()
        textures = loadTextures(textureURLs: textureURLs)
        textureCount = textures.count
        
        firstTexture = loadFirstTexture(texturesURLs: textureURLs)
        imageCount = textureURLs.count
    
        self.geometry?.firstMaterial? = firstTexture!
        self.pivot = SCNMatrix4MakeTranslation(0.0, -1.0, 0.0)
    }
    
    func toggleOrientation(){
        if isLandscape {
            self.geometry = nil 
            geometry = SCNPlane(width: 2, height: 4)
            self.geometry = geometry
            isLandscape = false
            isPortrait = true
            
        } else if isPortrait {
            self.geometry = nil
            geometry = SCNPlane(width: 4, height: 2)
            self.geometry = geometry
            isLandscape = true
            isPortrait = false
        }

    }
    
    func loadTextureURLs()->[URL]{
        let textureURLS = refURL
        
        let fileEnumerator = FileManager().enumerator(at: textureURLS!, includingPropertiesForKeys: [])!
        
        return fileEnumerator.compactMap { element in
            let url = element as! URL
            
            guard url.pathExtension == "png" || url.pathExtension == "jpg" else { return nil}
        
            return url
        }
    }
    
    func loadTextures(textureURLs: [URL]) -> [SCNMaterial] {
        for url in textureURLs {
            let material = SCNMaterial()
            material.diffuse.contents = url
            textures.append(material)
        }
        return textures
    }
    
    func loadFirstTexture(texturesURLs: [URL]) -> SCNMaterial {
        let url = texturesURLs[0]
        let material = SCNMaterial()
        material.diffuse.contents = url
        return material
    }
    
    override func update() {
        /*
        let textureCount : Int = textureURLs.count
        if index <= textureCount - 1 {
            let diffuse = textureURLs[index]
             print("Current diffuse:  \(diffuse)")
            self.geometry?.firstMaterial?.diffuse.contents = diffuse
            index += 1
        } else {
            if index > textureCount - 1{
                index = 0
                let diffuse = textureURLs[index]
                self.geometry?.firstMaterial?.diffuse.contents = diffuse
            }
        }
    */
        if nums.contains(counter){
            let textureCount : Int = textureURLs.count
            if index <= textureCount - 1 {
                let diffuse = textureURLs[index]
                 print("Current diffuse:  \(diffuse)")
                self.geometry?.firstMaterial?.diffuse.contents = diffuse
                index += 1
            } else {
                if index > textureCount - 1{
                    index = 0
                    let diffuse = textureURLs[index]
                    self.geometry?.firstMaterial?.diffuse.contents = diffuse
                }
            }
            
        }
        if counter > 60 {
            counter = 0
        } else {
            counter += 1
        }
    }
   
        
}
