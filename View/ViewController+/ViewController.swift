//
//  ViewController.swift
//  AR_Camera
//
//  Created by Justin Lee on 2/11/20.
//  Copyright © 2020 com.lee. All rights reserved.
//
import Foundation
import SceneKit
import ARKit
import UIKit
import Photos
import AVKit
import AVFoundation

class ViewController: UIViewController{
    
    var strip : [Cel] = []
    
    //Variables for Camera Delegates to Send Data to Preview
    var img : UIImage = UIImage()
    var pImg: [UIImage] = []
    var urlToPreview : URL = URL(fileURLWithPath: "")
    var isVideoToPreview = false
    var isImageToPreview = false
    var isCreatingStopMotion = false
    var isPlayingStopMotion = false
    var isPlayingStrip = false
    var greenKeepOn = false
    
    //Tell components view is returning so async tasks dont run
    var isReturn = false
    
    //Toggles for UI
    var hasBuilt = false
    var isBuilding = false
    var assetWriter: AVAssetWriter?
    
    /// The view controller that displays the virtual object selection menu.
    weak var objectsViewController: VirtualObjectSelectionViewController?
    
    /// Variables passed from StartView that contain created backgrounds and String to object loader
    var globalID = ""
    var globalUser = ""
    var backgrounds: [FileBackground] = []
    var objects: [FileNode] = []
    var objectsToLoad: String = ""
    weak var delegateToMenu : ReturnToMenuDelegate? = nil
    
    // MARK: - UI Elements
    @IBOutlet weak var sceneView: VirtualObjectARView!
    @IBOutlet weak var menuView: MenuView!
    @IBOutlet weak var upperControlsView: UIView!
    @IBOutlet weak var trashButton: UIButton!
    @IBOutlet weak var createButton: UIButton!
    @IBOutlet weak var resetButton: UIButton!
    @IBOutlet weak var backButton: UIButton!
    @IBOutlet weak var stopMotionButton: UIButton!
    @IBOutlet weak var greenScreenButton: UIButton!
    @IBOutlet weak var flipBackgroundButton: UIButton!
    @IBOutlet weak var playStripButton: UIButton!
    
    var focusSquare = FocusSquare()
    var cameraButton: CameraButton!
    var timer: Timer?
    
    weak var cam : Camera?
    
    // MARK: - ARKit Configuration Properties
    var currentFrameRate = 30

    /// A type which manages gesture manipulation of virtual content in the scene.
    lazy var virtualObjectInteraction = VirtualObjectInteraction(sceneView: sceneView, viewController: self)
    
    /// The view controller that displays the status and "restart experience" UI.
    lazy var statusViewController: StatusViewController = {
        return children.lazy.compactMap({ $0 as? StatusViewController }).first!
    }()
    
    let objectLoader = ObjectLoader()
    var currentRayCast : ARRaycastResult?

    /// A serial queue used to coordinate adding or removing nodes from the scene.
    let updateQueue = DispatchQueue(label: "com.example.apple-samplecode.arkitexample.serialSceneKitQueue")
    
    /// Convenience accessor for the session owned by ARSCNView.
    var session: ARSession {
        return sceneView.session
    }
    
    /// Marks if the AR experience is available for restart.
    var isRestartAvailable = true
    var fileNode = FileNode()

    
    deinit {
        print("No retain cycle")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //Creates variables for camera
        screenWidth = self.view.frame.width
        screenHeight = self.view.frame.height
        instantiateVariables()

        // Set the view's delegate
        sceneView.delegate = self
        sceneView.session.delegate = self
        sceneView.preferredFramesPerSecond = currentFrameRate

        getAudioAuth()
       
        sceneView.camera = Camera(size: self.view.bounds.size)
        sceneView.camera?.sceneView = self.sceneView
        sceneView.camera?.delegate = self
        cam = sceneView.camera!
        
        addLightNode()
    
        sceneView.scene.rootNode.addChildNode(focusSquare)
        
        initMenu()
        
        initNotificationView()
        
        let size: CGSize = view.bounds.size
        cameraButton = CameraButton(size: size, sceneView: sceneView)
        cameraButton.delegate = self
        self.sceneView.addSubview(cameraButton)
        
        initUIButtons()
        
        //checkFile()
        listFiles()
        
    }
    
    func listFiles(){
        // Get the document directory url
        let documentsUrl =  FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!

        do {
            // Get the directory contents urls (including subfolders urls)
            let directoryContents = try FileManager.default.contentsOfDirectory(at: documentsUrl, includingPropertiesForKeys: nil)
            print(directoryContents)
            
            // if you want to filter the directory contents you can do like this:
            let pngFiles = directoryContents.filter{ $0.pathExtension == "png" }
            print("png urls:", pngFiles)
            let pngfilesNames = pngFiles.map{ $0.deletingPathExtension().lastPathComponent }
            print("png list:", pngfilesNames)
        } catch {
            print(error)
        }
    }
    
    
    func checkFile(){
        let path = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0] as String
         let url = NSURL(fileURLWithPath: path)
         if let pathComponent = url.appendingPathComponent("C480DC7B-225D-49EA-8522-F9953629DAD0.png") {
             let filePath = pathComponent.path
             let fileManager = FileManager.default
             if fileManager.fileExists(atPath: filePath) {
                 print("FILE AVAILABLE")
                
                if let image = getSavedImage(named: "C480DC7B-225D-49EA-8522-F9953629DAD0.png") {
                    self.img = image
                    sendImageToPreview()
                } else {
                    print("Error")
                }
                
                /*
                try! fileManager.removeItem(atPath: filePath)
                checkFile()
                */
             } else {
                 print("FILE NOT AVAILABLE")
             }
         } else {
             print("FILE PATH NOT AVAILABLE")
         }
        
    }
    
    func getSavedImage(named: String) -> UIImage? {
        if let dir = try? FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: false) {
            return UIImage(contentsOfFile: URL(fileURLWithPath: dir.absoluteString).appendingPathComponent(named).path)
        }
        return nil
    }
    
    func getAudioAuth(){
        AVAudioSession.sharedInstance().requestRecordPermission () {
            [unowned self] allowed in
            if allowed {
                return
            } else {
                //Print message audio not allowed
            }
        }
    }
    
    func initMenu(){
        let layout = self.menuView.collectionView.collectionViewLayout as! UICollectionViewFlowLayout
        layout.sectionInset = UIEdgeInsets(top: 0,left: 10,bottom: 0,right: 0)
        layout.minimumInteritemSpacing = 0
        //If you want more than 2 per row, divide by 2++
        layout.itemSize = CGSize(width:(menuView.collectionView.frame.size.width - 20)/2, height: menuView.collectionView.frame.size.height/3)
        
        menuView.delgate = self
        let menuStartingTransform = menuView.transform
        let menuTransformed = menuStartingTransform.translatedBy(x: 0.0, y: 200.0)
        menuView.transform = menuTransformed
        menuView.isHidden = true
        self.view.sendSubviewToBack(menuView)
        menuView.backgrounds = self.backgrounds
        menuView.objects = self.objects
        menuView.collectionView.delegate = menuView
        menuView.collectionView.dataSource = menuView
    }
    
    
    
    func initNotificationView(){
        // Hook up status view controller callback(s)
        self.view.sendSubviewToBack(upperControlsView)        
        statusViewController.restartExperienceHandler = { [unowned self] in
            self.resetTracking()
        }

    }
    
    func initUIButtons(){
        focusSquare.hide()
        trashButton.isHidden = true
        playStripButton.isHidden = true
        greenScreenButton.isHidden = false
        flipBackgroundButton.isHidden = false
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        resetTracking()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
    }
    
    override var prefersHomeIndicatorAutoHidden: Bool {
        return true
    }
    
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
    
    }
    
    
    func resetTracking(){
        virtualObjectInteraction.selectedObject = nil
        let configuration = ARWorldTrackingConfiguration()
        configuration.isAutoFocusEnabled = true
        configuration.environmentTexturing = .automatic
        configuration.planeDetection = [.vertical, .horizontal]
        session.run(configuration, options: [.resetTracking, .removeExistingAnchors])
        
        self.view.bringSubviewToFront(self.upperControlsView)
        self.statusViewController.scheduleMessage("TAP THE WRENCH TO BEGIN BUILDING!", inSeconds: 0.5, messageType: .planeEstimation)
    }
    
    func updateFocusSquare(){
        // Perform ray casting only when ARkit tracking is in a good state.
        if isReturn == true {return}
        if let camera = session.currentFrame?.camera, case .normal = camera.trackingState,
            let query = sceneView.getRaycastQuery(),
            let result = sceneView.castRay(for: query).first {
            updateQueue.async {
                self.currentRayCast = result
                self.sceneView.scene.rootNode.addChildNode(self.focusSquare)
                self.focusSquare.state = .detecting(raycastResult: result, camera: camera)
            }
        } else {
            self.focusSquare.state = .initializing
            self.sceneView.pointOfView?.addChildNode(self.focusSquare)
        }
    }
    
    func addLightNode() {
        
        // Create ambient light
        let ambientLightNode = SCNNode()
        ambientLightNode.light = SCNLight()
        ambientLightNode.light!.type = .ambient
        ambientLightNode.light!.color = UIColor(white: 0.70, alpha: 1.0)
    
        // Create directional light
        let directionalLight = SCNNode()
        directionalLight.light = SCNLight()
        directionalLight.light!.type = .directional
        directionalLight.light!.color = UIColor(white: 1.0, alpha: 1.0)
        directionalLight.position = SCNVector3(x: 0, y: 0.0, z: 0.0)
        directionalLight.eulerAngles = SCNVector3(x: 0.0, y: 0, z: 0)

        // Add directional light to camera
        let cameraNode = sceneView.pointOfView!
        sceneView.scene.rootNode.addChildNode(ambientLightNode)
        cameraNode.addChildNode(directionalLight)
    }
    
    func hideCameraUI(){
        stopMotionButton.isHidden = true
        playStripButton.isHidden = true
        backButton.isHidden = true
        greenScreenButton.isHidden = true
        cameraButton.isHidden = true
        view.sendSubviewToBack(cameraButton)
    }
    
    func showCameraUI(){
        stopMotionButton.isHidden = false
        backButton.isHidden = false
        if strip.count > 0 {
            playStripButton.isHidden = false
        }
        if !(ProcessInfo.processInfo.thermalState == .critical){
            greenScreenButton.isHidden = false
        }
        cameraButton.isHidden = false
        view.bringSubviewToFront(cameraButton)
    }
    
        // MARK: - UI Functions
    
    @IBAction func stopMotionButtonPressed(_ sender: Any){
        if self.pImg.count > 0 {
            self.isPlayingStopMotion = true
            self.isImageToPreview = false
            self.isVideoToPreview = false 
            performSegue(withIdentifier: "showPreview", sender: self)
        }
        
        if isCreatingStopMotion == true {
            statusViewController.showMessage("Stop Motion Mode Deactivated")
            cameraButton.whiteCircle.backgroundColor = .white
            self.isCreatingStopMotion = false
        } else {
            statusViewController.showMessage("Stop Motion Mode Activated")
            cameraButton.whiteCircle.backgroundColor = .purple
            self.isCreatingStopMotion = true
        }
    }


    
    @IBAction func finishRecording(_ sender: Any) {
        sceneView.camera?.endRecording()
    }
    
    @IBAction func create(_ sender: Any){
        //Inital Setup: Show helper messages
        if hasBuilt == false {
            statusViewController.showMessage("Scanning for surfaces...")
            hasBuilt = true
        }
        
        //If in building mode, toggle camera and Vice Versa
        if isBuilding == false {
            createButton.setImage(UIImage(named:"ToggleCamera"), for: .normal)
            hideCameraUI()
            focusSquare.unhide()
            
            self.view.bringSubviewToFront(menuView)
            let menuStartingTransform = menuView.transform
            let menuTransformed = menuStartingTransform.translatedBy(x: 0.0, y: -200.0)
            UIView.animate(withDuration: 0.2) {
                self.menuView.isHidden = false
                self.menuView.transform = menuTransformed
            }
            isBuilding = true
        } else if isBuilding == true {
            createButton.setImage(UIImage(named:"Create"), for: .normal)
            focusSquare.hide()
            let menuStartingTransform = menuView.transform
            let menuTransformed = menuStartingTransform.translatedBy(x: 0.0, y: 200.0)
            UIView.animate(withDuration: 0.2) {
                self.menuView.transform = menuTransformed
                self.menuView.isHidden = true
                self.view.sendSubviewToBack(self.menuView)
            }
            showCameraUI()
            isBuilding = false
        }
        
    }
        
    @IBAction func backButtonPressed(_ sender: Any){
        strip.removeAll()
        isReturn = true
    
        //Clean up scheduled actions
        self.timer?.invalidate()
        NSObject.cancelPreviousPerformRequests(withTarget: self)
        
        //CleanUp Menu
        for index in (menuView.backgrounds.indices.reversed()){
            menuView.backgrounds[index].geometry = nil
            menuView.backgrounds.remove(at: index)
            menuView.backgroundImages.remove(at: index)
        }
        
        for index in (menuView.objects.indices.reversed()){
            menuView.objects[index].geometry = nil
            menuView.objects.remove(at: index)
            menuView.objImages.remove(at: index)
        }
        menuView.backgroundImages.removeAll()
        menuView.objImages.removeAll()
        menuView.backgroundImages = []
        menuView.collectionView = nil
        menuView = nil
        
        //Clean up Main View
        for index in (backgrounds.indices.reversed()){
            backgrounds[index].geometry = nil
        }
        
        for index in (objects.indices.reversed()){
            objects[index].geometry = nil
        }
        
        sceneView.scene.rootNode.cleanup()
        
        removeAllObjects()
        
        for index in (backgrounds.indices.reversed()){
            backgrounds.remove(at: index)
        }
        for index in (objects.indices.reversed()){
            objects.remove(at: index)
        }
        
        virtualObjectInteraction.selectedObject = nil
        
        self.delegateToMenu = nil
        sceneView.delegate = nil
        
        //Clean Up Camera
        self.cam = nil
        sceneView.camera?.sceneView = nil
        sceneView.camera?.delegate = nil
        sceneView.camera?.previewLayer = nil
        sceneView.camera?.pixelBufferAdaptor = nil
        sceneView.camera?.videoInput = nil
        sceneView.camera?.assetWriter = nil
        sceneView.camera?.previewLayer = nil
        sceneView.camera?.captureSession = nil
        sceneView.camera?.audioInput = nil
        sceneView.camera?.audioOutput = nil
        sceneView.camera?.micInput = nil
        sceneView.camera?.recordingSession = nil
        cameraButton.delegate = nil
        cameraButton = nil 
        
        sceneView.camera = nil
        sceneView.removeFromSuperview()
        sceneView = nil

        //delegateToMenu?.returnToMenu()
        performSegue(withIdentifier: "unwindToStart", sender: self)
    }
    
    func removeAllObjects(){
        if backgrounds.count == 0 { return }
        for index in (backgrounds.indices.reversed()){
            removeBackground(at: index)
        }
        
        for index in (objects.indices.reversed()){
            removeObject(at: index)
        }
    }
    
    func removeBackground(at index: Int){
        guard (backgrounds.indices.contains(index)) else { return }
        let background = backgrounds[index]
        
       // restoreObjectInMenuView(node: background)
        
        background.stopTrackedRaycast()
        background.removeFromParentNode()
        background.unload()
        if let anchor = background.anchor {
            session.remove(anchor: anchor)
        }
    }
    
    func removeObject(at index: Int){
        guard (objects.indices.contains(index)) else { return }
        let object = objects[index]
       // restoreObjectInMenuView(node: object)
        object.stopTrackedRaycast()
        object.removeFromParentNode()
        object.unload()
        if let anchor = object.anchor {
            session.remove(anchor: anchor)
        }
    }
    
    func loadObjects() ->[ReferenceNode] {
        print("Objects to load: \(objectsToLoad)")
        let modelsURL = Bundle.main.url(forResource: "\(objectsToLoad).scnassets", withExtension: nil)!

         let fileEnumerator = FileManager().enumerator(at: modelsURL, includingPropertiesForKeys: [])!

         return fileEnumerator.compactMap { element in
                let url = element as! URL

                guard url.pathExtension == "scn" && !url.path.contains("lighting") else { return nil }

                return FileNode(url: url)
        }
    }
    
    func segmentWithDepth(){
        //Camera Configuration
        let configuration = ARWorldTrackingConfiguration()
        configuration.isAutoFocusEnabled = true
        //configuration.frameSemantics = .personSegmentation
        configuration.frameSemantics = .personSegmentationWithDepth
        session.run(configuration, options: [])
        
        var time = 20.0
        if greenKeepOn == false {
            statusViewController.showMessage("Green Screen Mode Activaited for 20 Seconds")
        } else if greenKeepOn == true {
             time = 5.0
        }
        
        perform(#selector(foo), with: nil, afterDelay: time)
    }
    
    @objc func foo(){
        if self.sceneView.camera?.isRecording == true || self.isCreatingStopMotion == true {
            self.greenKeepOn = true
            self.segmentWithDepth()
            return
        }
        let configuration = ARWorldTrackingConfiguration()
        configuration.isAutoFocusEnabled = true
        configuration.planeDetection = [.vertical, .horizontal]
        configuration.environmentTexturing = .automatic
        self.session.run(configuration, options: [])
        self.statusViewController.showMessage("Green Screen Mode Dectivaited")
        self.greenKeepOn = false
    }
    
    

    // MARK: - ARSCNViewDelegate
    
/*
    // Override to create and configure nodes for anchors added to the view's session.
    func renderer(_ renderer: SCNSceneRenderer, nodeFor anchor: ARAnchor) -> SCNNode? {
        let node = SCNNode()
     
        return node
    }
*/
    
    func session(_ session: ARSession, didFailWithError error: Error) {
        // Present an error message to the user
        
    }
    
    func sessionWasInterrupted(_ session: ARSession) {
        // Inform the user that the session has been interrupted, for example, by presenting an overlay
        
    }
    
    func sessionInterruptionEnded(_ session: ARSession) {
        // Reset tracking and/or remove existing anchors if consistent tracking is required
        
    }
}

protocol ReturnToMenuDelegate: class {
    func returnToMenu()
}


