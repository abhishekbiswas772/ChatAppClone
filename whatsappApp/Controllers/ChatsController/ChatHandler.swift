//
//  ChatHandler.swift
//  whatsappApp
//
//  Created by Abhishek Biswas on 09/01/24.
//

import Foundation

final class ChatHandler {
    static let shared = ChatHandler()
    
    public func startPrivateChatBtw(withPersonOne: FirebaseUser, toPersonTwo: FirebaseUser) -> String? {
        if let userIdOne = withPersonOne.objectId, let userIdTwo = toPersonTwo.objectId {
            var chatRoomId : String = ""
            let comparedValue = userIdOne.compare(userIdTwo).rawValue
            if comparedValue < 0 {
                chatRoomId = userIdOne + userIdTwo
            }else{
                chatRoomId = userIdTwo + userIdOne
            }
            let members : [String] = [userIdOne, userIdTwo]
            self.createRecentChat(withMembers: members, chatRoomId: chatRoomId, withUserName: "", typeOfChat: kPRIVATE, users: [withPersonOne, toPersonTwo], groupAvatar: nil)
            return chatRoomId
        }
        return nil
    }
    
    public func createRecentChat(withMembers : [String], chatRoomId: String, withUserName: String, typeOfChat: String, users : [FirebaseUser]?, groupAvatar : String?) -> Void {
        var tempMembers : [String] = withMembers
        FHelperClass.shared.reference(.Recent).whereField(kCHATROOMID, isEqualTo: chatRoomId).getDocuments { (snapshot, error) in
            if error != nil {
                
            }else{
                guard let snap = snapshot else {return}
                if !snap.isEmpty {
                    for recentDocs in snap.documents {
                        let currentDocs = recentDocs.data()
                        if let currentUsrId = currentDocs[kUSERID] {
                            if tempMembers.contains(currentUsrId as? String ?? "") {
                                if let tempIdx = tempMembers.firstIndex(of: currentUsrId as? String ?? "") {
                                    tempMembers.remove(at: tempIdx)
                                }
                            }
                        }
                    }
                }
                
                for userId in tempMembers {
                    // create recent item for chat
                    self.createRecentItemForChat(withUserId: userId, chatRoomId: chatRoomId, members: withMembers, withUserName: withUserName, type: typeOfChat, users: users, avaTarGroup: groupAvatar)
                    
                }
            }
        }
    }
    
    private func createRecentItemForChat(withUserId : String, chatRoomId : String, members: [String], withUserName: String, type: String, users : [FirebaseUser]?, avaTarGroup: String?) -> Void {
        let locReference = FHelperClass.shared.reference(.Recent).document()
        let recentDocId = locReference.documentID
        let date = HelperClass.shared.dateFormatter().string(from: Date())
        var recent : [String : Any] = [:]
        if type == kPRIVATE {
            var withUser : FirebaseUser?
            if users != nil && ((users?.isEmpty) != nil) {
                if withUserId == FirebaseUser.currentId() {
                    withUser = users?.last
                }else{
                    withUser = users?.first
                }
            }
            recent = [
                kRECENTID : recentDocId,
                kUSERID : withUserId,
                kCHATROOMID : chatRoomId,
                kMEMBERS : members,
                kMEMBERSTOPUSH : members,
                kWITHUSERFULLNAME : withUser?.firstname ?? "",
                kWITHUSERUSERNAME : withUser?.objectId ?? "",
                kLASTNAME : "",
                kCOUNTER : 0,
                kDATE : date,
                kTYPE : type,
                kAVATAR : withUser?.avatar ?? ""
            ]
        }else{
            if avaTarGroup != nil {
                recent = [
                    kRECENTID : recentDocId,
                    kUSERID : withUserId,
                    kCHATROOMID : chatRoomId,
                    kMEMBERS : members,
                    kMEMBERSTOPUSH : members,
                    kWITHUSERFULLNAME :withUserName ,
                    kLASTNAME : "",
                    kCOUNTER : 0,
                    kDATE : date,
                    kTYPE : type,
                    kAVATAR : avaTarGroup ?? ""
                ]
                
            }
            
        }
        locReference.setData(recent)
    }
}
