import UIKit
import ARKit

class ObjectCell: UITableViewCell {
    static let reuseIdentifier = "ObjectCell"
    
    @IBOutlet weak var objectTitle: UILabel!
    @IBOutlet weak var vibrancyFx: UIVisualEffectView!
    
    var modelName = "" {
        didSet {
            objectTitle.text = modelName.capitalized
        }
    }
}


// MARK: - VirtualObjectSelectionViewControllerDelegate

/// A protocol for reporting which objects have been selected.
protocol VirtualObjectSelectionViewControllerDelegate: class {
    func virtualObjectSelectionViewController(_ selectionViewController: VirtualObjectSelectionViewController, didSelectObject: FileNode)
    func virtualObjectSelectionViewController(_ selectionViewController: VirtualObjectSelectionViewController, didDeselectObject: FileNode)
}

/// A custom table view controller to allow users to select `VirtualObject`s for placement in the scene.
class VirtualObjectSelectionViewController: UITableViewController {
    
    ///The collection of Objects to select from
    var objects = [FileNode]()
    
    /// The rows of the currently selected `VirtualObject`s.
    var selectedVirtualObjectRows = IndexSet()
    
    /// The rows of the 'VirtualObject's that are currently allowed to be placed.
    var enabledVirtualObjectRows = Set<Int>()
    
    weak var delegate: VirtualObjectSelectionViewControllerDelegate?
    
    weak var sceneView: ARSCNView?

    private var lastObjectAvailabilityUpdateTimestamp: TimeInterval?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.separatorEffect = UIVibrancyEffect(blurEffect: UIBlurEffect(style: .light))
    }
    
    override func viewWillLayoutSubviews() {
        preferredContentSize = CGSize(width: 250, height: tableView.contentSize.height)
    }
    
    
    func updateObjectAvailability(){
        guard let sceneView = sceneView else { return }
        
        //Update object availability only if last update update was at least half a second ago.
        if let lastUpdateTimeStamp = lastObjectAvailabilityUpdateTimestamp, let timestamp = sceneView.session.currentFrame?.timestamp,
            timestamp - lastUpdateTimeStamp < 0.5 {
            return
        } else {
            lastObjectAvailabilityUpdateTimestamp = sceneView.session.currentFrame?.timestamp
        }
        
        var newEnabledObjectRows = Set<Int>()
        for (row, object) in objects.enumerated(){
            //Enable row always if item has already been placed, in order to allow the user to remove it.
            if selectedVirtualObjectRows.contains(row){
                newEnabledObjectRows.insert(row)
            }
            
            //Enable row if item can be placed at current location
            if let query = sceneView.getRaycastQuery(for: object.allowedAlignment),
                let result = sceneView.castRay(for: query).first {
                object.mostRecentInitialPlacementResult = result
                object.raycastQuery = query
                newEnabledObjectRows.insert(row)
            } else {
                object.mostRecentInitialPlacementResult = nil
                object.raycastQuery = nil
            }
        }
        
        //Only reload changed rows
        let changedRows = newEnabledObjectRows.symmetricDifference(enabledVirtualObjectRows)
        enabledVirtualObjectRows = newEnabledObjectRows
        let indexPaths = changedRows.map { row in IndexPath(row: row, section: 0) }
        
        DispatchQueue.main.async {
            self.tableView.reloadRows(at: indexPaths, with: .automatic)
        }
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let cellIsEnabled = enabledVirtualObjectRows.contains(indexPath.row)
        guard cellIsEnabled else { return }
        
        let object = objects[indexPath.row]
        
        // Check if the current row is already selected, then deselect it.
        if selectedVirtualObjectRows.contains(indexPath.row) {
            delegate?.virtualObjectSelectionViewController(self, didDeselectObject: object)
        } else {
            delegate?.virtualObjectSelectionViewController(self, didSelectObject: object)
        }

        dismiss(animated: true, completion: nil)
    }
    
    // MARK: - UITableViewDelegate
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return objects.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: ObjectCell.reuseIdentifier, for: indexPath) as? ObjectCell else {
            fatalError("Expected `\(ObjectCell.self)` type for reuseIdentifier \(ObjectCell.reuseIdentifier). Check the configuration in Main.storyboard.")
        }
        
        cell.modelName = objects[indexPath.row].modelName

        if selectedVirtualObjectRows.contains(indexPath.row) {
            cell.accessoryType = .checkmark
        } else {
            cell.accessoryType = .none
        }
        
        let cellIsEnabled = enabledVirtualObjectRows.contains(indexPath.row)
        if cellIsEnabled {
            cell.vibrancyFx.alpha = 1.0
        } else {
            cell.vibrancyFx.alpha = 0.1
        }

        return cell
    }
    
    override func tableView(_ tableView: UITableView, didHighlightRowAt indexPath: IndexPath) {
        let cellIsEnabled = enabledVirtualObjectRows.contains(indexPath.row)
        guard cellIsEnabled else { return }

        let cell = tableView.cellForRow(at: indexPath)
        cell?.backgroundColor = UIColor.lightGray.withAlphaComponent(0.5)
    }
    
    override func tableView(_ tableView: UITableView, didUnhighlightRowAt indexPath: IndexPath) {
        let cellIsEnabled = enabledVirtualObjectRows.contains(indexPath.row)
        guard cellIsEnabled else { return }

        let cell = tableView.cellForRow(at: indexPath)
        cell?.backgroundColor = .clear
    }
}
