//
//  MenuView.swift
//  AR_Camera
//
//  Created by Justin Lee on 5/21/20.
//  Copyright © 2020 com.lee. All rights reserved.
//

import Foundation
import UIKit

protocol MenuToMainDelegate: class {
    func backgroundToMain(didSelectObject: FileBackground)
    func objectToMain(_ selectionViewController: MenuView, didSelectObject: FileNode)
    func messageToMain(string: String )
}

class MenuView: UIView, UICollectionViewDelegate, UICollectionViewDataSource {
    
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var showBackgrounds: UIButton!
    @IBOutlet weak var showObjects: UIButton!
    
    var backgrounds: [FileBackground] = []
    var backgroundImages: [UIImage] = []
    
    var objects: [FileNode] = []
    var objImages: [UIImage] = []
    
    var selectedObjects : [String] = []
    var isBackground = true
    var isObjects = false
    weak var delgate: MenuToMainDelegate? = nil
    
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        loadUI()
        if isBackground{
            return backgrounds.count
        } else {
            return objects.count
        }
    }
    
    func loadUI(){
        for bg in backgrounds{
            let img = UIImage(named: bg.name!)!
            backgroundImages.append(img)
        }
        
        for obj in objects{
            let img = UIImage(named: obj.modelName)
            print(obj.modelName)
            objImages.append(img!)
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "MenuCell", for: indexPath) as! MenuCell
        if isBackground{
            cell.menuItemImage.image = backgroundImages[indexPath.item]
        } else {
            cell.menuItemImage.image = objImages[indexPath.item]
        }
        return cell
    }
    
    @IBAction func getPathOfImage(_ sender: UIButton) {
        let hitPoint = sender.convert(CGPoint.zero, to: collectionView)
        if let indexPath = collectionView.indexPathForItem(at: hitPoint){
            if isBackground {
                let indexObj = backgrounds[indexPath.item]
                let indexName = indexObj.name
                if selectedObjects.contains(indexName!){
                    delgate?.messageToMain(string: "Background already selected!")
                    return
                } else {
                    delgate?.backgroundToMain(didSelectObject: indexObj)
                    selectedObjects.append(indexName!)
                }
            } else {
                let indexObj = objects[indexPath.item]
                let indexName = indexObj.modelName
                if selectedObjects.contains(indexName){
                    delgate?.messageToMain(string: "Object already selected!")
                    return
                } else {
                    delgate?.objectToMain(self, didSelectObject: indexObj)
                    selectedObjects.append(indexName)
                }
            }
        }
    }
    
    @IBAction func showBackgroundButtonPushed(){
        if isBackground {
            return
        }
        if isObjects {
            isBackground = true
            isObjects = false
            collectionView.reloadData()
        }
        
    }
    
    @IBAction func showObjectsButtonPushed(){
        if isObjects {
            return
        }
        if isBackground {
            isBackground = false
            isObjects = true
            collectionView.reloadData()
        }
        
    }

}

class MenuCell: UICollectionViewCell {
    @IBOutlet weak var menuItemImage : UIImageView!
}
