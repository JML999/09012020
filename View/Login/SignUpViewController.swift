//
//  SignUpViewController.swift
//  AR_Camera
//
//  Created by Justin Lee on 6/13/20.
//  Copyright © 2020 com.lee. All rights reserved.
//

import UIKit
import Firebase

class SignUpViewController: UIViewController {
    
    @IBOutlet weak var userNameTextField: UITextField!
    @IBOutlet weak var emailTextField: UITextField!
    
    @IBOutlet weak var passwordTextField: UITextField!
    @IBOutlet weak var signUpButton: UIButton!
    @IBOutlet weak var errorLabel: UILabel!
    
    @IBOutlet weak var testButton: UIButton!
    
    var globalUser = ""
    var globalID = ""
    var currentUser: FBUser?
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setUpElements()
        view.backgroundColor = .white
    }
    
    func setUpElements(){
        errorLabel.alpha = 0
        Utilities.styleTextField(userNameTextField)
        Utilities.styleTextField(emailTextField)
        Utilities.styleTextField(passwordTextField)
        Utilities.styleFilledButton(signUpButton)
    }
    
    @IBAction func testButtonPressed(){
        self.globalUser = "test9999"
        self.globalID = "fxtrsFTTMKNCDTm8e3BNWTFuQXw2"
        let logInDic = ["username": self.globalUser, "uid": self.globalID]
        self.currentUser = FBUser(dictionary: logInDic)
        transitionToHome()
    }
    
    @IBAction func signUpButtonPressed(_ sender: Any) {
        //Validate fields
        let error = validateFields()
        
        if error != nil {
            //Show error message
            showError(error!)
        } else {
            //Create cleaned version of the data
            let userName = self.userNameTextField.text!.trimmingCharacters(in: .whitespacesAndNewlines)
            globalUser = userName
            let email = self.emailTextField.text!.trimmingCharacters(in: .whitespacesAndNewlines)
            let password = self.passwordTextField.text!.trimmingCharacters(in: .whitespacesAndNewlines)
            
            //Create the user
            Auth.auth().createUser(withEmail: email, password: password) { (result, err) in
                if err != nil {
                    //There was an error creating the user
                    self.showError("Error creating user")
                } else {
                    //User created successfully, store the first name and last name
                    let db = Firestore.firestore()
                    db.collection("users").document("\(result!.user.uid)").setData(["username" : userName, "uid": result!.user.uid]){ (error) in
                        
                        if error != nil {
                            // Show error message
                            self.showError("Error saving user data to db")
                        }
                    }
                    //Transition to home
                    self.globalID = result!.user.uid
                    let logInDic = ["username": self.globalUser, "uid": self.globalID]
                    self.currentUser = FBUser(dictionary: logInDic)
                    self.transitionToHome()
                }
            }
        }
    }
    
    func transitionToHome(){
        
        //let homeViewController = storyboard?.instantiateViewController(identifier: "HomeVC") as? HomeViewController
        //view.window?.rootViewController = homeViewController
        //view.window?.makeKeyAndVisible()
        performSegue(withIdentifier: "SignUpToWelcome", sender: self)
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
            vc4.globalUser = globalUser
            vc4.globalID = globalID
            
        }
    }
    
    func validateFields()->String?{
        //Check that all fields are filled in
        if userNameTextField.text?.trimmingCharacters(in: .whitespacesAndNewlines) == "" ||  emailTextField.text?.trimmingCharacters(in: .whitespacesAndNewlines) == "" || passwordTextField.text?.trimmingCharacters(in: .whitespacesAndNewlines) == "" {
            return "Please fill in all fields"
        }
        let cleanedPassword = passwordTextField.text!.trimmingCharacters(in: .whitespacesAndNewlines)
        if Utilities.isPasswordValid(cleanedPassword) == false {
            return "Please make sure your password is at least 8 characters, contains a special character and a number"
        }
        return nil
    }
    
    func showError(_ message: String){
        errorLabel.text = message
        errorLabel.alpha = 1
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
