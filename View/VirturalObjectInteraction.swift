/*
See LICENSE folder for this sample’s licensing information.

Abstract:
Manages user interaction with virtual objects to enable one-finger tap, one- and two-finger pan,
 and two-finger rotation gesture recognizers to let the user position and orient virtual objects.
 
*/

import UIKit
import ARKit

/// - Tag: VirtualObjectInteraction
class VirtualObjectInteraction: NSObject, UIGestureRecognizerDelegate {
    
    /// Developer setting to translate assuming the detected plane extends infinitely.
    let translateAssumingInfinitePlane = true
    
    /// The scene view to hit test against when moving virtual content.
    let sceneView: VirtualObjectARView
    
    /// A reference to the view controller.
    weak var viewController: ViewController?
    
    ///The object that has been most recently intereacted with.
    var selectedObject: ReferenceNode?
    
    /// The object that is tracked for use by the pan and rotation gestures.
    var trackedObject: ReferenceNode? {
        didSet {
            guard trackedObject != nil else { return }
            selectedObject = trackedObject
        }
    }
    
    /// The tracked screen position used to update the `trackedObject`'s position.
    private var currentTrackingPosition: CGPoint?
    
    init(sceneView: VirtualObjectARView, viewController: ViewController) {
        self.sceneView = sceneView
        self.viewController = viewController
        super.init()
        
        createPanGestureRecognizer(sceneView)
        
        let tapGesture = UILongPressGestureRecognizer(target: self, action: #selector(didLongTap(_:)))
        tapGesture.cancelsTouchesInView = false
        sceneView.addGestureRecognizer(tapGesture)
        
        let pinchGesture = UIPinchGestureRecognizer(target: self, action: #selector(didPinch(_:)))
        sceneView.addGestureRecognizer(pinchGesture)
    }
    
    // - Tag: CreatePanGesture
    func createPanGestureRecognizer(_ sceneView: VirtualObjectARView) {
        let panGesture = ThresholdPanGesture(target: self, action: #selector(didPan(_:)))
        panGesture.delegate = self
       // panGesture.cancelsTouchesInView = false 
        sceneView.addGestureRecognizer(panGesture)
    }
    
    
    //MARK: - Gesture Actions
    
    @objc
    func didPan(_ gesture: ThresholdPanGesture){
        switch gesture.state {
        case .began:
            // Check for an object at the touch location.
            if let object = objectInteracting(with: gesture, in: sceneView) {
                trackedObject = object
            }
        case .changed where gesture.isThresholdExceeded:
            guard let object = trackedObject else { return }
            
            let tempEuler =  object.eulerAngles.x
           
            //Move an object if the displacement threshold has been met.
            translate(object, basedOn: updatedTrackingPosition(for: object, from: gesture))
        
            gesture.setTranslation(.zero, in: sceneView)
            
            if(object.isFlipped){
                object.eulerAngles.x = tempEuler
                let fig = object.position.y
                object.position.y = fig/2
            } else {
                object.eulerAngles.x = 0
                object.eulerAngles.y = 0
            }
            
        case .changed:
            //Ignore ban until the displacement threshold is exceeded
            break
        
        case .ended:
            //Update the objects position when the user stops panning.
            guard let object = trackedObject else { break }
            setDown(object, basedOn: updatedTrackingPosition(for: object, from: gesture))
            
            fallthrough
            
        default:
            // Reset the current position tracking.
            currentTrackingPosition = nil
            trackedObject = nil
        }
    }
    
    @objc
    func didLongTap(_ gesture: UILongPressGestureRecognizer){
        if viewController?.trashButton.isHidden == false || ((viewController?.cameraButton.isOkToShowObjMenu == false)) {
            return
        }
        
        viewController!.trashButton.isHidden = false
        if let object = objectInteracting(with: gesture, in: sceneView) {
            trackedObject = object
        }
        
        if trackedObject is FileBackground {
           
        
            viewController!.flipBackgroundButton.isHidden = false
        }
    }
    
    func objectEdited(){
        viewController!.trashButton.isHidden = true
        viewController!.flipBackgroundButton.isHidden = true
    }
    
    @objc
    func didPinch(_ gesture: UIPinchGestureRecognizer){
        let factor: CGFloat = 1.0
        
        switch gesture.state {
        case .began:
            // Check for an object at the touch location.
            if let object = objectInteracting(with: gesture, in: sceneView) {
                trackedObject = object
            }
            
        case .changed:
            
            if trackedObject == nil {
                trackedObject?.removeFromParentNode()
                return
            } else {
                let min = trackedObject!.boundingBox.min
                let max = trackedObject!.boundingBox.max
                _ = CGFloat(max.x - min.x)
                let h = CGFloat(max.y - min.y)
                let l = CGFloat(max.z - min.z)
                
                if gesture.scale > factor {
                    if h == 0 {
                        trackedObject?.scale.x += Float(gesture.scale * 0.02)
                        trackedObject?.scale.z += Float(gesture.scale * 0.02)
                    } else if l == 0{
                        trackedObject?.scale.x += Float(gesture.scale * 0.02)
                        trackedObject?.scale.y += Float(gesture.scale * 0.02)
                    } else {
                        trackedObject?.scale.x += Float(gesture.scale * 0.02)
                        trackedObject?.scale.y += Float(gesture.scale * 0.02)
                        trackedObject?.scale.z += Float(gesture.scale * 0.02)
                    }
                    gesture.scale = 1.0
                }
                
                if gesture.scale < factor {
                    if h == 0 {
                        trackedObject?.scale.x -= Float(gesture.scale * 0.02)
                        trackedObject?.scale.z -= Float(gesture.scale * 0.02)
                    } else if l == 0{
                        trackedObject?.scale.x -= Float(gesture.scale * 0.02)
                        trackedObject?.scale.y -= Float(gesture.scale * 0.02)
                    } else {
                        trackedObject?.scale.x -= Float(gesture.scale * 0.02)
                        trackedObject?.scale.y -= Float(gesture.scale * 0.02)
                        trackedObject?.scale.z -= Float(gesture.scale * 0.02)
                    }
                    gesture.scale = 1.0
                }
            }
        default:
            // Reset the current position tracking.
            currentTrackingPosition = nil
            trackedObject = nil
        }
        
    }
    
    func updatedTrackingPosition(for referenceNode: ReferenceNode, from gesture: UIPanGestureRecognizer) -> CGPoint {
        let translation = gesture.translation(in: sceneView)
        
        let currentPosition = currentTrackingPosition ?? CGPoint(sceneView.projectPoint(referenceNode.position))
        let updatedPosition = CGPoint(x: currentPosition.x + translation.x, y: currentPosition.y + translation.y)
        currentTrackingPosition = updatedPosition
        return updatedPosition
    }
    
    /** A helper method to return the first object that is found under the provided `gesture`s touch locations.
     Performs hit tests using the touch locations provided by gesture recognizers. By hit testing against the bounding
     boxes of the virtual objects, this function makes it more likely that a user touch will affect the object even if the
     touch location isn't on a point where the object has visible content. By performing multiple hit tests for multitouch
     gestures, the method makes it more likely that the user touch affects the intended object.
      - Tag: TouchTesting
    */
    private func objectInteracting(with gesture: UIGestureRecognizer, in view: ARSCNView) -> ReferenceNode? {

        for index in 0..<gesture.numberOfTouches {
            let touchLocation = gesture.location(ofTouch: index, in: view)
            
            //Look for an object directly under the 'touchLocation'
            if let objectReferenceNode = sceneView.object(at: touchLocation){
                return objectReferenceNode
            }
        }
    
        //As last resort, look for an object under the center of the touches
        if let center = gesture.center(in: view){
            return sceneView.object(at: center)
        }
        return nil
    }
    
    // MARK: - Update object position
    /// - Tag: DragVirtualObject
    func translate(_ referenceNode: ReferenceNode, basedOn screenPos: CGPoint){
        
        referenceNode.stopTrackedRaycast()
        
        // Update the object by using a one-time position request.
        if let query = sceneView.raycastQuery(from: screenPos, allowing: .estimatedPlane, alignment: .horizontal) {
            viewController!.createRaycastAndUpdate3DPosition(of: referenceNode, from: query)
        }
    }
    
    func setDown(_ referenceNode: ReferenceNode, basedOn screenPos: CGPoint){
        referenceNode.stopTrackedRaycast()
        
        //Prepare to update the object's anchor to the current location
        referenceNode.shouldUpdateAnchor = true
        
        // Attempt to create a new tracked raycast from the current location.
        if let query = sceneView.raycastQuery(from: screenPos, allowing: .estimatedPlane, alignment: .any), let raycast = viewController!.createTrackedRaycastAndSet3DPosition(of: referenceNode, from: query) {
            referenceNode.raycast = raycast
        } else {
            // If the tracked raycast did not succeed, simply update the anchor to the object's current position
            referenceNode.shouldUpdateAnchor = false
            viewController!.updateQueue.async {
                self.sceneView.addOrUpdateAnchor(for: referenceNode)
            }
        }
    }

}


/// Extends `UIGestureRecognizer` to provide the center point resulting from multiple touches.
extension UIGestureRecognizer {
    func center(in view: UIView) -> CGPoint? {
        guard numberOfTouches > 0 else { return nil }
        
        let first = CGRect(origin: location(ofTouch: 0, in: view), size: .zero)

        let touchBounds = (1..<numberOfTouches).reduce(first) { touchBounds, index in
            return touchBounds.union(CGRect(origin: location(ofTouch: index, in: view), size: .zero))
        }

        return CGPoint(x: touchBounds.midX, y: touchBounds.midY)
    }
}




