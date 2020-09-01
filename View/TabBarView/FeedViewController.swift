//
//  FeedViewController.swift
//  AR_Camera
//
//  Created by Justin Lee on 8/28/20.
//  Copyright © 2020 com.lee. All rights reserved.
//

import Foundation
import Firebase
import AVFoundation

class FeedViewController: UIViewController, UICollectionViewDelegate, UICollectionViewDataSource{
    
    @IBOutlet weak var feedCollectionView: UICollectionView!
    
    let db = Firestore.firestore()
    var currentUser: FBUser?
    var currentUserID: String?
    var query: Query!
    
    var userIDs = [String]()
    var docURLs = [String]()
    var stripIDs = [String]()
    var newCels = [Cel]()
    
    var timer = Timer()
    var timerVal = 2.0
    
   var newStrips = [[Cel]]()
   var sortedStrips = [[Cel]]()
    
    override func viewDidLoad() {
        self.feedCollectionView.dataSource = self
        self.feedCollectionView.delegate = self
        self.feedCollectionView?.performBatchUpdates({
          self.loadUserIDs()
        }, completion: nil)
        
        loadUserIDs()
        timer = Timer.scheduledTimer(timeInterval: timerVal, target: self, selector: #selector(timerAction), userInfo: nil, repeats: false)

    }
    

    func loadUserIDs(){
        let collectionRef = db.collection("following").document(currentUser!.uid).collection("userFollowing")
        collectionRef.getDocuments { (querySnapShot, err) in
            if err != nil {
                print("Error is \(err!.localizedDescription)")
            } else {
                guard let snapshot = querySnapShot else {return}
                for document in snapshot.documents {
                    let myData = document.data()
                    let id = myData["uid"] as? String ?? "No Name Found"
                    let containsCheck = self.userIDs.filter {cl in cl == id}
                    if containsCheck.count > 0 {
                        return
                    } else {
                        self.userIDs.append(id)
                    }
                }
            }
            self.loadDocIDs()
        }
    }
    
    func loadDocIDs(){
        for id in userIDs {
            let query = db.collection("Posts/" + id + "/userPosts").order(by: "Date", descending: true).limit(to: 3)
            query.getDocuments { (querySnapShot, err) in
                if err != nil {
                    print("Error is \(err!.localizedDescription)")
                 } else {
                    guard let snapshot = querySnapShot else {return}
                    for document in snapshot.documents {
                        self.loadURLs(UserID: id, DocID: document.documentID)
                    }
                }
            }
        }
    }
    
    func loadURLs(UserID: String, DocID: String ){
        var postUserName = ""

        let query = db.collection("Posts/" + UserID + "/userPosts/" + DocID + "/Cels")
        query.getDocuments { (querySnapShot, err) in
            if err != nil {
                print("Error is \(err!.localizedDescription)")
            } else {
                guard let snapshot = querySnapShot else {return}
                for document in snapshot.documents {
                    let documentDic = document.data() as NSDictionary
                    let c = Cel()
                    
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
                    self.stripIDs.append((stripID as? String)!)
                    
                    let stamp = documentDic.allValues[2]
                    let ts = stamp as! Timestamp
                    c.timeStamp = ts
                    
                    //Provide Username
                    let idDoc = self.db.collection("users").document(UserID)
                    idDoc.getDocument { (querySnapShot, err) in
                        if err != nil {
                            print("Error is \(err!.localizedDescription)")
                        } else{
                            guard let snapshot = querySnapShot else {return}
                            let docDic = snapshot.data()! as NSDictionary
                            postUserName = docDic["username"] as! String
                        }
                        c.username = postUserName
                    }
                    
                    let containsCheck = self.newCels.filter {cl in cl.urlString == c.urlString}
                     if containsCheck.count > 0 {
                         return
                     } else {
                        self.newCels.append(c)
                    }
                }
            }
        }
    }
    
    var timerCount = 0
    @objc func timerAction(){
        print(self.newCels.count)
        if newCels.count == 0 {
            if timerCount >= 5 {
                print("REQUEST TIMED OUT")
                return
            }
            print("Trouble Loading")
            newCels = []
            stripIDs = []
            loadUserIDs()
            timer.invalidate()
            timer = Timer.scheduledTimer(timeInterval: (timerVal + 0.5), target: self, selector: #selector(timerAction), userInfo: nil, repeats: false)
            timerCount += 1
            return
        }
        sortStrips()
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
        self.feedCollectionView.isHidden = false
        feedCollectionView.reloadData()
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return sortedStrips.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = feedCollectionView.dequeueReusableCell(withReuseIdentifier: "FeedCell", for: indexPath) as! FeedCell
        cell.backgroundColor = .white
        cell.coverImg.layer.cornerRadius = 12
        cell.coverImg.contentMode = .scaleAspectFill
        cell.coverImg.clipsToBounds = true
        cell.coverImg.translatesAutoresizingMaskIntoConstraints = false
        
        let firstCell = sortedStrips[indexPath.item][0]
        cell.usernameLabel.text = firstCell.username
        cell.contentView.bringSubviewToFront(cell.usernameLabel)
        
        if let url = URL(string: sortedStrips[indexPath.item][0].urlString) {
            if firstCell.isVideo {
                for c in sortedStrips[indexPath.item]{
                    if c.isPicture {
                        cell.coverImg?.sd_setImage(with: URL(string: c.urlString), placeholderImage: UIImage(named: "Blue.jpg") )
                        cell.contentView.bringSubviewToFront(cell.usernameLabel)
                        return cell
                    }
                }
                for c in sortedStrips[indexPath.item]{
                    if c.isGif {
                        cell.coverImg?.sd_setImage(with: URL(string: c.urlString), placeholderImage: UIImage(named: "Blue.jpg") )
                        cell.contentView.bringSubviewToFront(cell.usernameLabel)
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
                cell.usernameLabel.text = firstCell.username
                cell.contentView.bringSubviewToFront(cell.usernameLabel)
                cell.coverImg?.sd_setImage(with: url, placeholderImage: UIImage(named: "Blue.jpg"))
                return cell
            }
        }
        return cell
    }
    
    @IBAction func incrementLikeValue(_ sender: UIButton){
        let hitPoint = sender.convert(CGPoint.zero, to: feedCollectionView)
        if let indexPath = feedCollectionView.indexPathForItem(at: hitPoint){
            let postToLike = sortedStrips[indexPath.item][0].stripID
           
            
            
        }
    }
    

}

class FeedCell: UICollectionViewCell {
    @IBOutlet weak var coverImg: UIImageView!
    @IBOutlet weak var usernameLabel: UILabel!
    
    
}
