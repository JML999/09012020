//
//  StartView.swift
//  AR_Camera
//
//  Created by Justin Lee on 5/14/20.
//  Copyright © 2020 com.lee. All rights reserved.
//

import Foundation
import UIKit

protocol StartToMainDelegate: class {
    func dataToMainView(backgrounds: [FileBackground], objects: [FileNode], tagForModels: String)
}

class StartView : UIViewController, UICollectionViewDelegate, UICollectionViewDataSource, ReturnToMenuDelegate{
    
    // USER INFO
    var globalUser: String?
    var globalID: String?

    @IBOutlet weak var assetPackView : UICollectionView!
    
    private let assetPackTitles: [String] = [
        "CyberSpace",
        "Garden",
        "Kawaii",
        "Medieval",
        "Manga",
        "Cloudy",
        "Cockpit"
    ]
    private var assetPackImages: [UIImage] = [
        UIImage(named: "CyberSpace")!,
        UIImage(named: "Garden")!,
        UIImage(named: "Kawaii")!,
        UIImage(named: "Medieval")!,
        UIImage(named: "Manga")!,
        UIImage(named: "Cloudy")!,
        UIImage(named: "Cockpit")!
    ]
    
    private let mangaBackgroundTitles: [String] = ["Speed", "WTF", "PowerUp"]
    private let cyberSpaceBackgroundTitles : [String] = ["Runner", "Zapp"]
    private let gardenBackgroundTitles : [String] = ["SunTwirl"]
    private let kawaiiBackgroundTitles : [String] = ["Glitz"]
    private let medievalBackgroundTitles : [String] = []
    private let cloudyBackgroundTitles: [String] = ["Floating"]
    private let basicBackgroundTitles : [String] = ["Blue", "Yellow", "Pink", "Orange"]
    private let cockpitBackgroundTitles : [String] = ["BlackSide"]
 
    
    //CollectionUI
    let cellSpacing: CGFloat = 5
    let cellsPerRow: CGFloat = 2
    
    weak var delegate: StartToMainDelegate? = nil
    var resourceRequest: NSBundleResourceRequest?
    
    //Variables to be sent to main view
    var createdBackgrounds: [FileBackground] = []
    var createdObjects: [FileNode] = []
    var objectsToLoad: String = ""
    let itemSize = UIScreen.main.bounds.width/2-3
    
    //Loading UI
    var activityIndicator = UIActivityIndicatorView()
    var strLabel = UILabel()
    let effectView = UIVisualEffectView(effect: UIBlurEffect(style: .systemUltraThinMaterialLight))
    
    weak var viewController : ViewController?
    
    override func viewDidLoad(){
        assetPackView.delegate = self
        assetPackView.dataSource = self
        self.view.backgroundColor = UIColor(patternImage: UIImage(named: "Background2")!)
        self.assetPackView.backgroundColor = .clear
        
        let layout = self.assetPackView.collectionViewLayout as! UICollectionViewFlowLayout
        layout.sectionInset = UIEdgeInsets(top: 5,left: 0,bottom: 5,right: 0)
        layout.minimumInteritemSpacing = 1

        layout.minimumLineSpacing = 5
        //If you want more than 2 per row, divide by 2++
        layout.itemSize = CGSize(width:(self.assetPackView.frame.size.width - 20)/2, height: assetPackView.frame.size.height/3.75)
        assetPackView.collectionViewLayout = layout
    
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        let mainView = segue.destination as! ViewController
        self.viewController = mainView
        viewController!.delegateToMenu = self
        mainView.modalPresentationStyle = .fullScreen
        
        mainView.globalID = self.globalID!
        mainView.globalUser = self.globalUser!
        
        for bg in createdBackgrounds{
            if !(mainView.backgrounds.contains(bg)){
                mainView.backgrounds.append(bg)
                print("Main Background count\(mainView.backgrounds.count)")
            }
        }
        
        for obj in createdObjects{
            if !(mainView.objects.contains(obj)){
                mainView.objects.append(obj)
                print("Main Obj count\(mainView.objects.count)")
            }
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return assetPackTitles.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "AssetPackCell", for: indexPath) as! AssetPackCell
            cell.assetPackLabel.text = assetPackTitles[indexPath.item]
            cell.assetPackImage.image = assetPackImages[indexPath.item]
            return cell
    }
    
    @IBAction func goToCamera(){
        self.performSegue(withIdentifier: "StartToMainView", sender:nil)
    }
    
    @IBAction func getPathOfImage(_ sender: UIButton) {
        let hitPoint = sender.convert(CGPoint.zero, to: assetPackView)
        if let indexPath = assetPackView.indexPathForItem(at: hitPoint){
            let indexString = assetPackTitles[indexPath.item]
            self.objectsToLoad = "\(indexString)3D"
            
            var tag : [String] = []
            tag.append(indexString)
            
            self.loadResourcesWithTag(assetTitles: tag)
            self.showLoadingUI()
        }
    }
    
  
    func loadResourcesWithTag(assetTitles: [String]){
        let tags = NSSet(array: assetTitles)
         self.resourceRequest = NSBundleResourceRequest(tags: tags as! Set<String>)
        resourceRequest?.conditionallyBeginAccessingResources { (resourceAvailable: Bool) in
            DispatchQueue.main.sync {
                if resourceAvailable {
                    print("On Demand Resources now available")
                    // Do something with resources
                    let assetTag = assetTitles[0]
                    
                    self.loadBackgroundObjects(resourceTag: assetTag)
                    self.createdObjects = self.loadObjects(objectsToLoad: self.objectsToLoad)
                    //self.nextButton.isHidden = false
                    self.dismissLoadingUI()
                    self.performSegue(withIdentifier: "StartToMainView", sender:nil)
                } else {
                    self.resourceRequest!.beginAccessingResources { (error) in
                        //Check for error
                        guard error == nil else {
                            print(error!)
                            return
                        }
                        print("On Demand Resources Downloaded")
                        self.loadResourcesWithTag(assetTitles: assetTitles)
                    }
                }
            }
        }
        print(self.createdBackgrounds.count)
    }
    
    func loadBackgroundObjects(resourceTag: String){
        if resourceTag == "Manga" {
            for i in 0...(mangaBackgroundTitles.count-1){
                let backgroundName = mangaBackgroundTitles[i]
                let backgroundURL = Bundle.main.url(forResource: "\(backgroundName).scnassets", withExtension: nil)!
                let background = FileBackground(url: backgroundURL)
                background?.name = backgroundName
                createdBackgrounds.append(background!)
            }
        } else if resourceTag == "CyberSpace" {
            for i in 0...(cyberSpaceBackgroundTitles.count-1){
                let backgroundName = cyberSpaceBackgroundTitles[i]
                let backgroundURL = Bundle.main.url(forResource: "\(backgroundName).scnassets", withExtension: nil)!
                let background = FileBackground(url: backgroundURL)
                background?.name = backgroundName
                createdBackgrounds.append(background!)
            }
        } else if resourceTag == "Garden" {
            for i in 0...(gardenBackgroundTitles.count-1){
                let backgroundName = gardenBackgroundTitles[i]
                let backgroundURL = Bundle.main.url(forResource: "\(backgroundName).scnassets", withExtension: nil)!
                let background = FileBackground(url: backgroundURL)
                background?.name = backgroundName
                createdBackgrounds.append(background!)
            }
        } else if resourceTag == "Kawaii" {
            for i in 0...(kawaiiBackgroundTitles.count-1){
                let backgroundName = kawaiiBackgroundTitles[i]
                let backgroundURL = Bundle.main.url(forResource: "\(backgroundName).scnassets", withExtension: nil)!
                let background = FileBackground(url: backgroundURL)
                background?.name = backgroundName
                createdBackgrounds.append(background!)
            }
        } else if resourceTag == "Medieval" { }
        else if resourceTag == "Cloudy" {
            for i in 0...(cloudyBackgroundTitles.count-1){
                let backgroundName = cloudyBackgroundTitles[i]
                let backgroundURL = Bundle.main.url(forResource: "\(backgroundName).scnassets", withExtension: nil)!
                let background = FileBackground(url: backgroundURL)
                background?.name = backgroundName
                createdBackgrounds.append(background!)
            }
            
        } else if resourceTag == "Cockpit" {
            for i in 0...(cockpitBackgroundTitles.count-1){
                let backgroundName = cockpitBackgroundTitles[i]
                let backgroundURL = Bundle.main.url(forResource: "\(backgroundName).scnassets", withExtension: nil)!
                let background = FileBackground(url: backgroundURL)
                background?.name = backgroundName
                createdBackgrounds.append(background!)
            }
        }
        loadBasicBackgrounds()
    }
    
    func loadObjects(objectsToLoad: String) -> [FileNode]{
        print(objectsToLoad)
        let modelsURL = Bundle.main.url(forResource: "\(objectsToLoad).scnassets", withExtension: nil)!
        
        let fileEnumerator = FileManager().enumerator(at: modelsURL, includingPropertiesForKeys: [])!
        
        return fileEnumerator.compactMap { element in
            let url = element as! URL
            
             guard url.pathExtension == "scn" && !url.path.contains("lighting") else { return nil }
            
            return FileNode(url: url)
        }
    }
    
    func loadBasicBackgrounds(){
        for i in 0...(basicBackgroundTitles.count-1){
            let backgroundName = basicBackgroundTitles[i]
            let backgroundURL = Bundle.main.url(forResource: "\(backgroundName).scnassets", withExtension: nil)!
            let background = FileBackground(url: backgroundURL)
            background?.name = backgroundName
            createdBackgrounds.append(background!)
        }
    }
    
    func showLoadingUI(){
         activityIndicator("Loading!")        
    }
    
    func dismissLoadingUI(){
        activityIndicator.stopAnimating()
        activityIndicator.removeFromSuperview()
        self.effectView.removeFromSuperview()
    }
    
    func activityIndicator(_ title: String) {
        strLabel.removeFromSuperview()
        activityIndicator.removeFromSuperview()
        effectView.removeFromSuperview()
        
        strLabel = UILabel(frame: CGRect(x: 60, y: 5, width: 160, height: 46))
        strLabel.text = title
        strLabel.font = .systemFont(ofSize: 24, weight: UIFont.Weight.bold)
        strLabel.textColor = UIColor(white: 0.9, alpha: 0.7)
        
        
        effectView.frame = CGRect(x: view.frame.midX - strLabel.frame.width/2,
                                  y: view.frame.midY - strLabel.frame.height/2 ,
                                  width: 200, height: 60)
        effectView.layer.cornerRadius = 15
        effectView.layer.masksToBounds = true
        
        activityIndicator = UIActivityIndicatorView(style: .large)
        activityIndicator.frame = CGRect(x: 4, y: 5, width: 50, height: 50)
        activityIndicator.color = UIColor(red: 0.5, green: 0.2, blue: 0.8, alpha: 0.5)
        activityIndicator.startAnimating()
        
        
        effectView.contentView.addSubview(activityIndicator)
        effectView.contentView.addSubview(strLabel)
        view.addSubview(effectView)
    }
    
    func returnToMenu() {
        self.dismiss(animated: true) {
            for index in (self.createdBackgrounds.indices.reversed()){
                self.createdBackgrounds[index].geometry = nil
            }
            
            for index in (self.createdObjects.indices.reversed()){
                self.createdObjects[index].geometry = nil
            }
            
            self.assetPackView.reloadData()
            self.createdBackgrounds = []
            self.createdObjects = []
            self.resourceRequest!.endAccessingResources()
        }
    }
    
    @IBAction func unwind(_ seg: UIStoryboardSegue ){
        for index in (self.createdBackgrounds.indices.reversed()){
            self.createdBackgrounds[index].geometry = nil
        }
        
        for index in (self.createdObjects.indices.reversed()){
            self.createdObjects[index].geometry = nil
        }
        
        self.assetPackView.reloadData()
        self.createdBackgrounds = []
        self.createdObjects = []
        self.resourceRequest!.endAccessingResources()
    }
        
}


class AssetPackCell : UICollectionViewCell {
    @IBOutlet weak var assetPackImage : UIImageView!
    @IBOutlet weak var assetPackLabel : UILabel!

}
