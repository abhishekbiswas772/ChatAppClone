//
//  ChatUIIncomingHandler.swift
//  whatsappApp
//
//  Created by Abhishek Biswas on 10/01/24.
//

import Foundation
import JSQMessagesViewController


class ChatUIIncomingHandler {
    var collectionView : JSQMessagesCollectionView
    init(_collectionView: JSQMessagesCollectionView) {
        self.collectionView = _collectionView
    }
    
    public func createMessage(withMessage : NSDictionary, havingChatRoomId: String) -> JSQMessage? {
        var message : JSQMessage?
        if let typeOfMessage = withMessage[kTYPE] as? String {
            switch typeOfMessage {
            case kTEXT:
                message = self.createMessageWithTxt(withMessage: withMessage, withChatRoomID: havingChatRoomId)
                break
            case kPICTURE:
                message = self.createPicMessage(withMessage: withMessage)
                break
            case kVIDEO:
                message = self.createVideoMessage(withMessage: withMessage)
                break
            case kLOCATION:
                break
            case kAUDIO:
                break
            default:
                print("Unknown Message Type!!")
                break
            }
            
            if message != nil {
                return message
            }
        }
        return nil
    }
    
    private func createPicMessage(withMessage: NSDictionary) -> JSQMessage {
        let name = withMessage[kSENDERNAME] as? String ?? ""
        let usrId = withMessage[kSENDERID] as? String ?? ""
        var date : Date?
        if let created = withMessage[kDATE] as? String {
            if created.count != 14 {
                date = Date()
            }else{
                date = HelperClass.shared.dateFormatter().date(from: created)
            }
        }else{
            date = Date()
        }
        let mediaItem = PhotoMediaItem(image: nil)
        mediaItem?.appliesMediaViewMaskAsOutgoing = self.isMessageInCommingOrOutGoing(senderId: usrId)
        DownloadHelper.shared.downloadImage(withImageUrl: withMessage[kPICTURE] as? String ?? "") { image in
            if image != nil {
                mediaItem?.image = image
                self.collectionView.reloadData()
            }
        }
        return JSQMessage(senderId: usrId, senderDisplayName: name, date: date, media: mediaItem)
        
    }
    
    private func isMessageInCommingOrOutGoing(senderId: String) -> Bool {
        if FirebaseUser.currentId() != "" {
            if senderId == FirebaseUser.currentId() {
                return true
            }else{
                return false
            }
        }else{
            return false
        }
    }
    
    private func createVideoMessage(withMessage: NSDictionary) -> JSQMessage {
        let name = withMessage[kSENDERNAME] as? String ?? ""
        let usrId = withMessage[kSENDERID] as? String ?? ""
        var date : Date?
        if let created = withMessage[kDATE] as? String {
            if created.count != 14 {
                date = Date()
            }else{
                date = HelperClass.shared.dateFormatter().date(from: created)
            }
        }else{
            date = Date()
        }
        let videoUrl = NSURL(fileURLWithPath: withMessage[kVIDEO] as? String ?? "")
        let mediaItem = VideoMessge(withFileURl: videoUrl, maskOutgoing: self.isMessageInCommingOrOutGoing(senderId: usrId))
        DownloadHelper.shared.downloadVideo(withVideoLink: (withMessage[kVIDEO] as? String) ?? "") { (isReadyToPlay, videoFileName) in
            guard let fileURL = DownloadHelper.shared.fileInFileDIR(withFileName: videoFileName) else {return}
            let url = NSURL(fileURLWithPath: fileURL)
            mediaItem.status = kSUCCESS
            mediaItem.fileURl = url
            HelperClass.shared.imageFromData(withData: (withMessage[kPICTURE] as? String) ?? "") { image in
                guard let image = image else {return}
                mediaItem.videoImage = image
                DispatchQueue.main.async {
                    self.collectionView.reloadData()
                }
            }
            DispatchQueue.main.async {
                self.collectionView.reloadData()
            }
            
        }
        return JSQMessage(senderId: usrId, senderDisplayName: name, date: date, media: mediaItem)
    }
    
    private func createMessageWithTxt(withMessage: NSDictionary, withChatRoomID: String) -> JSQMessage {
        let name = withMessage[kSENDERNAME] as? String ?? ""
        let usrId = withMessage[kSENDERID] as? String ?? ""
        var date : Date?
        if let created = withMessage[kDATE] as? String {
            if created.count != 14 {
                date = Date()
            }else{
                date = HelperClass.shared.dateFormatter().date(from: created)
            }
        }else{
            date = Date()
        }
        let messageTxt = withMessage[kMESSAGE] as? String ?? ""
        return JSQMessage(senderId: usrId, senderDisplayName: name, date: date, text: messageTxt)
    }
}
