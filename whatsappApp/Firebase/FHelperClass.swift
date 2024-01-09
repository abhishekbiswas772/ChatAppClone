//
//  FHelperClass.swift
//  whatsappApp
//
//  Created by Abhishek Biswas on 05/01/24.
//

import Foundation
import FirebaseFirestore

@frozen
enum FUserCollectionReference : String {
    case User
    case Typing
    case Recent
    case Message
    case Group
    case Call
}

class FHelperClass {
    static let shared = FHelperClass()
    
    func reference(_ collectionReference : FUserCollectionReference) -> CollectionReference {
        return Firestore.firestore().collection(collectionReference.rawValue)
    }
    
    func userDictionaryFrom(user: FirebaseUser) -> NSDictionary {
        let createdAt = HelperClass.shared.dateFormatter().string(from: user.createdAt ?? Date())
        let updatedAt = HelperClass.shared.dateFormatter().string(from: user.updatedAt ?? Date())
        return  NSDictionary(objects: [user.objectId ?? "", createdAt, updatedAt, user.email ?? "", user.loginMethod ?? "", user.pushId ?? "", user.firstname ?? "", user.lastname ?? "", user.fullname ?? "", user.avatar ?? "", user.contacts ?? [], user.blockedUsers ?? [], user.isOnline ?? true, user.phoneNumber ?? "", user.countryCode ?? "", user.city ?? "", user.country ?? ""], forKeys: [kOBJECTID as NSCopying, kCREATEDAT as NSCopying, kUPDATEDAT as NSCopying, kEMAIL as NSCopying, kLOGINMETHOD as NSCopying, kPUSHID as NSCopying, kFIRSTNAME as NSCopying, kLASTNAME as NSCopying, kFULLNAME as NSCopying, kAVATAR as NSCopying, kCONTACT as NSCopying, kBLOCKEDUSERID as NSCopying, kISONLINE as NSCopying, kPHONE as NSCopying, kCOUNTRYCODE as NSCopying, kCITY as NSCopying, kCOUNTRY as NSCopying])
    }
    
    func saveUserInFirebase(fUser : FirebaseUser) {
        self.reference(.User).document(fUser.objectId ?? "").setData(userDictionaryFrom(user: fUser) as? [String: Any] ?? [:]) {
            (error) in
            print(error?.localizedDescription as Any)
        }
    }
    
    func saveUserLocally(fUser: FirebaseUser) {
        userDefaults.set(userDictionaryFrom(user: fUser), forKey: kCURRENTUSER)
        userDefaults.synchronize()
    }
    
    func fetchCurrentUserFromFirestore(havingUserId: String) {
        reference(.User).document(havingUserId).getDocument { (snapshort, error) in
            guard let snapshort = snapshort  else {return}
            if snapshort.exists {
                if let snapData = snapshort.data() {
                    userDefaults.set(snapData, forKey: kCURRENTUSER)
                    userDefaults.synchronize()
                }
            }
        }
    }
    
    func fetchCurrentUserFromFirestore(userId: String, compleation: @escaping(_ user: FirebaseUser?) -> Void) {
        reference(.User).document(userId).getDocument { (snapshot, error) in
            guard let snapshot = snapshot else {return}
            if snapshot.exists {
                if let snapData = snapshot.data() {
                    let user = FirebaseUser(_dictionary: snapshot.data() as? NSDictionary ?? NSDictionary())
                    compleation(user)
                }else{
                    compleation(nil)
                }
            }
        }
    }
    
    func getUsersFromFirestore(withIds: [String], completion: @escaping (_ usersArray: [FirebaseUser]) -> Void) {
        var count = 0
        var usersArray: [FirebaseUser] = []
        for userId in withIds {
            
            reference(.User).document(userId).getDocument { (snapshot, error) in
                
                guard let snapshot = snapshot else {  return }
                if snapshot.exists {
                    let user = FirebaseUser(_dictionary: snapshot.data() as? NSDictionary ?? NSDictionary())
                    count += 1
                    if user.objectId != FirebaseUser.currentId() {
                        usersArray.append(user)
                    }

                } else {
                    completion(usersArray)
                }
                
                if count == withIds.count {
                    completion(usersArray)
                }

            }
            
        }
    }


    func updateCurrentUserInFirestore(withValues : [String : Any], completion: @escaping (_ error: Error?) -> Void) {
        
        if let dictionary = UserDefaults.standard.object(forKey: kCURRENTUSER) {
            
            var tempWithValues = withValues
            let currentUserId = FirebaseUser.currentId()
            let updatedAt = HelperClass.shared.dateFormatter().string(from: Date())
            tempWithValues[kUPDATEDAT] = updatedAt
            let userObject = (dictionary as? NSDictionary ?? NSDictionary()).mutableCopy() as? NSMutableDictionary
            userObject?.setValuesForKeys(tempWithValues)
            reference(.User).document(currentUserId).updateData(withValues) { (error) in
                if error != nil {
                    completion(error)
                    return
                }
                userDefaults.setValue(userObject, forKeyPath: kCURRENTUSER)
                userDefaults.synchronize()
                completion(error)
            }

        }
    }
    
    func updateOneSignalId() {
        if FirebaseUser.currentUser() != nil {
            if let pushId = UserDefaults.standard.string(forKey: kPUSHID) {
                setOneSignalId(pushId: pushId)
            } else {
                removeOneSignalId()
            }
        }
    }


    func setOneSignalId(pushId: String) {
        updateCurrentUserOneSignalId(newId: pushId)
    }


    func removeOneSignalId() {
        updateCurrentUserOneSignalId(newId: "")
    }

    func updateCurrentUserOneSignalId(newId: String) {
        updateCurrentUserInFirestore(withValues: [kPUSHID : newId]) { (error) in
            if error != nil {
                print("error updating push id \(error?.localizedDescription ?? "Error in Update")")
            }
        }
    }
}
