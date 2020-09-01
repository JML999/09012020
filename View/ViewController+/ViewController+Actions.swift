/*
See LICENSE folder for this sample’s licensing information.

Abstract:
UI Actions for the main view controller.


  Created by Justin Lee on 3/4/20.
  Copyright © 2020 com.lee. All rights reserved.
 
 */

import UIKit
import SceneKit

extension ViewController: UIGestureRecognizerDelegate {
    // MARK: - Interface Actions
    @IBAction func deleteSelectedObject(){
        if virtualObjectInteraction.selectedObject == nil {
            virtualObjectInteraction.objectEdited()
            return
        }
        
        let obj = virtualObjectInteraction.selectedObject
        if obj!.isBackground {
            obj?.stopTrackedRaycast()
            obj?.removeFromParentNode()
            obj?.unload()
            if let anchor = virtualObjectInteraction.selectedObject?.anchor {
                session.remove(anchor: anchor)
            }
            
            //Restore Object in Menu
            restoreObjectInMenuView(node: obj!)
                    
            virtualObjectInteraction.selectedObject = nil
            virtualObjectInteraction.objectEdited()
            return
        }
        
        //Else obj is FileNode
        let object = obj as! FileNode
        guard let objectIndex = objectLoader.loadedObjects.firstIndex(of: object) else {
            fatalError("Programmer error: Failed to lookup virtual object in scene.")
        }
        
        //Restore Object in Menu
        restoreObjectInMenuView(node: object)
        
        objectLoader.removeObject(at: objectIndex)
        virtualObjectInteraction.selectedObject = nil
        if let anchor = object.anchor {
            session.remove(anchor: anchor)
        }
        virtualObjectInteraction.objectEdited()
    }
    
    func restoreObjectInMenuView(node: ReferenceNode){
      
        if node.isBackground {
            let newArr = menuView.selectedObjects.filter { $0 != node.name }
            menuView.selectedObjects = newArr
            return
        }
        
        let object = node as! FileNode
        let newArr = menuView.selectedObjects.filter { $0 != object.modelName }
        menuView.selectedObjects = newArr
    }
    
    @IBAction func turnGreenScreenOn(){
        segmentWithDepth()
    }
    
    @IBAction func playButtonPressed(){
        self.isImageToPreview = false
        self.isVideoToPreview = false
        
        self.isPlayingStopMotion = false
        self.isCreatingStopMotion = false
        
        self.isPlayingStrip = true
        performSegue(withIdentifier: "showPreview", sender: self)
    
    }
    
    @IBAction func flipBackground(){
        checkFile()
        
        /*
        if virtualObjectInteraction.selectedObject == nil {
            return
        }
        let obj = virtualObjectInteraction.selectedObject
        let object = obj as! FileBackground
        object.toggleOrientation()
        */
    }
    
    @IBAction func resetScene(_ sender: Any){
        guard isRestartAvailable else { return }
        isRestartAvailable = false
        
        menuView.selectedObjects.removeAll()
        
        removeAllObjects()
        resetTracking()
        
        // Disable restart for a while in order to give the session time to restart.
        DispatchQueue.main.asyncAfter(deadline: .now() + 5.0) {
            self.isRestartAvailable = true
        }
    }
    
    
    func gestureRecognizerShouldBegin(_: UIGestureRecognizer) -> Bool {
        return true
    }
    
}

extension ViewController: UIPopoverPresentationControllerDelegate {
    func adaptivePresentationStyle(for controller: UIPresentationController) -> UIModalPresentationStyle {
        return .none
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?){
        
        //All menus should be popover.
        if let popoverController = segue.destination.popoverPresentationController, let button = sender as? UIButton {
            popoverController.delegate = self
            popoverController.sourceView = button
            popoverController.sourceRect = button.bounds
        }
        
        if let destination = segue.destination as? PreviewViewController{
            //Send User Info
            destination.globalUser = self.globalUser
            destination.globalID = self.globalID
            sceneView.preferredFramesPerSecond = 5
            destination.delegate = self
            destination.camera = sceneView.camera
            if self.isImageToPreview == true {
                destination.previewType = .image
                destination.img = self.img
                if isCreatingStopMotion == true {
                    destination.isCreatingStopMotion = true
                } else {
                    destination.isCreatingStopMotion = false
                }
            } else if self.isPlayingStopMotion == true {
                destination.gif = self.pImg
                destination.isCreatingStopMotion = false
                destination.isPlayingStopMotion = true
            } else if self.isVideoToPreview == true {
                destination.isCreatingStopMotion = false
                destination.isPlayingStopMotion = false 
                destination.previewType = .video
                destination.videoURL = urlToPreview
                print("vid", urlToPreview)
                destination.assetWriter = self.assetWriter
                destination.isCreatingStopMotion = false
            } else if self.isPlayingStrip{
                destination.isCreatingStopMotion = false
                destination.isPlayingStopMotion = false
                destination.isPlayingStrip = true
                destination.assetWriter = self.assetWriter
                destination.currentStrip = self.strip
            } else {
                print("ERROR IN SEGUE TO PREVIEW, ALL BOOL RETURN FALSE")
                return
            }
        }
        
    }
}
