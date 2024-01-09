//
//  FUser.swift
//  whatsappApp
//
//  Created by Abhishek Biswas on 05/01/24.
//

import Foundation
import FirebaseAuth
import FirebaseCore
import FirebaseFirestore

class FirebaseUser {
    
    let objectId: String?
    var pushId: String?
    let createdAt: Date?
    var updatedAt: Date?
    var email: String?
    var firstname: String?
    var lastname: String?
    var fullname: String?
    var avatar: String?
    var isOnline: Bool?
    var phoneNumber: String?
    var countryCode: String?
    var country:String?
    var city: String?
    var contacts: [String]?
    var blockedUsers: [String]?
    let loginMethod: String?
    
    
    init(_objectId: String? = "", _pushId: String? = "", _createdAt: Date? = nil, _updatedAt: Date? = nil, _email: String? = "", _firstname: String? = "", _lastname: String? = "", _avatar: String = "", _loginMethod: String? = "", _phoneNumber: String? = "", _city: String? = "", _country: String? = "") {
        
        objectId = _objectId
        pushId = _pushId
        
        createdAt = _createdAt
        updatedAt = _updatedAt
        
        email = _email
        firstname = _firstname
        lastname = _lastname
        fullname = (_firstname ?? "") + " " + (_lastname ?? "")
        avatar = _avatar
        isOnline = true
        
        city = _city
        country = _country
        
        loginMethod = _loginMethod
        phoneNumber = _phoneNumber
        countryCode = ""
        blockedUsers = []
        contacts = []
        
    }
    
    
    
    init(_dictionary: NSDictionary) {
        
        objectId = _dictionary[kOBJECTID] as? String
        pushId = _dictionary[kPUSHID] as? String
        
        if let created = _dictionary[kCREATEDAT] {
            if (created as! String).count != 14 {
                createdAt = Date()
            } else {
                createdAt = HelperClass.shared.dateFormatter().date(from: created as? String ?? "") ?? Date()
            }
        } else {
            createdAt = Date()
        }
        if let updateded = _dictionary[kUPDATEDAT] {
            if (updateded as! String).count != 14 {
                updatedAt = Date()
            } else {
                updatedAt = HelperClass.shared.dateFormatter().date(from: updateded as? String ?? "") ?? Date()
            }
        } else {
            updatedAt = Date()
        }
        
        if let mail = _dictionary[kEMAIL] {
            email = mail as? String
        } else {
            email = ""
        }
        if let fname = _dictionary[kFIRSTNAME] {
            firstname = fname as? String
        } else {
            firstname = ""
        }
        if let lname = _dictionary[kLASTNAME] {
            lastname = lname as? String
        } else {
            lastname = ""
        }
        fullname = (firstname ?? "") + " " + (lastname ?? "")
        if let avat = _dictionary[kAVATAR] {
            avatar = avat as? String
        } else {
            avatar = ""
        }
        if let onl = _dictionary[kISONLINE] {
            isOnline = onl as? Bool
        } else {
            isOnline = false
        }
        if let phone = _dictionary[kPHONE] {
            phoneNumber = phone as? String
        } else {
            phoneNumber = ""
        }
        if let countryC = _dictionary[kCOUNTRYCODE] {
            countryCode = countryC as? String
        } else {
            countryCode = ""
        }
        if let cont = _dictionary[kCONTACT] {
            contacts = cont as? [String]
        } else {
            contacts = []
        }
        if let block = _dictionary[kBLOCKEDUSERID] {
            blockedUsers = block as? [String]
        } else {
            blockedUsers = []
        }
        
        if let lgm = _dictionary[kLOGINMETHOD] {
            loginMethod = lgm as? String
        } else {
            loginMethod = ""
        }
        if let cit = _dictionary[kCITY] {
            city = cit as? String
        } else {
            city = ""
        }
        if let count = _dictionary[kCOUNTRY] {
            country = count as? String
        } else {
            country = ""
        }
        
    }
    
    
    class func loginUser(withEmail: String, withPassword: String, onCompleation: @escaping(_ error : Error?) -> Void) {
        Auth.auth().signIn(withEmail: withEmail, password: withPassword) { (authResult, error) in
            if error != nil {
                onCompleation(error)
                return
            }else{
                FHelperClass.shared.fetchCurrentUserFromFirestore(havingUserId: authResult?.user.uid ?? "")
                onCompleation(error)
            }
        }
    }
    
//    class func registerUserWith(phoneNumber: String, verificationCode: String, verificationID: String, compleation: @escaping(_ error: Error? , _ shouldLogin: Bool) -> Void) {
//        let cred = PhoneAuthProvider.provider().credential(withVerificationID: verificationID, verificationCode: verificationCode)
//        Auth.auth().signIn(with: cred) { (result, error) in
//            if error != nil{
//                compleation(error ?? Error, false)
//                return
//            }else{
//                
//            }
//        }
//    }
    
    class func registerUser(withEmail: String, withPassword: String, withFirstName: String, withLastName: String, withAvatar: String, onCompleation: @escaping(_ error: Error?) -> Void) {
        Auth.auth().createUser(withEmail: withEmail, password: withPassword) { (authResult, error) in
            if error != nil {
                onCompleation(error)
                return
            }else{
                let fUser = FirebaseUser(_objectId: authResult?.user.uid,
                                         _pushId: "",
                                         _createdAt: Date(),
                                         _updatedAt: Date(),
                                         _email: authResult?.user.email,
                                         _firstname: withFirstName,
                                         _lastname: withLastName,
                                         _avatar: withAvatar,
                                         _loginMethod: kEMAIL,
                                         _phoneNumber: "",
                                         _city: "",
                                         _country: ""
                                         
                )
                FHelperClass.shared.saveUserLocally(fUser: fUser)
                FHelperClass.shared.saveUserInFirebase(fUser: fUser)
                onCompleation(error)
            }
        }
    }
    
    class func logoutCurrentUser(compleation: @escaping(_ sucess : Bool) -> Void) {
        userDefaults.removeObject(forKey: kPUSHID)
        userDefaults.removeObject(forKey: kCURRENTUSER)
        userDefaults.synchronize()
        do{
            try Auth.auth().signOut()
            compleation(true)
        }catch let err{
            print(err.localizedDescription)
            compleation(false)
        }
    }
    
    class func deleteUser(compleation: @escaping(_ error : Error?) -> Void) {
        let userCurrent = Auth.auth().currentUser
        userCurrent?.delete(completion: { error in
            compleation(error)
        })
    }
    
    class func currentId() -> String {
        if let currId = Auth.auth().currentUser?.uid {
            return currId
        }
        return ""
    }
    
    class func currentUser() -> FirebaseUser? {
        if Auth.auth().currentUser != nil {
            if let currentDict = userDefaults.object(forKey: kCURRENTUSER) {
                return FirebaseUser.init(_dictionary: currentDict as? NSDictionary ?? NSDictionary())
            }
        }
        return nil
    }
}
