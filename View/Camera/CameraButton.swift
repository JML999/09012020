//
//  CameraButton.swift
//  AR_Camera
//
//  Created by Justin Lee on 3/26/20.
//  Copyright © 2020 com.lee. All rights reserved.
//

import UIKit
import ARKit
import Photos
import ReplayKit

protocol SnapToViewDelegate: class {
    func sendImageToPreview()
}

class CameraButton: UIButton {
    
    weak var delegate: SnapToViewDelegate? = nil
    
    public weak var sceneView: VirtualObjectARView!
    
    public let whiteCircle: UIView = UIView()
    
    private var whiteCircleSize: CGFloat {
        return cameraButtonDimension*(9/10)
    }
    
    private let videoCameraProgressArc: CAShapeLayer = CAShapeLayer()
    private var videoCameraProgressArcMargin: CGFloat {
        return cameraButtonDimension/80
    }
    
    private let circleGrowthTimeInterval: TimeInterval = 0.15
    private var touchEnded: Bool = false
    private var videoStarted:Bool = false
    private var videoSaved: Bool = false
    
    var cameraSize: CGSize?
    var timer: Timer?
    var isOkToShowObjMenu: Bool = true
    var isAnimating: Bool = false
    
    var stopArr: [UIImage] = []
    
    init(size: CGSize, sceneView: VirtualObjectARView) {
        super.init(frame: CGRect(x: (screenWidth - cameraButtonDimension)/2, y: (screenHeight*0.9 - cameraButtonDimension), width: cameraButtonDimension, height: cameraButtonDimension))
        
        self.cameraSize = size
        self.sceneView = sceneView
        
        self.backgroundColor = UIColor.white.withAlphaComponent(0.6)
        self.layer.cornerRadius = cameraButtonDimension/2
        
        //Camera Ciricle
        self.whiteCircle.backgroundColor = UIColor.white
        self.whiteCircle.layer.cornerRadius = whiteCircleSize/2
        self.whiteCircle.frame = CGRect(x:(self.frame.width-whiteCircleSize)/2, y: (self.frame.width-whiteCircleSize)/2, width: whiteCircleSize, height: whiteCircleSize);
        self.addSubview(self.whiteCircle)
        
        //Create the video camera progress arc
        self.videoCameraProgressArc.opacity = 0
        self.videoCameraProgressArc.path = UIBezierPath(ovalIn: CGRect(x: self.videoCameraProgressArcMargin, y: self.videoCameraProgressArcMargin, width: self.frame.width - self.videoCameraProgressArcMargin*2, height: self.frame.width - self.videoCameraProgressArcMargin*2)).cgPath
        self.videoCameraProgressArc.lineWidth = 5.0
        self.videoCameraProgressArc.strokeStart = 0
        self.videoCameraProgressArc.strokeEnd = 0
        self.videoCameraProgressArc.strokeColor = UIColor.black.cgColor
        self.videoCameraProgressArc.fillColor = UIColor.clear.cgColor
        
        //Rotate 90 degrees anti-clockwise
        self.videoCameraProgressArc.transform = CATransform3DMakeRotation(CGFloat(-Double.pi/2), 0, 0, 1)
        self.videoCameraProgressArc.position = CGPoint(x: 0, y: self.frame.height)
        
        self.layer.addSublayer(self.videoCameraProgressArc)
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame);
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        self.touchEnded = false
        self.isOkToShowObjMenu = false
        self.videoSaved = false
    
        
        UIView.animate(withDuration: circleGrowthTimeInterval, delay: 0.10, options: .curveEaseIn, animations: {
            self.frame = CGRect(x: (screenWidth - cameraButtonDimension * 1.5) / 2,
                                y: (screenHeight * 0.9 - cameraButtonDimension * 1.25),
                                width: cameraButtonDimension * 1.5,
                                height: cameraButtonDimension * 1.5)
            
            self.layer.cornerRadius = cameraButtonDimension * 1.5 / 2
            
            self.whiteCircle.frame = CGRect(x: (self.frame.width-self.whiteCircleSize)/2,
                                            y: (self.frame.width - self.whiteCircleSize)/2,
                                            width: self.whiteCircleSize,
                                            height:  self.whiteCircleSize)
            
            self.videoCameraProgressArc.path = UIBezierPath(ovalIn: CGRect(x:self.videoCameraProgressArcMargin,
                                                                           y: self.videoCameraProgressArcMargin,
                                                                           width: self.frame.width - self.videoCameraProgressArcMargin*2,
                                                                           height: self.frame.width - self.videoCameraProgressArcMargin*2)).cgPath;
            
            self.videoCameraProgressArc.transform = CATransform3DMakeRotation(CGFloat(-Double.pi/2), 0,0,1);
            self.videoCameraProgressArc.position = CGPoint(x: 0, y: self.frame.height);
    
        }) { (finished) in
            print("Finished Inward Animation")
            //Begin Video Capture
            if (self.touchEnded == false){
                self.timer = Timer.scheduledTimer(withTimeInterval: 0.25, repeats: false, block: { [weak self] _ in
                   if (self?.touchEnded == false ) {
                        self!.videoStarted = true
                        self!.animateVideoRing()
                        self!.sceneView.camera?.startRecording(size: self!.cameraSize!)
                    } else {
                        self!.videoCameraProgressArc.removeAllAnimations()
                        self!.videoCameraProgressArc.opacity = 0
                        self?.videoStarted = false
                        self?.videoSaved = false 
                    }
                })
            }
        }
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        self.touchEnded = true
        self.isOkToShowObjMenu = true 

        print("State", RPScreenRecorder.shared().isRecording)
        print("VIDEO STARTED ", self.videoStarted )
        
        if (self.videoStarted == false){
            if self.videoSaved == false {
                print("Image")
                                
                delegate?.sendImageToPreview()

                UIView.animate(withDuration: circleGrowthTimeInterval, animations: {
                    
                    self.frame = CGRect(x: (screenWidth - cameraButtonDimension)/2,
                                        y: (screenHeight*0.9-cameraButtonDimension),
                                        width: cameraButtonDimension,
                                        height: cameraButtonDimension);
                    self.layer.cornerRadius = cameraButtonDimension/2;
                    
                    self.whiteCircle.frame = CGRect(x: (self.frame.width-self.whiteCircleSize)/2,
                                                    y: (self.frame.width-self.whiteCircleSize)/2,
                                                    width: self.whiteCircleSize,
                                                    height: self.whiteCircleSize);
                })
                return
            } else {
                print("Video Already Saved")
            }
        } else {
            self.videoStarted = true
            //Recorder is not recording, stop recording
            print("Video")
            self.videoCameraProgressArc.removeAllAnimations()
            self.videoCameraProgressArc.opacity = 0
            
        }
        
        UIView.animate(withDuration: circleGrowthTimeInterval, animations: {
            
            self.frame = CGRect(x: (screenWidth - cameraButtonDimension)/2,
                                y: (screenHeight*0.9-cameraButtonDimension),
                                width: cameraButtonDimension,
                                height: cameraButtonDimension);
            self.layer.cornerRadius = cameraButtonDimension/2;
            
            self.whiteCircle.frame = CGRect(x: (self.frame.width-self.whiteCircleSize)/2,
                                            y: (self.frame.width-self.whiteCircleSize)/2,
                                            width: self.whiteCircleSize,
                                            height: self.whiteCircleSize);
            
        })
       
    }
    
    // MARK :  ANIMATION FUNCTIONALITY
    func animateVideoRing(){
        // Set the Initial Stroke State
        self.videoCameraProgressArc.strokeStart = 0
        self.videoCameraProgressArc.strokeEnd = 0
        self.videoCameraProgressArc.opacity = 1;
        self.isAnimating = true
        
        CATransaction.begin();
        CATransaction.setAnimationDuration(10);
        CATransaction.setDisableActions(true);
        CATransaction.setCompletionBlock {
            self.videoRingAnimationDidFinish();
        }
        
        // Set animation end state
        let start = CABasicAnimation(keyPath: "strokeStart")
        start.toValue = 0
        let end = CABasicAnimation(keyPath: "strokeEnd")
        end.toValue = 1
        
        // Play Animation Repetitively
        let group = CAAnimationGroup()
        group.animations = [start, end];
        group.duration = 10
        group.autoreverses = false;
        group.repeatCount = 0 // repeat 0 times
        group.isRemovedOnCompletion = true;
        
        self.videoCameraProgressArc.add(group, forKey: nil)
        
        CATransaction.commit();
        
    }
    
    func videoRingAnimationDidFinish(){

        print("STOP VIDEO, ANIMATION COMPLETE");
        
        // Stop the button animation and hide the arc
        self.videoCameraProgressArc.removeAllAnimations();
        self.videoCameraProgressArc.opacity = 0;
        self.videoSaved = true;
        self.videoStarted = false
        self.sceneView.camera?.endRecording();
    }
    
}
