/*
See LICENSE folder for this sample’s licensing information.

Abstract:
A type which loads and tracks virtual objects.
*/

import Foundation
import ARKit

/**
 Loads multiple `VirtualObject`s on a background queue to be able to display the
 objects quickly once they are needed.
*/
class ObjectLoader {
    var loadedObjects = [FileNode]()
    private(set) var isLoading = false
    
    // MARK: - Loading object
    
    /**
     Loads a `FileNode` on a background queue. `loadedHandler` is invoked
     on a background queue once `object` has been loaded.
    */
    func loadObject(_ fileNode: FileNode, loadedHandler: @escaping (FileNode) -> Void){
        isLoading = true
        loadedObjects.append(fileNode)
        
        //Load the content into the reference node.
        DispatchQueue.global(qos: .userInitiated).async {
            fileNode.load()
            self.isLoading = false
            loadedHandler(fileNode)
        }
    }
    
    /// - Tag: RemoveObject
    func removeObject(at index: Int) {
        guard loadedObjects.indices.contains(index) else { return }
        
        // Stop the object's tracked ray cast.
        loadedObjects[index].stopTrackedRaycast()
        
        // Remove the visual node from the scene graph.
        loadedObjects[index].removeFromParentNode()
        // Recoup resources allocated by the object.
        loadedObjects[index].unload()
        loadedObjects.remove(at: index)
    }
    
}
