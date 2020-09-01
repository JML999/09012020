//
//  DiscoverViewController.swift
//  AR_Camera
//
//  Created by Justin Lee on 8/24/20.
//  Copyright © 2020 com.lee. All rights reserved.
//

import Foundation
import Firebase

class DiscoverViewController: UIViewController, UICollectionViewDelegate, UICollectionViewDataSource, UISearchBarDelegate {

    @IBOutlet weak var searchCollectionView: UICollectionView!
    @IBOutlet weak var searchBar: UISearchBar!
    
    var globalUser: String?
    var globalID: String?
    var currentUser: FBUser?
    
    var people = [FBUser]()
    var profiledUser: FBUser?
    
    let db = Firestore.firestore()
   
    // We keep track of the pending work item as a property
    private var pendingRequestWorkItem: DispatchWorkItem?
    
    
    override func viewDidLoad() {
        self.searchCollectionView.delegate = self
        self.searchCollectionView.dataSource = self
        self.searchBar.delegate = self
        self.searchBar.placeholder = "Search"
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
         let tap: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: "dismissKeyboard")
         view.addGestureRecognizer(tap)
        DispatchQueue.global(qos: .default).async(execute: {() -> Void in
          DispatchQueue.main.async(execute: {() -> Void in
            self.searchBar.becomeFirstResponder()
          })
        })
    }
    
    @objc func dismissKeyboard() {
        view.endEditing(true)
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return people.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = searchCollectionView.dequeueReusableCell(withReuseIdentifier: "searchCell", for: indexPath) as! SearchCell
        let user = people[indexPath.item]
        cell.name?.text = user.username
        return cell
    }
    
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        if searchText.isEmpty {
            return
        }
        let searchString = searchText.lowercased()
        pendingRequestWorkItem?.cancel()
        
        // Wrap our request in a work item
        let requestWorkItem = DispatchWorkItem { [weak self] in
          self?.people = [FBUser]()
          self?.searchCollectionView?.reloadData()
          self?.searchCollectionView?.performBatchUpdates({
            self?.search(searchString, at: "username")
          }, completion: nil)
        }
        // Save the new work item and execute it after 250 ms
        pendingRequestWorkItem = requestWorkItem
        DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(250),
                                      execute: requestWorkItem)
    }
    
    private func search(_ searchString: String, at index: String) {
        let collectionRef: CollectionReference!
        collectionRef = db.collection("users")
        collectionRef.getDocuments { (querySnapShot, err) in
            if err != nil {
                print("Error is \(err!.localizedDescription)")
            } else {
                guard let snapshot = querySnapShot else {return}
                for document in snapshot.documents {
                    let myData = document.data()
                    let username = myData["username"] as? String ?? "No Name Found"
                    if username.contains(searchString) {
                        let queryuid = myData["uid"] as? String ?? "No ID Found"
                        let newDic = ["username" : username , "uid" : queryuid] as NSDictionary
                        let foundUser = FBUser(dictionary: newDic as! [String : String])
                        self.people.append(foundUser)
                        self.searchCollectionView?.insertItems(at: [IndexPath(item: self.people.count - 1, section: 0)])
                        //self.searchCollectionView.reloadData()
                    }
                }
            }
        }
    }
    
    
    @IBAction func getPathOfCell(_ sender: UIButton){
        let hitPoint = sender.convert(CGPoint.zero, to: searchCollectionView)
        if let indexPath = searchCollectionView.indexPathForItem(at: hitPoint){
            self.profiledUser = people[indexPath.item]
            self.performSegue(withIdentifier: "SearchToUser", sender:nil)
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let destination = segue.destination as? ProfileViewController{
            destination.currentUser = self.currentUser
            destination.profiledUser = self.profiledUser
        }
    }

}

class SearchCell: UICollectionViewCell {
    @IBOutlet weak var profileImg: UIImageView?
    @IBOutlet weak var name: UILabel?
}

