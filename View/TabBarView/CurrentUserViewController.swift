//
//  CurrentUserViewController.swift
//  AR_Camera
//
//  Created by Justin Lee on 6/13/20.
//  Copyright © 2020 com.lee. All rights reserved.
//

import UIKit
import Firebase
import AVFoundation


class CurrentUserViewController: UIViewController, UICollectionViewDelegate, UICollectionViewDataSource{

    @IBOutlet weak var welcomeLabel: UILabel!
    @IBOutlet weak var libraryCollection: UICollectionView!
    

    var globalUser = ""
    var globalID = ""
    var celCodes = [String]()
    var stripCodes = [[String]]()
    var celArray = [Cel]()
    var timeStamps = [Timestamp]()
    
    
    //Sunday
    var loggedInUser: User?
    var profiledUser: FBUser?
    var timerVal = 2.0
    var timer = Timer()
    var stripArray = [[Cel]]()
    var sortedStrips = [[Cel]]()
    var stripAddresses = [String]()
    var newCels = [Cel]()
    var newStrips = [[Cel]]()
    var stripIDs = [String]()
    var celsToPlay: [Cel]?
    
    // We keep track of the pending work item as a property
    private var pendingRequestWorkItem: DispatchWorkItem?
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.loggedInUser = Auth.auth().currentUser
        
        self.libraryCollection?.performBatchUpdates({
          self.loadData()
        }, completion: nil)
       
        view.backgroundColor = .white
        welcomeLabel.textColor = .black
        view.addSubview(welcomeLabel)
        
        welcomeLabel.text = profiledUser?.username
        self.libraryCollection.dataSource = self
        self.libraryCollection.delegate = self
        
        let layout = self.libraryCollection.collectionViewLayout as! UICollectionViewFlowLayout
        layout.sectionInset = UIEdgeInsets(top: 0,left: 0,bottom: 0,right: 0)
        layout.minimumInteritemSpacing = 0.5

        layout.minimumLineSpacing = 5
        //If you want more than 2 per row, divide by 2++
        //layout.itemSize = CGSize(width:(self.libraryCollection.frame.size.width - 20)/2.25, height: libraryCollection.frame.size.height/3)
        libraryCollection.collectionViewLayout = layout
        timer = Timer.scheduledTimer(timeInterval: timerVal, target: self, selector: #selector(timerAction), userInfo: nil, repeats: false)
        
    }
    
    var timerCount = 0
    @objc func timerAction(){
        if newCels.count == 0 {
            if timerCount >= 5 {
                print("REQUEST TIMED OUT")
                return
            }
            print("Trouble Loading")
            newCels = []
            stripArray = []
            stripIDs = []
            sortedStrips = []
            loadData()
            timer.invalidate()
            timer = Timer.scheduledTimer(timeInterval: (timerVal + 0.5), target: self, selector: #selector(timerAction), userInfo: nil, repeats: false)
            timerCount += 1
            return
        }
        sortStrips()
    }
    
    func loadData(){
        let db = Firestore.firestore()
        let docRef = db.collection("users").document(profiledUser!.uid)
        docRef.getDocument { (document, error) in
            if let document = document, document.exists {
                guard document.get("StripIDs") != nil else {return}
                self.stripAddresses = document.get("StripIDs") as! [String]
                self.pendingRequestWorkItem?.cancel()
                
                let requestWorkItem = DispatchWorkItem { [weak self] in
                    let stripRef = db.collection("Posts").document(self!.profiledUser!.uid).collection("userPosts")
                    for str in self!.stripAddresses {
                        stripRef.document(str).collection("Cels").getDocuments { (querySnapshot, error) in
                            if let error = error {
                                print("Error getting documents: \(error)")
                            } else {
                                for document in querySnapshot!.documents {
                                    let c = Cel()
                                    let documentDic = document.data() as NSDictionary
                                          
                                    //Pull 0, 1, or 2 code for pic,gif, vid formats
                                    let singleCode = documentDic.allValues[0]
                                    let singleCodeString = singleCode as! String
                                    if singleCodeString == "0" {
                                        c.isPicture = true
                                    }else if singleCodeString == "1" {
                                        c.isGif = true
                                    } else if singleCodeString == "2" {
                                        c.isVideo = true
                                    }
                                          
                                    let singleURL = documentDic.allValues[1]
                                    c.urlString = singleURL as! String
                                    
                                    let stripID = documentDic.allValues[3]
                                    c.stripID = stripID as? String
                                    self!.stripIDs.append((stripID as? String)!)
                                          
                               
                                    let stamp = documentDic.allValues[2]
                                    let ts = stamp as! Timestamp
                                    c.timeStamp = ts
                                          
                                    let containsCheck = self!.newCels.filter {cl in cl.urlString == c.urlString}
                                    if containsCheck.count > 0 {
                                        return
                                    } else {
                                        self!.newCels.append(c)
                                    }
                                
                                }
                            }
                        }
                    }

                }
                self.pendingRequestWorkItem = requestWorkItem
                DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(250),
                                              execute: requestWorkItem)
            } else {
                print("Document does not exist")
            }
        }
    }
    
  
    
    func createCels(URLs: [String]){
        var count = 0
        for url in URLs {
            let c = Cel()
            c.urlString = url
            c.timeStamp = timeStamps[count]
            celArray.append(c)
            count += 1
        }
        timeStamps = []
    }
    
    func sortStrips(){
        let uniqueIDs = Array(Set(stripIDs))
        for str in uniqueIDs {
            var strip = [Cel]()
            for c in newCels {
                if c.stripID == str {
                    strip.append(c)
                }
            }
            let orderedStrip = strip.sorted(by: {$0.timeStamp!.dateValue() < $1.timeStamp!.dateValue()} )
            newStrips.append(orderedStrip)
            self.sortedStrips = newStrips.sorted(by: {$0[0].timeStamp!.dateValue() < $1[0].timeStamp!.dateValue()} )
        }
        sortedStrips.reverse()
        self.libraryCollection.isHidden = false
        libraryCollection.reloadData()
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        print("Strip Array Count: \(celArray.count)")
        return sortedStrips.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = libraryCollection.dequeueReusableCell(withReuseIdentifier: "libraryCell", for: indexPath) as! LibraryCell
        cell.coverImage!.layer.cornerRadius = 12
        let firstCell = sortedStrips[indexPath.item][0]
        if let url = URL(string: sortedStrips[indexPath.item][0].urlString) {
            if firstCell.isVideo {
                for c in sortedStrips[indexPath.item]{
                    if c.isPicture {
                        cell.coverImage?.sd_setImage(with: URL(string: c.urlString), placeholderImage: UIImage(named: "Blue.jpg") )
                        return cell
                    }
                }
                for c in sortedStrips[indexPath.item]{
                    if c.isGif {
                        cell.coverImage?.sd_setImage(with: URL(string: c.urlString), placeholderImage: UIImage(named: "Blue.jpg") )
                        return cell
                    }
                }
                let player = AVPlayer(url: url)
                let playerLayer = AVPlayerLayer(player: player)
                playerLayer.frame = cell.bounds
                cell.layer.addSublayer(playerLayer)
                player.play()
                player.pause()
                return cell
            } else {
                cell.coverImage?.sd_setImage(with: url, placeholderImage: UIImage(named: "Blue.jpg") )
                return cell
            }
        }
        return cell
    }
    
    @IBAction func getPathOfImage(_ sender: UIButton) {
        let hitPoint = sender.convert(CGPoint.zero, to: libraryCollection)
        if let indexPath = libraryCollection.indexPathForItem(at: hitPoint){
            self.celsToPlay = sortedStrips[indexPath.item]
            self.performSegue(withIdentifier: "libraryToPlay", sender:nil)
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        self.timer.invalidate()
        if let destination = segue.destination as? PlayStripViewController{
            destination.strip = self.celsToPlay
        }
    }

}


class LibraryCell: UICollectionViewCell {
    @IBOutlet weak var coverImage: UIImageView?
}


/*
 
 
 
 func sortStrips(){
       for strip in stripArray {
           let sorted = strip.sorted(by: { (($0.timeStamp?.compare($1.timeStamp!))!.rawValue < ($1.timeStamp?.compare($0.timeStamp!))!.rawValue)})
           sortedStrips.append(sorted)
           if sortedStrips.count == 0 {sortedStrips.append(sorted)}
           else {
               if let index = sortedStrips.firstIndex(where: {($0[0].timeStamp?.compare(sorted[0].timeStamp!))!.rawValue > 0 }) {
                   sortedStrips.insert(sorted, at: index)
               }
           }
       }
       self.stripArray = sortedStrips
       libraryCollection.reloadData()
       self.classifyCels()
       print(self.stripCodes)
       
      
       print("Before")
       for strip in stripArray {
           for cell in strip{
               print(cell.urlString)
               print(cell.timeStamp)
           }
       }
       for strip in stripArray {
           let sorted = strip.sorted(by: { (($0.timeStamp?.compare($1.timeStamp!))!.rawValue > ($1.timeStamp?.compare($0.timeStamp!))!.rawValue)})
         //  sortedStrips.append(sorted)
           
           if sortedStrips.count == 0 {sortedStrips.append(sorted)}
           else {
               if let index = sortedStrips.firstIndex(where: {($0[0].timeStamp?.compare(sorted[0].timeStamp!))!.rawValue > 0 }) {
                   sortedStrips.insert(sorted, at: index)
               }
           }
       }
       
       print("After")
       for strip in stripArray {
           for cell in strip{
               print(cell.urlString)
               print(cell.timeStamp)
           }
       }
       
       var finalSorted: [[Cel]] = []
       for s in sortedStrips {
           if finalSorted.contains(where: {$0[0].urlString == s[0].urlString}){
               continue
           } else {
               finalSorted.append(s)
           }
       }
       
       print("FINAL SORTED SORTED")
       for c in finalSorted {
           print(c[0].urlString)
       }
       
       self.stripArray = finalSorted.reversed()
       self.libraryCollection.reloadData()
       
 }
 
 func classifyCels(){
     var outercount = 0
     for strip in stripArray {
         var innerCount = 0
         for cell in strip {
             print(cell.timeStamp as Any)
             if stripCodes[outercount][innerCount] == "0" {
                 cell.isPicture = true
             } else if stripCodes[outercount][innerCount] == "1" {
                 cell.isGif = true
             } else if stripCodes[outercount][innerCount] == "2" {
                 cell.isVideo = true
             }
             innerCount += 1
         }
         outercount += 1
     }
 }
 
 func loadData(){
       let db = Firestore.firestore()
       let docRef = db.collection("users").document("\(profiledUser!.uid)")

       //Access user db to retrieve each strip (i.e. strip address) created by user
       docRef.getDocument { (document, error) in
           if let document = document, document.exists {
               
               //For each user, get the codes that indicate pic, gif, or vid strip
               guard document.get("StripIDs") != nil else {return}
               
               self.stripAddresses = document.get("StripIDs") as! [String]
               
               let stripRef = db.collection("Strips")
               
               //For each strip address, access urls for each strip, make Cel's with the data
               for str in self.stripAddresses {
                   stripRef.document("\(self.profiledUser!.uid)").collection("\(str)").getDocuments() { (querySnapshot, err) in
                       if let err = err {
                           print("Error getting documents: \(err)")
                       } else {
                           for document in querySnapshot!.documents {
                               //Sunday
                               let c = Cel()
                       
                               let documentDic = document.data() as NSDictionary
                               
                               //Pull 0, 1, or 2 code for pic,gif, vid formats
                               let singleCode = documentDic.allValues[0]
                      //         self.celCodes.append(singleCode as! String)
                               
                               //Sunday
                               let singleCodeString = singleCode as! String
                               if singleCodeString == "0" {
                                   c.isPicture = true
                               }else if singleCodeString == "1" {
                                   c.isGif = true
                               } else if singleCodeString == "2" {
                                   c.isVideo = true
                               }
                               
                               let singleURL = documentDic.allValues[1]
                               c.urlString = singleURL as! String
                       //        urlsPerStrip.append(singleURL as! String)
                               
                               let stripID = documentDic.allValues[3]
                               c.stripID = stripID as? String
                               self.stripIDs.append((stripID as? String)!)
                               
                               //Pull timestamps
                               let stamp = documentDic.allValues[2]
                               let ts = stamp as! Timestamp
                     //          self.timeStamps.append(ts)
                               
                               //Add timestamp to cell
                               c.timeStamp = ts
                               
                               let containsCheck = self.newCels.filter {cl in cl.urlString == c.urlString}
                               
                               if containsCheck.count > 0 {
                                   return
                               } else {
                                   self.newCels.append(c)
                               }
                               
                               /*
                               for cel in self.newCels {
                                   if cel.urlString == c.urlString {
                                       return
                                   }
                               }
                               self.newCels.append(c)
                               */
                           }
                           self.libraryCollection.isHidden = true
                           //Add codes for entire strip
                   //        self.stripCodes.append(self.celCodes)
                   //        self.celCodes = []
                           
                           //Create cels, add cells to strip
                   //        self.createCels(URLs: urlsPerStrip)
                   //        self.stripArray.append(self.celArray)
                   //        self.celArray = []
                           
                           //Load data
                  //         self.libraryCollection.isHidden = true
                          // self.libraryCollection?.insertItems(at: [IndexPath(item: self.stripArray.count - 1, section: 0)])
                           
                           
                  //         self.libraryCollection.reloadData()
                  //         let indexSet = IndexSet(integer: 0)
                  //         self.libraryCollection.reloadSections(indexSet)
                            
                       }
                   }
               }
           } else {
               print("Document does not exist")
           }
           
       }
   }
 */
