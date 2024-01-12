//
//  ChatUIHandler.swift
//  whatsappApp
//
//  Created by Abhishek Biswas on 10/01/24.
//

import Foundation
import FirebaseFirestore


class ChatUIOutgoingHandler {
    
    var message: NSMutableDictionary
    
    init(messageContent: String, senderId: String, senderName: String, date: Date, status: String, type: String) {
        let dateString = HelperClass.shared.dateFormatter().string(from: date)
        
        message = NSMutableDictionary(dictionary: [
            kMESSAGE: messageContent,
            kSENDERID: senderId,
            kSENDERNAME: senderName,
            kDATE: dateString,
            kSTATUS: status,
            kTYPE: type
        ])
    }
    
    init(messageContent: String, pictureLink : String, senderId: String, senderName: String, date: Date, status: String, type: String) {
        let dateString = HelperClass.shared.dateFormatter().string(from: date)
        message = NSMutableDictionary(dictionary: [
            kMESSAGE: messageContent,
            kPICTURE : pictureLink,
            kSENDERID: senderId,
            kSENDERNAME: senderName,
            kDATE: dateString,
            kSTATUS: status,
            kTYPE: type
        ])
    }
    
    
    init(messageContent: String, videoLink : String, thumbnail: NSData, senderId: String, senderName: String, date: Date, status: String, type: String) {
        let dateString = HelperClass.shared.dateFormatter().string(from: date)
        let createThumbNail = thumbnail.base64EncodedString(options: NSData.Base64EncodingOptions(rawValue: 0))
        message = NSMutableDictionary(dictionary: [
            kMESSAGE: messageContent,
            kVIDEO : videoLink,
            kTHUMBNAIL : thumbnail,
            kSENDERID: senderId,
            kSENDERNAME: senderName,
            kDATE: dateString,
            kSTATUS: status,
            kTYPE: type
        ])
    }
    
    init(messageContent: String, audioLink : String, senderId: String, senderName: String, date: Date, status: String, type: String) {
        let dateString = HelperClass.shared.dateFormatter().string(from: date)
        message = NSMutableDictionary(dictionary: [
            kMESSAGE: messageContent,
            kAUDIO : audioLink,
            kSENDERID: senderId,
            kSENDERNAME: senderName,
            kDATE: dateString,
            kSTATUS: status,
            kTYPE: type
        ])
    }
     
    
    
    public func sendMessage(withChatRoomID: String, message : NSMutableDictionary, memberIds: [String], memberToPush: [String]) {
        let messageId = UUID().uuidString
        self.message[kMESSAGEID] = messageId
        for memberId in memberIds {
            FHelperClass.shared.reference(.Message).document(memberId).collection(withChatRoomID).document(messageId).setData(message as? [String : Any] ?? [:])
        }
        // update the chat &&
        // create push notification
        
    }
    
     
}
