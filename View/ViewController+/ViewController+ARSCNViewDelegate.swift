
import  ARKit


extension ViewController: ARSCNViewDelegate, ARSessionDelegate {
    
    //MARK: - ARSCNViewDelegate
    func renderer(_ renderer: SCNSceneRenderer, updateAtTime time: TimeInterval) {
        
        DispatchQueue.main.async {
           self.updateFocusSquare()
        }
        
        if cam!.isRecording {
            if cam?.lastTime == 0 || (cam!.lastTime + 1/25) < time {
                var currentFrameTime: CMTime = CMTime(value: CMTimeValue((sceneView.session.currentFrame!.timestamp) * Double(cam!.scale)),timescale: cam!.scale)
                if cam!.lastTime == 0 {
                    cam!.videoStartTime = currentFrameTime
                }
                
                print("Update @:  \(time)")
                cam!.lastTime = time
                
                //Video
                let snapshot:UIImage = self.sceneView.snapshot()
                cam!.createPixelBufferFromUIImage(image: snapshot, completionHandler: { (error, pixelBuffer) in
                    guard error == nil else {
                        print("Failed to get pixel buffer")
                        return
                    }
                    
                    currentFrameTime = currentFrameTime - self.cam!.videoStartTime!
                    
                    if (self.cam!.videoInput?.isReadyForMoreMediaData)!{
                        //Add pixel buffer to video input
                        self.cam!.pixelBufferAdaptor!.append(pixelBuffer!, withPresentationTime: currentFrameTime)
                        return
                    } else {
                        print("Failed to pass data")
                    }
                })
            }
        }
        
       self.sceneView.scene.update()
    }
    
    
    /// - Tag: ShowVirtualContent
    /*
    func session(_ session: ARSession, cameraDidChangeTrackingState camera: ARCamera) {
        showVirtualContent()
    }
    
    func showVirtualContent() {
        objectLoader.loadedObjects.forEach { $0.isHidden = false }
    }
    */
    
}

