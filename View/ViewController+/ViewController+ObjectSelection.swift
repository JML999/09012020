//
//  ViewController+ObjectSelction+BackgroundSelection.swift
//
//  Extends view controller to include delegates for selecting Virtual Objects and Backgrounds
//
//  Created by Justin Lee on 2/27/20.
//  Copyright © 2020 com.lee. All rights reserved.
//

import UIKit
import ARKit

extension ViewController: VirtualObjectSelectionViewControllerDelegate  {
    
    /** Adds the specified virtual object to the scene, placed at the world-space position
     estimated by a hit test from the center of the screen.
     - Tag: PlaceVirtualObject */
    func placeVirtualObject(_ virtualObject: FileNode) {
        guard focusSquare.state != .initializing, let query = virtualObject.raycastQuery else {
            self.statusViewController.showMessage("CANNOT PLACE OBJECT\nTry moving left or right.")
            if let controller = self.objectsViewController {
                self.virtualObjectSelectionViewController(controller, didDeselectObject: virtualObject)
            }
            return
        }
       
        let trackedRaycast = createTrackedRaycastAndSet3DPosition(of: virtualObject, from: query,
                                                                  withInitialResult: virtualObject.mostRecentInitialPlacementResult)
        
        virtualObject.raycast = trackedRaycast
        virtualObjectInteraction.selectedObject = virtualObject
        virtualObject.isHidden = false
    }
    
    
    func createTrackedRaycastAndSet3DPosition(of referenceNode: ReferenceNode, from query: ARRaycastQuery, withInitialResult initialResult: ARRaycastResult? = nil) -> ARTrackedRaycast? {
        
        if let initialResult = initialResult {
            self.setTransform(of: referenceNode, with: initialResult)
        }
        
        return session.trackedRaycast(query) { (results) in self.setVirtualObject3DPosition(results, with: referenceNode)
        }
    }
    

    // - Tag: GetTrackedRaycast
    func createRaycastAndUpdate3DPosition(of referenceNode: ReferenceNode, from query: ARRaycastQuery) {
        guard let result = session.raycast(query).first else {
            return
        }
        
        if self.virtualObjectInteraction.trackedObject == referenceNode {
            // If an object that's aligned to a surface is being dragged, then
            // smoothen its orientation to avoid visible jumps, and apply only the translation directly.
            referenceNode.simdWorldPosition = result.worldTransform.translation
            
            let previousOrientation = referenceNode.simdWorldTransform.orientation
            let currentOrientation = result.worldTransform.orientation
            
            if referenceNode is FileBackground {
                return
            }
            
            referenceNode.simdWorldOrientation = simd_slerp(previousOrientation, currentOrientation, 0.1)
        } else {
            self.setTransform(of: referenceNode, with: result)
        }
    }
    
    // - Tag: ProcessRaycastResults
    private func setVirtualObject3DPosition(_ results: [ARRaycastResult], with referenceNode: ReferenceNode) {
        
        guard let result = results.first else {
            fatalError("Unexpected case: the update handler is always supposed to return at least one result.")
        }
        
        self.setTransform(of: referenceNode, with: result)
        
        // If the virtual object is not yet in the scene, add it.
        if referenceNode.parent == nil {
            if self.isReturn { return }
            self.sceneView.scene.rootNode.addChildNode(referenceNode)
            referenceNode.shouldUpdateAnchor = true
        }
        
        if referenceNode.shouldUpdateAnchor {
            referenceNode.shouldUpdateAnchor = false
            self.updateQueue.async {
                self.sceneView.addOrUpdateAnchor(for: referenceNode)
            }
        }
    }
    
    func setTransform(of referenceNode: ReferenceNode, with result: ARRaycastResult) {
        let oldScale = referenceNode.scale
        referenceNode.simdWorldTransform = result.worldTransform
        referenceNode.scale = oldScale
    }
    
    
    // MARK: - VirtualObjectSelectionViewControllerDelegate
     // - Tag: PlaceVirtualContent
    func virtualObjectSelectionViewController(_: VirtualObjectSelectionViewController, didSelectObject object: FileNode) {
        objectLoader.loadObject(object, loadedHandler: { [unowned self] loadedObject in
            do {
                let scene = try SCNScene(url: object.referenceURL, options: nil)
                self.sceneView.prepare([scene], completionHandler: { _ in
                    DispatchQueue.main.async {
                        self.hideObjectLoadingUI()
                        self.placeVirtualObject(loadedObject)
                    }
                })
            } catch {
                fatalError("Failed to load SCNScene from object.referenceURL")
            }
            
        })
        displayObjectLoadingUI()
    }
    
    func virtualObjectSelectionViewController(_: VirtualObjectSelectionViewController, didDeselectObject object: FileNode) {
        guard let objectIndex = objectLoader.loadedObjects.firstIndex(of: object) else {
            fatalError("Programmer error: Failed to lookup virtual object in scene.")
        }
        objectLoader.removeObject(at: objectIndex)
        virtualObjectInteraction.selectedObject = nil
        if let anchor = object.anchor {
            session.remove(anchor: anchor)
        }
    }

    // MARK: Object Loading UI

    func displayObjectLoadingUI() {
        // Show progress indicator.
  //      spinner.startAnimating()
        
  //      addObjectButton.setImage(#imageLiteral(resourceName: "buttonring"), for: [])

   //     isRestartAvailable = false
    }

    func hideObjectLoadingUI() {
        // Hide progress indicator.
  //      spinner.stopAnimating()

 //       addObjectButton.setImage(#imageLiteral(resourceName: "add"), for: [])
 //       addObjectButton.setImage(#imageLiteral(resourceName: "addPressed"), for: [.highlighted])

//        isRestartAvailable = true
    }
    
}

extension ViewController: MenuToMainDelegate{
    func messageToMain(string: String) {
        statusViewController.showMessage(string)
    }
    
    func objectToMain(_ selectionViewController: MenuView, didSelectObject object: FileNode) {
        if let query = sceneView.getRaycastQuery(for: object.allowedAlignment),
            let result = sceneView.castRay(for: query).first {
            object.mostRecentInitialPlacementResult = result
            object.raycastQuery = query
            
        } else {
            object.mostRecentInitialPlacementResult = nil
            object.raycastQuery = nil
        }
        
        objectLoader.loadObject(object, loadedHandler: { [unowned self] loadedObject in
            do {
                let scene = try SCNScene(url: object.referenceURL, options: nil)
                self.sceneView.prepare([scene], completionHandler: { _ in
                    DispatchQueue.main.async {
                        self.hideObjectLoadingUI()
                        self.placeVirtualObject(loadedObject)
                    }
                })
            } catch {
                fatalError("Failed to load SCNScene from object.referenceURL")
            }
            
        })
    }
    
    func backgroundToMain(didSelectObject: FileBackground) {
        let background: FileBackground = didSelectObject
        let currentCast = self.currentRayCast
        
        if (currentCast == nil){
            let transform = focusSquare.transform
            background.transform = transform
            sceneView.scene.rootNode.addChildNode(background)
            return
        }
        
        setTransform(of: background, with: currentCast!)
        sceneView.scene.rootNode.addChildNode(background)
    }
    
    
}
