//
//  VirtualObjectARView.swift
//  AR_Camera
//
//  Created by Justin Lee on 2/27/20.
//  Copyright © 2020 com.lee. All rights reserved.
//

import Foundation
import ARKit

class VirtualObjectARView: ARSCNView {
    
    var camera : Camera?
    var consoleCheck: Int = 1

    
    // MARK: Position Testing
    
    /// Hit tests against the `sceneView` to find an object at the provided point.
    func object(at point: CGPoint) -> ReferenceNode? {
        let hitTestOptions: [SCNHitTestOption: Any] = [.boundingBoxOnly: true]
        let hitTestResults = hitTest(point, options: hitTestOptions)
        
        return hitTestResults.lazy.compactMap { result in
            return ReferenceNode.existingObjectContainingNode(result.node)
        }.first
    }
    
    // - MARK: Object anchors
    /// - Tag: AddOrUpdateAnchor
    func addOrUpdateAnchor(for referenceNode: ReferenceNode) {
        // If the anchor is not nil, remove it from the session.
        if let anchor = referenceNode.anchor {
            session.remove(anchor: anchor)
        }
        
        // Create a new anchor with the object's current transform and add it to the session
        let newAnchor = ARAnchor(transform: referenceNode.simdWorldTransform)
        referenceNode.anchor = newAnchor
        session.add(anchor: newAnchor)
    }
    
}



extension ARSCNView {
    /**
    Type conversion wrapper for original `unprojectPoint(_:)` method.
    Used in contexts where sticking to SIMD3<Float> type is helpful.
    */
    func unprojectPoint(_ point: SIMD3<Float>) -> SIMD3<Float> {
        return SIMD3<Float>(unprojectPoint(SCNVector3(point)))
    }
      
    // - Tag: CastRayForFocusSquarePosition
    func castRay(for query: ARRaycastQuery) -> [ARRaycastResult] {
        return session.raycast(query)
    }
    
    func getRaycastQuery(for alignment: ARRaycastQuery.TargetAlignment = .any) -> ARRaycastQuery? {
        return raycastQuery(from: screenCenter, allowing: .estimatedPlane, alignment: alignment)
    }
    
    var screenCenter: CGPoint {
        return CGPoint(x: bounds.midX, y: bounds.midY)
    }
}
