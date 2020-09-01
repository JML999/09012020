//
//  PreviewViewController.swift
//  AR_Camera
//
//  Created by Justin Lee on 3/21/20.
//  Copyright © 2020 com.lee. All rights reserved.
//



import UIKit
import ImageIO
import MobileCoreServices
import Photos
import Firebase


protocol PreviewToCameraDelegate: class {
    func addPhotoToStrip(img: UIImage)
    func addVideoToStrip(url: URL)
    func addGifToStrip(gif: [UIImage])
    
    func addToGif(img: UIImage)
    func unload()
    func removeGif()
    func deleteStrip()
}

enum PreviewTypes {
    case image
    case video
}

class PreviewViewController: UIViewController {
    
    public var previewType: PreviewTypes = .image
    public weak var delegate: PreviewToCameraDelegate? = nil
    
    public var videoURL: URL = URL(fileURLWithPath: "")
    public var stripURL: URL?
    let stripID = NSUUID().uuidString
    
    public var img: UIImage = UIImage()
    
    var pIMG : [UIImage]!
    var gif: [UIImage] = []
    var timer: Timer!
    var counter = 0
    var queueCounter = 0
    
    var currentStrip: [Cel] = []
    var savedStripIDs: [[String]] = []
    
    var assetWriter: AVAssetWriter?
    var camera: Camera?
    
    var isCreatingStopMotion = false
    var isPlayingStopMotion = false
    var isPlayingStrip = false
    
    var globalUser = ""
    var globalID = "" 
    
    private var player: AVPlayer?
    private var playerLayer: AVPlayerLayer?
    
    var items: [AVPlayerItem] = []
    private var playerQueue : AVQueuePlayer?
    private var queuePlayerLayer: AVPlayerLayer?
    var playerLooper: NSObject?
    
    @IBOutlet weak var preview: UIImageView!
    @IBOutlet weak var ffwButton: UIButton!
    @IBOutlet weak var rrwButton: UIButton!
    
    private var saveButton:SaveButton?
    private var cancelButton:CancelButton?
    private var stopMotionButton: StopMotionButton?
    private var addToStripButton: StripButton?
    private var uploadButton: UploadButton?
    let stripStamp = Date()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.preview.frame = CGRect(x: 0, y: 0, width: screenWidth, height: screenHeight)
               
        pIMG = [UIImage]()
        
        //UI
        initUI()
        
        if isPlayingStrip {
            self.addToStripButton!.isHidden = true

            NotificationCenter.default.addObserver(forName: .AVPlayerItemDidPlayToEndTime, object: self.playerQueue?.currentItem, queue: .main) { _ in
                          self.playerQueue?.seek(to: CMTime.zero)
                          self.playerQueue?.play()
        }
        } else {
            // Loop Observer
            NotificationCenter.default.addObserver(forName: .AVPlayerItemDidPlayToEndTime, object: self.player?.currentItem, queue: .main) { _ in
                       self.player?.seek(to: CMTime.zero)
                       self.player?.play()
                }
        }
        initPlayer()
    }
    
    
    override func viewWillDisappear(_ animated: Bool) {
        print("Swipe Worked")
        
        self.removePreview()
        self.dismiss(animated: true) {
            //FileManager.default.clearTmpDirectory();
        }
    }
    
    private func removePreview(){
        if isPlayingStopMotion || isPlayingStrip {
            if isPlayingStrip {
                let currentCel = currentStrip[queueCounter]
                if (currentCel.isGif){
                    timer.invalidate()
                    self.delegate!.removeGif()
                    isPlayingStopMotion = false
                    isCreatingStopMotion = false
                    print("Discharge strip @ gif")
                    return
                } else if currentCel.isVideo {
                    self.playerQueue?.pause()
                    self.queuePlayerLayer?.removeFromSuperlayer()
                    self.playerQueue = nil
                    self.queuePlayerLayer = nil
                    print("Discharge strip @ video")
                }
            } else {
                //Else is playing stop motion preview
                timer.invalidate()
                self.delegate!.removeGif()
                isPlayingStopMotion = false
                isCreatingStopMotion = false
                print("Discharge stop motion preview")
            }
        }
        
        // Preview Video
        self.player?.pause();
        self.playerLayer?.removeFromSuperlayer();
        self.player = nil;
        self.playerLayer = nil;
        
        self.saveButton!.removeFromSuperview();
        self.cancelButton!.removeFromSuperview();
        
        // Image
        if (self.preview != nil) {
            self.preview.image = nil
            self.preview.removeFromSuperview()
        }
        
        delegate!.unload()
    }
    
    func initUI(){
        self.saveButton = SaveButton()
        self.cancelButton = CancelButton()
        self.stopMotionButton = StopMotionButton()
        self.addToStripButton = StripButton()
        self.uploadButton = UploadButton()
        
        self.ffwButton.isHidden = true
        self.rrwButton.isHidden = true
        
        if isCreatingStopMotion == true {
            self.view.addSubview(self.stopMotionButton!)
            self.view.addSubview(self.saveButton!)
            self.view.addSubview(self.cancelButton!)
        } else if isPlayingStrip {
            self.view.addSubview(self.uploadButton!)
            self.view.addSubview(self.saveButton!)
            self.view.addSubview(self.cancelButton!)
            self.ffwButton.isHidden = false
            self.rrwButton.isHidden = false
        }
        
        // Image, Gif and Video Preview
        self.view.addSubview(self.saveButton!)
        self.view.addSubview(self.cancelButton!)
        self.view.addSubview(self.addToStripButton!)
        
        self.saveButton!.addTarget(self, action: #selector(self.saveButtonPressed), for: .touchUpInside)
        self.cancelButton!.addTarget(self, action: #selector(self.cancelButtonPressed), for: .touchUpInside)
        self.stopMotionButton!.addTarget(self, action: #selector(self.stopMotionButtonPressed), for: .touchUpInside)
        self.addToStripButton!.addTarget(self, action: #selector(self.addToStripButtonPressed), for: .touchUpInside)
        self.uploadButton!.addTarget(self, action: #selector(self.uploadButtonPressed), for: .touchUpInside)
        
    }
    
    func initPlayer(){
        if isPlayingStrip == true {
            ffwButton.isHidden = false
            rrwButton.isHidden = false
            playStrip()
        } else if previewType == .image {
            if isPlayingStopMotion == true {
                playStopMotion()
                return
            } else {
                preview.image = img
                pIMG.append(img)
            }
        } else if previewType == .video {
            createPreviewVideo()
        }
    }
    
    func playStopMotion(){
        timer = Timer.scheduledTimer(timeInterval: 0.15, target: self, selector: #selector(self.display), userInfo: nil, repeats: true)
    }
    
    @objc func display(){
        if !(gif.count == counter){
            preview.image = gif[counter]
            counter += 1
        } else {
            counter = 0
        }
    }
    
    private func createPreviewVideo(){
        guard self.videoURL.absoluteString != "" else {
            print("No video url")
            return
        }
        
        self.player = AVPlayer(url: self.videoURL)
        guard self.player != nil else {
            print("Failed to create player")
            return
        }
        
        self.playerLayer = AVPlayerLayer()
        self.playerLayer? = AVPlayerLayer(player: self.player)
        self.playerLayer?.frame = self.view.layer.bounds
        self.playerLayer?.videoGravity = AVLayerVideoGravity.resizeAspectFill
        self.view!.layer.addSublayer(playerLayer!)
        
        // Bring buttons to front
        DispatchQueue.main.async {
            self.view.addSubview(self.saveButton!)
            self.view.addSubview(self.cancelButton!)
            self.view.addSubview(self.addToStripButton!)
            self.view.addSubview(self.uploadButton!)
            if self.isPlayingStrip {
                self.uploadButton?.isHidden = false
                self.saveButton?.isHidden = true
            } else {
                self.uploadButton?.isHidden = true
                self.saveButton?.isHidden = false
            }
            self.player!.play();
        }
    }

    
    // MARK : BUTTON FUNCTIONALITY
    
    @objc private func uploadButtonPressed() {
        self.dismiss(animated: true) {
            self.saveStripToFireBase()
            print("Strip Uploaded")
        }
    }
    
    @objc private func saveButtonPressed() {
        if isPlayingStrip {
            saveToDisk()
            print("File Saved!!!!")
            if savedStripIDs.count > 0 {
                for stripID in savedStripIDs {
                    for str in stripID {
                        do {
                            let url = URL(fileURLWithPath: str)
                            try FileManager.default.removeItem(at: url)
                            print("Picture with ID ", str, " Deleted ")
                        } catch {
                            print("Could not delete file: \(error)")
                        }
                    }
                }
            }
            return
        } else {
            if self.previewType == .video {
                self.dismiss(animated: true) {
                    print("Video Saved")
                    self.exportVideo()
                }
            }
            else {
                if isPlayingStopMotion {
                    self.dismiss(animated: true) {
                        self.createGIF(images: self.gif)
                    }
                } else {
                    self.dismiss(animated: true) {
                        //Need to implement save single img
                        self.createGIF(images: self.pIMG)
                    }
                }
            }
        }
    }
    
    @objc private func cancelButtonPressed() {
        print("CANCEL BUTTON PRESSED")
        self.dismiss(animated: true) {
            FileManager.default.clearTmpDirectory();
            self.delegate!.deleteStrip()
        }
    }
    
    @objc private func addToStripButtonPressed() {
         print("STRIP BUTTON PRESSED")
         self.dismiss(animated: true) {
            
            if self.gif.count > 0 {
                self.delegate!.addGifToStrip(gif: self.gif)
                return
            }
            
            if self.previewType == .image {
                self.delegate!.addPhotoToStrip(img: self.img)
            } else if self.previewType == .video {
                self.delegate!.addVideoToStrip(url: self.videoURL)
            }
            //  FileManager.default.clearTmpDirectory();
         }
     }
    
    @objc private func stopMotionButtonPressed() {
        self.delegate?.addToGif(img: img)
        print("Image added to gif")
        //removePreview()
        self.dismiss(animated: true) {}
    }
    
    func playStrip(){
        print("qCount: ", queueCounter)
        if !((currentStrip.count) <= queueCounter){
            print("Current Strip Gif: ", currentStrip[queueCounter].isGif)
            print("Current Strip Pic: ", currentStrip[queueCounter].isPicture)
            print("Current Strip Vid: ", currentStrip[queueCounter].isVideo)
            let currentCel = currentStrip[queueCounter]
            displayCel(currentCel: currentCel)
        } else {
            queueCounter = 0
            print("0 Index of Gif: ")
            print("Current Strip Gif: ", currentStrip[queueCounter].isGif)
            print("Current Strip Pic: ", currentStrip[queueCounter].isPicture)
            print("Current Strip Vid: ", currentStrip[queueCounter].isVideo)
            let currentCel = currentStrip[queueCounter]
            displayCel(currentCel: currentCel)
        }
    }
       
    func displayCel(currentCel: Cel){
        if currentCel.isPicture {
            self.img = currentCel.picture!
            preview.image = img
        } else if currentCel.isVideo {
            self.previewType = .video
            self.videoURL = currentCel.url!
            createStripVideo()
        } else if currentCel.isGif {
            self.gif = currentCel.gif!
            playStopMotion()
        }
    }
       
    private func createStripVideo(){
        self.playerQueue = AVQueuePlayer.init()
        self.playerQueue!.removeAllItems()
        
        let playerItem = AVPlayerItem.init(url: videoURL)
        self.playerQueue!.insert(playerItem, after: nil)
      
           
        self.queuePlayerLayer = AVPlayerLayer()
        self.queuePlayerLayer = AVPlayerLayer(player: playerQueue)
        playerLooper = AVPlayerLooper(player: self.playerQueue!, templateItem: playerItem)
        self.queuePlayerLayer?.frame = self.view.layer.bounds
        self.queuePlayerLayer!.videoGravity = AVLayerVideoGravity.resizeAspectFill
        self.view!.layer.addSublayer(queuePlayerLayer!)
           
        // Bring buttons to front
        DispatchQueue.main.async {
            // Add Buttons
            self.view.addSubview(self.saveButton!)
            self.view.addSubview(self.cancelButton!)
            self.view.addSubview(self.addToStripButton!)
            self.view.addSubview(self.ffwButton)
            self.view.addSubview(self.rrwButton)
            self.view.addSubview(self.uploadButton!)
            self.uploadButton?.isHidden = false
            self.playerQueue!.play();
        }
           
    }
    
    @IBAction func ffwButtonPressed(){
        print(currentStrip.count)
        print(queueCounter + 1)
        
        let currentCel = currentStrip[queueCounter]
        if currentCel.isVideo{
            self.playerQueue?.pause();
            self.queuePlayerLayer?.removeFromSuperlayer();
            self.playerQueue = nil;
            self.queuePlayerLayer = nil;
        } else if currentCel.isGif {
            timer.invalidate()
        }
        
        queueCounter += 1
        playStrip()
        
    }
    
    @IBAction func rrwButtonPressed(){
        if (queueCounter == 0){
            return
        }
        queueCounter -= 1
        playStrip()
    }
    
    /*
    @IBAction func saveAction(_ sender: Any) {
        createGIF(images: pIMG)
        dismiss(animated: true, completion: nil)
    }
    
    @IBAction func closeAction(_ sender: Any) {
        timer.invalidate()
        dismiss(animated: true, completion: nil)
    }
    */
    
    
}

extension PreviewViewController {
    func createGIF(images: [UIImage]){
        let fileProperties: CFDictionary = [kCGImagePropertyGIFDictionary as String: [kCGImagePropertyGIFLoopCount as String: 0]] as CFDictionary
        let frameProperties: CFDictionary = [kCGImagePropertyGIFDictionary as String: [kCGImagePropertyGIFUnclampedDelayTime as String: 0.15]] as CFDictionary
        
        let documentsDirectoryURL: URL? = try? FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
        let fileURL: URL? = documentsDirectoryURL?.appendingPathComponent("animated.gif")
        
        if let url = fileURL as CFURL? {
            if let destination = CGImageDestinationCreateWithURL(url, kUTTypeGIF, images.count, nil) {
                CGImageDestinationSetProperties(destination, fileProperties)
                for image in images {
                    if let cgImage = image.cgImage {
                        CGImageDestinationAddImage(destination, cgImage, frameProperties)
                    }
                }
                if !CGImageDestinationFinalize(destination){
                    print("Failed to finalize the image destination")
                }
                print("URL = \(fileURL!)")
            }
        }
        
        PHPhotoLibrary.shared().performChanges({
            //Request creating an asset from the image
            PHAssetChangeRequest.creationRequestForAssetFromImage(atFileURL: fileURL!)
        })
    }
    
    func createGIFForCloud(images: [UIImage]) -> URL{
        let fileProperties: CFDictionary = [kCGImagePropertyGIFDictionary as String: [kCGImagePropertyGIFLoopCount as String: 0]] as CFDictionary
        let frameProperties: CFDictionary = [kCGImagePropertyGIFDictionary as String: [kCGImagePropertyGIFUnclampedDelayTime as String: 0.15]] as CFDictionary
        
        let documentsDirectoryURL: URL? = try? FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
        let fileURL: URL? = documentsDirectoryURL?.appendingPathComponent("animated.gif")
        
        if let url = fileURL as CFURL? {
            if let destination = CGImageDestinationCreateWithURL(url, kUTTypeGIF, images.count, nil) {
                CGImageDestinationSetProperties(destination, fileProperties)
                for image in images {
                    if let cgImage = image.cgImage {
                        CGImageDestinationAddImage(destination, cgImage, frameProperties)
                    }
                }
                if !CGImageDestinationFinalize(destination){
                    print("Failed to finalize the image destination")
                }
                print("URL = \(fileURL!)")
                return fileURL!
            }
        }
        return fileURL!
    }
    
    public func exportVideo() {
        PHPhotoLibrary.requestAuthorization({ (status) in
            PHPhotoLibrary.shared().performChanges({
                PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: (self.assetWriter?.outputURL)!)
            }) { saved, error in
                
                guard error == nil else {
                    print("failed to save video");
                    print("error : \(String(describing: error))")
                    return
                }
                
       //         self.videoInput = nil;
       //         self.pixelBufferAdaptor = nil;
                self.assetWriter = nil;
                
                
               // FileManager.default.clearTmpDirectory();
            }
        })
    }
}

extension PreviewViewController {
   public func saveToDisk(){
        for cel in currentStrip{
            if cel.isPicture {
                let img = cel.picture
                let saveID = saveImage(image: img!)
                print(saveID)
                var single: [String] = []
                single.append(saveID)
                savedStripIDs.append(single)
            } else if cel.isGif {
                var multi : [String] = []
                for image in cel.gif! {
                    let saveID = saveImage(image: image)
                    multi.append(saveID)
                }
                savedStripIDs.append(multi)
            } else if cel.isVideo {
                let saveID = saveVideo(url: cel.url!)
                var single: [String] = []
                single.append(saveID)
                savedStripIDs.append(single)
            }
        }
    }
    
    public func saveImage(image: UIImage) -> String {
        let imageData = NSData(data: image.pngData()!)
        let paths = NSSearchPathForDirectoriesInDomains(FileManager.SearchPathDirectory.documentDirectory,  FileManager.SearchPathDomainMask.userDomainMask, true)
        let docs = paths[0] as NSString
        let uuid = NSUUID().uuidString + ".png"
        let fullPath = docs.appendingPathComponent(uuid)
        _ = imageData.write(toFile: fullPath, atomically: true)
        return uuid
     }
    
    public func saveVideo(url: URL) -> String {
        let videoData = NSData(contentsOf: videoURL)
        let paths = NSSearchPathForDirectoriesInDomains(FileManager.SearchPathDirectory.documentDirectory,  FileManager.SearchPathDomainMask.userDomainMask, true)
        let docs = paths[0] as NSString
        let uuid = NSUUID().uuidString + ".mp4"
        let fullPath = docs.appendingPathComponent(uuid)
        _ = videoData?.write(toFile: fullPath, atomically: false)
        return uuid
    }
    
    public func saveStripToFireBase(){
        for cel in currentStrip{
            if cel.isPicture {
                let img = cel.picture
                let stamp = cel.timeStamp
                updloadPictureToCloud(image: img!, ID: stripID, timestamp: stamp!)
            } else if cel.isGif {
                let g = cel.gif
                let gifURL = createGIFForCloud(images: g!)
                let stamp = cel.timeStamp
                uploadGIFToCloud(url: gifURL, ID: stripID, timestamp: stamp!)
            } else if cel.isVideo {
                let stamp = cel.timeStamp
                uploadVideoToCloud(vidurl: cel.url!, ID: stripID, timestamp: stamp!)
            }
        }
    }
    
    public func updloadPictureToCloud(image: UIImage, ID: String, timestamp: Timestamp) {
        let typeCode = "0"
        let d: Data = image.jpegData(compressionQuality: 0.5)!
        let md = StorageMetadata()
        md.contentType = "image/jpg"
        let picID = NSUUID().uuidString
        let ref = Storage.storage().reference().child("\(globalID)/strips/\(ID)/\(picID).jpg")
        ref.putData(d, metadata: md) { (metadata, error) in
            if error == nil {
                ref.downloadURL(completion: { (url, error) in
                   // print("Done, url is \(String(describing: url))")
                    let photoURL = url?.absoluteString
                    self.sendDataToDatabase(URL: photoURL!, typeCode: typeCode, timestamp: timestamp)
                })
            } else {
                print("error \(String(describing: error))")
            }
        }
     }
    

    
    public func uploadVideoToCloud(vidurl: URL, ID: String, timestamp: Timestamp) {
        let typeCode = "2"
        let vidID = NSUUID().uuidString
        let ref = Storage.storage().reference().child("\(globalID)/strips/\(ID)/\(vidID).mov")
        ref.putFile(from: vidurl as URL, metadata: nil) { (metadata, error) in
            if error == nil {
                print("Successful video upload")
                ref.downloadURL(completion: { (url, error) in
                    print("Done, url is \(String(describing: url))")
                    guard let vURL = url?.absoluteString else {return}
                    self.sendDataToDatabase(URL: vURL, typeCode: typeCode, timestamp: timestamp)
                })
            } else {
                print(error!.localizedDescription)
            }
        }
    }
    
    public func uploadGIFToCloud(url: URL, ID: String, timestamp: Timestamp) {
        let typeCode = "1"
        let gifID = NSUUID().uuidString
        let ref = Storage.storage().reference().child("\(globalID)/strips/\(ID)/\(gifID).gif")
        ref.putFile(from: url as URL, metadata: nil) { (metadata, error) in
            if error == nil {
               // print("Successful gif upload")
                ref.downloadURL(completion: { (url, error) in
                    print("Done, url is \(String(describing: url))")
                    guard let gifURL = url?.absoluteString else {return}
                    self.sendDataToDatabase(URL: gifURL, typeCode: typeCode, timestamp: timestamp)
                })
            } else {
                print(error!.localizedDescription)
            }
        }
    }
    
    func sendDataToDatabase(URL: String, typeCode: String, timestamp: Timestamp){
        let db = Firestore.firestore()
        
        let userref = db.collection("Strips").document("\(globalID)").collection("\(stripID)").document()
        userref.setData(["PostUrl" : URL])
        userref.updateData(["PostCode" : typeCode])
        userref.updateData(["Time" : timestamp])
        userref.updateData(["Strip" : stripID])
        
        let userref2 = db.collection("users").document("\(globalID)")
        userref2.updateData(["StripIDs" : FieldValue.arrayUnion(["\(stripID)"])])
        
        let userref3 = db.collection("Posts").document("\(globalID)").collection("userPosts").document("\(stripID)")
        userref3.setData(["Date" : stripStamp])
        let celsInStrip = userref3.collection("Cels").document()
        celsInStrip.setData(["PostUrl" : URL])
        celsInStrip.updateData(["PostCode" : typeCode])
        celsInStrip.updateData(["Time" : timestamp])
        celsInStrip.updateData(["Strip" : stripID])
        //NEW
        celsInStrip.updateData(["UserID" : globalID])
        celsInStrip.updateData(["Username" : globalUser])
        celsInStrip.updateData(["Title" : timestamp.dateValue()])
        
    }
    
}


