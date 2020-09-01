//
//  LoginViewController.swift
//  AR_Camera
//
//  Created by Justin Lee on 6/13/20.
//  Copyright © 2020 com.lee. All rights reserved.
//

import UIKit
import Firebase

class LoginViewController: UIViewController {

    @IBOutlet weak var emailTextField: UITextField!
    
    @IBOutlet weak var passwordTextField: UITextField!
    @IBOutlet weak var loginButton: UIButton!
    
    @IBOutlet weak var errorLabel: UILabel!
    
    var currentUser: FBUser?
    var username: String?
    var globalUser: String?
    var globalID: String?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setUpElements()
        view.backgroundColor = .white
        emailTextField.textColor = .black
        passwordTextField.textColor = .black

        // Do any additional setup after loading the view.
    }
    
    func setUpElements(){
        errorLabel.alpha = 0
        Utilities.styleTextField(emailTextField)
        Utilities.styleTextField(passwordTextField)
        Utilities.styleFilledButton(loginButton)
    }
    
    @IBAction func loginButtonPressed(_ sender: Any) {
        let email = emailTextField.text!.trimmingCharacters(in: .whitespacesAndNewlines)
        let password = passwordTextField.text!.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Signing in the user
        Auth.auth().signIn(withEmail: email, password: password) { (result, error) in
            if error != nil {
                // Couldn't sign in
                self.errorLabel.text = error!.localizedDescription
                self.errorLabel.alpha = 1
            }
            else {
                self.globalID = result?.user.uid
                let db = Firestore.firestore()
                let ref = db.collection("users").document(self.globalID!)
                ref.getDocument { (querySnapShot, error) in
                    if error != nil {
                        print("Error is \(error!.localizedDescription)")
                    } else{
                        guard let snapshot = querySnapShot else {return}
                        let docDic = snapshot.data()! as NSDictionary
                        self.globalUser = docDic["username"] as? String
                        let logInDic = ["username": self.globalUser, "uid": self.globalID]
                        self.currentUser = FBUser(dictionary: logInDic as! [String : String])
                        self.transitionToHome()
                    }
                }
            }
        }
    }
    
    func transitionToHome(){
        performSegue(withIdentifier: "LogInToTab", sender: self)
    }
    
    //Pass User Info
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let destination = segue.destination as? TabBarViewController{
            let vc = destination.viewControllers![0] as! FeedViewController
            vc.currentUser = self.currentUser
            
            let vc2 = destination.viewControllers![1] as! StartView
            vc2.globalUser = globalUser
            vc2.globalID = globalID
            
            let vc3 = destination.viewControllers![2] as! DiscoverViewController
            vc3.currentUser = currentUser
            vc3.globalUser = globalUser
            vc3.globalID = globalID
            
            let vc4 = destination.viewControllers![3] as! CurrentUserViewController
            vc4.profiledUser = self.currentUser
            vc4.globalUser = globalUser!
            vc4.globalID = globalID!
        }
    }

    
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
