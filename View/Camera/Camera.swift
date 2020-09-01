//
//  CameraSetup.swift
//  AR_Camera
//
//  Created by Justin Lee on 3/21/20.
//  Copyright © 2020 com.lee. All rights reserved.
//

import Foundation
import AVFoundation
import UIKit
import ARKit
import Photos
import ImageIO
import MobileCoreServices


protocol VideoToViewDelegate: class {
    func videoToPreview(URL: URL, assetWriter: AVAssetWriter)
}

class Camera: NSObject{
    
    var pixelBufferAdaptor: AVAssetWriterInputPixelBufferAdaptor?
    var videoInput: AVAssetWriterInput?
    var assetWriter: AVAssetWriter?
    var sceneView: VirtualObjectARView?
    
    weak var delegate: VideoToViewDelegate? = nil
    
    var isRecording = false
    var recordingStartTime = TimeInterval(0)
    public var videoStartTime:CMTime?
    
    private var cgSize: CGSize?
    var snapshotArray: [[String:Any]] = [[String:Any]]()
    var lastTime:TimeInterval = 0
    
    let scale = CMTimeScale(NSEC_PER_SEC)
    
    var previewLayer: AVCaptureVideoPreviewLayer?
    
    // Audio
    var captureSession: AVCaptureSession?
    var audioInput:AVAssetWriterInput?;
    var micInput:AVCaptureDeviceInput?
    var audioOutput:AVCaptureAudioDataOutput?
    var recordingSession:AVAudioSession!
    
    fileprivate let recordingQueue = DispatchQueue(label: "com.takecian.RecordingQueue", attributes: [])
    
    init(size: CGSize){
        self.cgSize = size
    }
    
    func startRecording(size: CGSize) {
        self.createURLForVideo(withName: "test") {(videoURL) in
            self.prepareWriterAndInput(size: size, videoURL: videoURL, completionHandler: { (error) in
                guard error == nil else {
                    return
                }

                
                self.startAudioRecording { (result) in
                    guard result == true else {
                        print("FAILED TO START AUDIO SESSION")
                        return
                    }
                    print("AUDIO SESSION ALLOWED");
                    self.videoStartTime = CMTime.zero
                    self.lastTime = 0
                    self.isRecording = true

                }
            })
        }
    }
    
    
    func endRecording(){
        self.isRecording = false;
    
        self.captureSession!.stopRunning()
        self.finishVideoRecording{ (videoURL) in
            print("Video URL")
            self.videoInput = nil;
            self.pixelBufferAdaptor = nil;
            DispatchQueue.main.async {
                self.delegate?.videoToPreview(URL: videoURL, assetWriter: self.assetWriter!)
            }
        }
        
    //    self.exportVideo()

    }
        
    
    func createURLForVideo(withName: String, completionHandler:@escaping (URL)->()){
        // Clear the location for the temporary file
        let temporaryDirectoryURL: URL = URL.init(fileURLWithPath: NSTemporaryDirectory(), isDirectory: true)
        let targetURL: URL = temporaryDirectoryURL.appendingPathComponent("\(withName).mp4")
        
        //Delete file, incase it exists
        do {
            try FileManager.default.removeItem(at: targetURL)
        } catch let error {
            NSLog("Unable to delete file, with error: \(error)")
        }
        completionHandler(targetURL)
    }
    
    private func prepareWriterAndInput(size:CGSize, videoURL:URL, completionHandler:@escaping(Error?)->()) {
        do {
            
            self.assetWriter = try AVAssetWriter(outputURL: videoURL, fileType: AVFileType.mp4)
            
            let videoOutputSettings: Dictionary<String, Any> = [
                AVVideoCodecKey : AVVideoCodecType.h264,
                AVVideoWidthKey : size.width,
                AVVideoHeightKey : size.height
            ]
    
            self.videoInput  = AVAssetWriterInput (mediaType: AVMediaType.video, outputSettings: videoOutputSettings)
            self.videoInput!.expectsMediaDataInRealTime = true
            self.assetWriter!.add(self.videoInput!)
            
            // Input is the mic audio of the AVAudioEngine
            let audioOutputSettings = [
                AVFormatIDKey : kAudioFormatMPEG4AAC,
                AVNumberOfChannelsKey : 1,
                AVSampleRateKey : 44100.0,
                AVEncoderBitRateKey: 192000,
            ] as [String : Any]
            
            self.audioInput = AVAssetWriterInput(mediaType: AVMediaType.audio, outputSettings: audioOutputSettings)
            self.audioInput!.expectsMediaDataInRealTime = true
            self.assetWriter?.add(self.audioInput!)
            
            // Create Pixel buffer Adaptor
            let sourceBufferAttributes:[String : Any] = [
                (kCVPixelBufferPixelFormatTypeKey as String): Int(kCVPixelFormatType_32ARGB),
                (kCVPixelBufferWidthKey as String): Float(size.width),
                (kCVPixelBufferHeightKey as String): Float(size.height)] as [String : Any]
            
            self.pixelBufferAdaptor = AVAssetWriterInputPixelBufferAdaptor(assetWriterInput: self.videoInput!, sourcePixelBufferAttributes: sourceBufferAttributes)
    
            self.assetWriter?.startWriting()
            self.assetWriter?.startSession(atSourceTime: CMTime.zero)
            completionHandler(nil)
        }
        catch {
            print("Failed to create assetWritter with error : \(error)")
            completionHandler(error)
        }
    }
    
    public func createPixelBufferFromUIImage(image: UIImage, completionHandler:@escaping(String?, CVPixelBuffer?) ->()){
        let attrs = [kCVPixelBufferCGImageCompatibilityKey: kCFBooleanTrue,
                     kCVPixelBufferCGBitmapContextCompatibilityKey: kCFBooleanTrue] as CFDictionary
        var pixelBuffer : CVPixelBuffer?
        let status = CVPixelBufferCreate(kCFAllocatorDefault, Int(image.size.width), Int(image.size.height), kCVPixelFormatType_32ARGB, attrs, &pixelBuffer)
        guard (status == kCVReturnSuccess) else {
            completionHandler("Failed to create pixel buffer", nil)
            return
        }
        
        CVPixelBufferLockBaseAddress(pixelBuffer!, CVPixelBufferLockFlags(rawValue: 0))
        let pixelData = CVPixelBufferGetBaseAddress(pixelBuffer!)
        
        let rgbColorSpace = CGColorSpaceCreateDeviceRGB()
        
        let context = CGContext(data: pixelData, width: Int(image.size.width), height: Int(image.size.height), bitsPerComponent: 8, bytesPerRow: CVPixelBufferGetBytesPerRow(pixelBuffer!), space: rgbColorSpace, bitmapInfo: CGImageAlphaInfo.noneSkipFirst.rawValue)
        
        context?.translateBy(x: 0, y: image.size.height)
        context?.scaleBy(x: 1.0, y: -1.0)
        
        UIGraphicsPushContext(context!)
        image.draw(in: CGRect(x: 0, y: 0, width: image.size.width, height: image.size.height))
        UIGraphicsPopContext()
        CVPixelBufferUnlockBaseAddress(pixelBuffer!, CVPixelBufferLockFlags(rawValue: 0))
        
        completionHandler(nil, pixelBuffer)
    }
    
    public func finishVideoRecording(completionHandler:@escaping(URL)->()) {
        DispatchQueue.main.async {
    
            self.videoInput!.markAsFinished()
            self.audioInput?.markAsFinished()
            self.assetWriter?.finishWriting(completionHandler: {
                print("output url : \(String(describing: self.assetWriter?.outputURL))");
                      completionHandler((self.assetWriter?.outputURL)!)
            })
        }
      
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
                
                self.videoInput = nil
                self.audioInput = nil
                self.pixelBufferAdaptor = nil
                self.assetWriter = nil
                
                FileManager.default.clearTmpDirectory();
            }
        })
    }
    
    //Photo
    public func saveImage(image:UIImage){
        // Save as UI Image
        UIImageWriteToSavedPhotosAlbum(image, self, nil, nil)
    }
        
    @objc func image(_ image: UIImage, didFinishSavingWithError error: Error?, contextInfo: UnsafeRawPointer) {
        
    }
    
    
    func startAudioRecording(completionHandler:@escaping(Bool) -> ()) {
        self.recordingSession = AVAudioSession.sharedInstance()
        do {
            try self.recordingSession.setCategory(AVAudioSession.Category.playAndRecord, mode: .videoRecording, options: [.defaultToSpeaker])
        
            try self.recordingSession.setActive(true, options: .notifyOthersOnDeactivation)
            
            print("REQUESTED SESSION")
            
            self.recordingSession!.requestRecordPermission() { [unowned self] allowed in
                DispatchQueue.main.async {
                    if allowed {
                        print("SESSION ALLOWED")
                        
                        let microphone = AVCaptureDevice.default(.builtInMicrophone, for: .audio, position: .unspecified)
                        
                        do {
                            try self.micInput = AVCaptureDeviceInput(device: microphone!)
                            
                            self.captureSession = AVCaptureSession()
                            
                            if (self.captureSession?.canAddInput(self.micInput!))! {
                                self.captureSession?.addInput(self.micInput!);
                                self.audioOutput = AVCaptureAudioDataOutput();
                                
                                if self.captureSession!.canAddOutput(self.audioOutput!){
                                    
                                    self.audioOutput?.setSampleBufferDelegate(self, queue: self.recordingQueue);
                                    self.captureSession!.addOutput(self.audioOutput!)
                                    
                                    self.captureSession?.startRunning()
                                    completionHandler(true);
                                }
                            }
                        }
                        catch {
                            completionHandler(false)
                        }
                        } else {
                            completionHandler(false)
                        }
                    }
                }
            } catch {
                completionHandler(false);
            }
        }
    
    
    
    
}

extension FileManager {
    func clearTmpDirectory() {
        do {
            let tmpDirURL = FileManager.default.temporaryDirectory
            let tmpDirectory = try contentsOfDirectory(atPath: tmpDirURL.path)
            try tmpDirectory.forEach { file in
                let fileUrl = tmpDirURL.appendingPathComponent(file)
                try removeItem(atPath: fileUrl.path)
            }
        } catch {
            //catch the error somehow
        }
    }
}

extension Camera: AVCaptureAudioDataOutputSampleBufferDelegate {
   
    //Capture Audio output
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        
        var count: CMItemCount = 0
        CMSampleBufferGetSampleTimingInfoArray(sampleBuffer, entryCount: 0, arrayToFill: nil, entriesNeededOut: &count);
        var info = [CMSampleTimingInfo](repeating: CMSampleTimingInfo(duration: CMTimeMake(value: 0, timescale: 0), presentationTimeStamp: CMTimeMake(value: 0, timescale: 0), decodeTimeStamp: CMTimeMake(value: 0, timescale: 0)), count: count)
        CMSampleBufferGetSampleTimingInfoArray(sampleBuffer, entryCount: count, arrayToFill: &info, entriesNeededOut: &count);
        
        let scale = CMTimeScale(NSEC_PER_SEC)
        var currentFrameTime:CMTime = CMTime(value: CMTimeValue(((self.sceneView?.session.currentFrame!.timestamp)!) * Double(scale)), timescale: scale);
        
        if self.videoStartTime == CMTime.zero {
            self.videoStartTime = currentFrameTime;
        }
        
        currentFrameTime = currentFrameTime-self.videoStartTime!;
        
        for i in 0..<count {
            info[i].decodeTimeStamp = currentFrameTime
            info[i].presentationTimeStamp = currentFrameTime
        }
        
        var soundbuffer:CMSampleBuffer?
        
        CMSampleBufferCreateCopyWithNewTiming(allocator: kCFAllocatorDefault, sampleBuffer: sampleBuffer, sampleTimingEntryCount: count, sampleTimingArray: &info, sampleBufferOut: &soundbuffer);
        
        if (self.audioInput?.isReadyForMoreMediaData)! {
            self.audioInput?.append(soundbuffer!);
        }
        else {
            print("Audio Data Failed");
        }
        
        
    }
}

