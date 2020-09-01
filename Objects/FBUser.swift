import Firebase

class FBUser {
  var uid: String
  var username: String
  var profilePictureURL: URL?

  init(dictionary: [String: String]) {
    self.uid = dictionary["uid"]!
    self.username = dictionary["username"] ?? ""
  //  guard let profile_picture = dictionary["profile_picture"],
  //    let profilePictureURL = URL(string: profile_picture) else { return }
  //  self.profilePictureURL = profilePictureURL
  }

  private init(user: User) {
    self.uid = user.uid
    self.username = user.displayName ?? ""
    self.profilePictureURL = user.photoURL
  }
    
    private init(username: String, uid: String){
        self.uid = uid
        self.username = username
    }

  static func currentUser() -> FBUser {
    return FBUser(user: Auth.auth().currentUser!)
  }

  func author() -> [String: String] {
    return ["uid": uid, "username": username, "profile_picture": profilePictureURL?.absoluteString ?? ""]
  }
}

extension FBUser: Equatable {
  static func ==(lhs: FBUser, rhs: FBUser) -> Bool {
    return lhs.uid == rhs.uid
  }
  static func ==(lhs: FBUser, rhs: User) -> Bool {
    return lhs.uid == rhs.uid
  }
}
