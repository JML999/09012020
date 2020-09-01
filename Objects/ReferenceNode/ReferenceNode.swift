import SceneKit
import ARKit

class ReferenceNode : SCNReferenceNode {
    
    var isBackground: Bool = false
    
    var modelName: String {
        
        if isBackground {
            return self.name!
        }
        return "object"
    }
    
    /// The alignments that are allowed for a virtual object.
    var allowedAlignment: ARRaycastQuery.TargetAlignment {
        if modelName == "sticky note" {
            return .any
        } else if modelName == "painting" {
            return .vertical
        } else {
            return .horizontal
        }
    }
    
    /// Marks if the object has been flipped about x axis
    var isFlipped = false
    
    /// The object's corresponding ARAnchor.
    var anchor: ARAnchor?

    /// The raycast query used when placing this object.
    var raycastQuery: ARRaycastQuery?
    
    /// The associated tracked raycast used to place this object.
    var raycast: ARTrackedRaycast?
    
    /// The most recent raycast result used for determining the initial location
    /// of the object after placement.
    var mostRecentInitialPlacementResult: ARRaycastResult?
    
    /// Flag that indicates the associated anchor should be updated
    /// at the end of a pan gesture or when the object is repositioned.
    var shouldUpdateAnchor = false
    
    /// Rotates the first child node of a virtual object.
    /// - Note: For correct rotation on horizontal and vertical surfaces, rotate around
    /// local y rather than world y.
    var objectRotation: Float {
        get {
            return childNodes.first!.eulerAngles.y
        }
        set (newValue){
            childNodes.first!.eulerAngles.y = newValue
        }
    }
    
    /// Stops tracking the object's position and orientation.
    /// - Tag: StopTrackedRaycasts
    func stopTrackedRaycast() {
        raycast?.stopTracking()
        raycast = nil
    }
    
    override func update(){}
}

extension ReferenceNode {
        
    /// Returns a `ReferenceNode` if one exists as an ancestor to the provided node.
    static func existingObjectContainingNode(_ node: SCNNode) -> ReferenceNode? {
        if let virtualObjectRoot = node as? ReferenceNode {
            return virtualObjectRoot
        }
        
        guard let parent = node.parent else { return nil }
        
        // Recurse up to check if the parent is a `VirtualObject`.
        return existingObjectContainingNode(parent)
    }
}
