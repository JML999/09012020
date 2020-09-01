import UIKit
import Firebase
import AVFoundation


class ProfileViewController: UIViewController, UICollectionViewDelegate, UICollectionViewDataSource{
    @IBOutlet weak var profileLibaryCollection: UICollectionView!
    @IBOutlet weak var usernameLabel: UILabel?
    @IBOutlet weak var backButton: UIButton?
    @IBOutlet weak var backLabel: UILabel?

    var profiledUser: FBUser?
    var currentUser: FBUser?
    var timer = Timer()
    var timerVal = 2.0
    
    var stripAddresses = [String]()
    var newCels = [Cel]()
    var newStrips = [[Cel]]()
    var stripIDs = [String]()
    var sortedStrips = [[Cel]]()
    var stripArray = [[Cel]]()
    var celsToPlay: [Cel]?
    
    // We keep track of the pending work item as a property
    private var pendingRequestWorkItem: DispatchWorkItem?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.profileLibaryCollection.dataSource = self
        self.profileLibaryCollection.delegate = self
        self.profileLibaryCollection?.performBatchUpdates({
          self.loadData1()
        }, completion: nil)
       
        view.backgroundColor = .white
        usernameLabel!.textColor = .black
        view.addSubview(usernameLabel!)
        usernameLabel!.text = profiledUser?.username
        
        backLabel!.textColor = .black
        view.addSubview(backLabel!)
        
        let layout = self.profileLibaryCollection.collectionViewLayout as! UICollectionViewFlowLayout
        layout.sectionInset = UIEdgeInsets(top: 0,left: 0,bottom: 0,right: 0)
        layout.minimumInteritemSpacing = 0.5

        layout.minimumLineSpacing = 5
        //If you want more than 2 per row, divide by 2++
        //layout.itemSize = CGSize(width:(self.libraryCollection.frame.size.width - 20)/2.25, height: libraryCollection.frame.size.height/3)
        profileLibaryCollection.collectionViewLayout = layout
        timer = Timer.scheduledTimer(timeInterval: timerVal, target: self, selector: #selector(timerAction), userInfo: nil, repeats: false)
        
        profileLibaryCollection.backgroundColor = .white
        
    }
    
    func loadData1(){
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
                                //For each strip under user's strips pull URL
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
                                self.stripIDs.append((stripID as? String)!)
                                
                                //Pull timestamps
                                let stamp = documentDic.allValues[2]
                                let ts = stamp as! Timestamp
                               
                                //Add timestamp to cell
                                c.timeStamp = ts
                            
                                self.newCels.append(c)
                            }
                            //Load data
                            self.profileLibaryCollection.isHidden = true
                        }
                    }
                }
            } else {
                print("Document does not exist")
            }
            
        }
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
            sortedStrips = []
            stripIDs = []
            loadData1()
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
        self.profileLibaryCollection.isHidden = false
        profileLibaryCollection.reloadData()
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return sortedStrips.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = profileLibaryCollection.dequeueReusableCell(withReuseIdentifier: "ProfileCell", for: indexPath) as! ProfileCell
        cell.coverImg.layer.cornerRadius = 12
        cell.coverImg.contentMode = .scaleAspectFill
        cell.coverImg.clipsToBounds = true
        cell.coverImg.translatesAutoresizingMaskIntoConstraints = false
        let firstCell = sortedStrips[indexPath.item][0]
        if let url = URL(string: sortedStrips[indexPath.item][0].urlString) {
            if firstCell.isVideo {
                for c in sortedStrips[indexPath.item]{
                    if c.isPicture {
                        cell.coverImg?.sd_setImage(with: URL(string: c.urlString), placeholderImage: UIImage(named: "Blue.jpg") )
                        return cell
                    }
                }
                for c in sortedStrips[indexPath.item]{
                    if c.isGif {
                        cell.coverImg?.sd_setImage(with: URL(string: c.urlString), placeholderImage: UIImage(named: "Blue.jpg") )
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
                cell.coverImg?.sd_setImage(with: url, placeholderImage: UIImage(named: "Blue.jpg") )
                return cell
            }
        }
        return cell
    }
    
 
    
    @IBAction func getPathOfImage(_ sender: UIButton) {
        let hitPoint = sender.convert(CGPoint.zero, to: profileLibaryCollection)
        if let indexPath = profileLibaryCollection.indexPathForItem(at: hitPoint){
            self.celsToPlay = sortedStrips[indexPath.item]
            self.performSegue(withIdentifier: "UserToPlay", sender:nil)
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        self.timer.invalidate()
        if let destination = segue.destination as? PlayStripViewController{
            destination.strip = self.celsToPlay
        }
    }
    
    @IBAction func backButtonPressed(_ sender: UIButton){
        profiledUser = nil
        currentUser = nil
        timer.invalidate()
        newCels = []
        newStrips = []
        stripIDs = []
        sortedStrips = []
        stripArray = []
        celsToPlay = []
        navigationController?.popViewController(animated: true)
    }
    
    @IBAction func followButtonPressed(_ sender: UIButton){
        let db = Firestore.firestore()
        let userref = db.collection("following").document(currentUser!.uid)
        userref.collection("userFollowing").addDocument(data: ["uid" : profiledUser?.uid])
        
        
        userref.setData(["following" : profiledUser?.uid as Any])
        let uniqueIDs = Array(Set(stripIDs))
        for s in uniqueIDs {
            userref.updateData(["followingStrips" : FieldValue.arrayUnion([s])])
        }
    }
    
}

class ProfileCell: UICollectionViewCell {
    @IBOutlet weak var coverImg: UIImageView!
}
