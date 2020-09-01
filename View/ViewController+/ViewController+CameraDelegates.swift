//
//  ViewController+CameraDelegates.swift
//  AR_Camera
//
//  Created by Justin Lee on 5/12/20.
//  Copyright © 2020 com.lee. All rights reserved.
//

import AVFoundation
import Foundation
import Photos
import UIKit
import ImageIO
import Firebase



extension ViewController: SnapToViewDelegate, VideoToViewDelegate, PreviewToCameraDelegate  {
    func addPhotoToStrip(img: UIImage) {
        playStripButton.isHidden = false 
        let cel = Cel()
        cel.isPicture = true
        cel.isVideo = false
        cel.isGif = false
        
        let now = Date()
        let stamp = Timestamp(date: now)
        cel.timeStamp = stamp
        
        cel.picture = img
        self.strip.append(cel)
    }
    
    func addVideoToStrip(url: URL) {
        playStripButton.isHidden = false
        let cel = Cel()
        cel.isVideo = true
        cel.isPicture = false
        cel.isGif = false
        
        let now = Date()
        let stamp = Timestamp(date: now)
        cel.timeStamp = stamp
        
        
        cel.url = url
        self.strip.append(cel)
    }
    
    func addGifToStrip(gif: [UIImage]){
        playStripButton.isHidden = false
        let cel = Cel()
        cel.isGif = true
        cel.isPicture = false
        cel.isVideo = false
        
        let now = Date()
        let stamp = Timestamp(date: now)
        cel.timeStamp = stamp
        
        cel.gif = gif
        self.strip.append(cel)
    }
    
    
    func addToGif(img: UIImage) {
        stopMotionButton.setImage(UIImage(named:"PlayPurple"), for: .normal)
        self.pImg.append(img)
    }
    
    func unload(){
        self.isPlayingStrip = false
        self.isPlayingStopMotion = false
        self.isImageToPreview = false
        self.isVideoToPreview = false
        
        if  ProcessInfo.processInfo.thermalState == .nominal {
            self.greenScreenButton.isHidden = false
            self.currentFrameRate = 30
            self.sceneView.preferredFramesPerSecond = currentFrameRate
        } else if ProcessInfo.processInfo.thermalState == .fair {
            self.greenScreenButton.isHidden = false
            self.currentFrameRate = 20
            self.sceneView.preferredFramesPerSecond = currentFrameRate
        } else if ProcessInfo.processInfo.thermalState == .serious {
            self.currentFrameRate = 15
            self.greenScreenButton.isHidden = false
            self.sceneView.preferredFramesPerSecond = currentFrameRate
        } else if ProcessInfo.processInfo.thermalState == .critical {
            self.currentFrameRate = 10
            self.removeAllObjects()
            self.greenScreenButton.isHidden = true
            self.sceneView.preferredFramesPerSecond = currentFrameRate
        }
        
    }
    
    func removeGif(){
        stopMotionButton.setImage(UIImage(named:"StopMotion"), for: .normal)
        self.pImg.removeAll()
    }
    
    func deleteStrip(){
        self.playStripButton.isHidden = true 
        self.strip.removeAll()
    }
    

    func videoToPreview(URL: URL, assetWriter: AVAssetWriter) {
        self.urlToPreview = URL
        self.assetWriter = assetWriter
        self.isVideoToPreview = true
        self.isImageToPreview = false
        
        performSegue(withIdentifier: "showPreview", sender: self)
    }
    
    func sendImageToPreview() {
        self.img = sceneView.snapshot()
        self.isVideoToPreview = false
        self.isImageToPreview = true
        performSegue(withIdentifier: "showPreview", sender: self)
    }
    
}


