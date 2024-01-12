//
//  ChatViewController.swift
//  whatsappApp
//
//  Created by Abhishek Biswas on 10/01/24.
//

import Foundation
import UIKit
import JSQMessagesViewController
import ProgressHUD
import IQAudioRecorderController
import IDMPhotoBrowser
import AVFoundation
import AVKit
import FirebaseFirestore


class ChatViewController : JSQMessagesViewController {
    
    private var outgoingMessageBubble = JSQMessagesBubbleImageFactory().outgoingMessagesBubbleImage(with: UIColor.jsq_messageBubbleBlue())
    private var incommingMessageBubble = JSQMessagesBubbleImageFactory().incomingMessagesBubbleImage(with: UIColor.jsq_messageBubbleLightGray())
    public var chatRoomId : String?
    public var memberId : [String] = []
    public var memberIdToPush : [String] = []
    public var chatTitle : String?
    private var legitType : [String] = [kTEXT, kVIDEO, kVIDEO, kLOCATION, kPICTURE]
    public var isGroup : Bool?
    public var group : NSDictionary?
    public var withUsers : [FirebaseUser] = []
    
    private var jsqMessageArray : [JSQMessage] = []
    private var objectMessage : [NSDictionary] = []
    private var loadedMessage : [NSDictionary] = []
    private var allPicture : [String] = []
    private var initLaodComplete : Bool = false
    private lazy var leftBarButtonView: UIView = {
        
        let view = UIView(frame: CGRect(x: 0, y: 0, width: 200, height: 44))
        return view
    }()
    private lazy var avatarButton: UIButton = {
        let button = UIButton(frame: CGRect(x: 0, y: 10, width: 30, height: 30))
        return button
    }()
    private lazy var titleLabel: UILabel = {
        let title = UILabel(frame: CGRect(x: 40, y: 10, width: 140, height: 15))
        title.textAlignment = .left
        title.font = UIFont.systemFont(ofSize: 16)
        
        return title
    }()
    private lazy var subTitleLabel: UILabel = {
        let subTitle = UILabel(frame: CGRect(x: 40, y: 25, width: 140, height: 15))
        subTitle.textAlignment = .left
        subTitle.font = UIFont.systemFont(ofSize: 12)
        return subTitle
    }()
    
    
    // For old message
    private var maxMessageCount : Int = 0
    private var minMessageCount : Int = 0
    private var laodAll : Bool = false
    private var loadMessageCount : Int = 0
    
    //listener For newChat
    private var newChatListener : ListenerRegistration?
    private var typingListener : ListenerRegistration?
    private var updateListener : ListenerRegistration?
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.prepareForChatControllerView()
        self.prepareForCustomTitle()
        self.loadMessageFromFirebase()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        perform(Selector(("jsq_updateCollectionViewInsets")))
    }
    
    public func prepareForCustomTitle() {
        leftBarButtonView.addSubview(avatarButton)
        leftBarButtonView.addSubview(titleLabel)
        leftBarButtonView.addSubview(subTitleLabel)
        
        let infoButton = UIBarButtonItem(image: UIImage(named: "info"), style: .plain, target: self, action: #selector(self.infoBtn))
        self.navigationItem.rightBarButtonItem = infoButton
        
        
        let leftBarButtonItem = UIBarButtonItem(customView: leftBarButtonView)
        self.navigationItem.leftBarButtonItems?.append(leftBarButtonItem)
        guard let isGrp = self.isGroup else {return}
        if isGrp {
            avatarButton.addTarget(self, action: #selector(self.showGroup), for: .touchUpInside)
        }else{
            avatarButton.addTarget(self, action: #selector(self.showUserProfile), for: .touchUpInside)
        }
        FHelperClass.shared.getUsersFromFirestore(withIds: self.memberId) { usersArray in
            self.withUsers = usersArray
            guard let isGrp = self.isGroup else {return}
            if !isGrp {
                self.setUIForSingleChat()
            }
        }
    }
    
    private func setUIForSingleChat() {
        if let withUser = self.withUsers.first {
            HelperClass.shared.imageFromData(withData: withUser.avatar ?? "") { image in
                if let image = image {
                    DispatchQueue.main.async {
                        self.avatarButton.setImage(image.circleMasked, for: .normal)
                        self.titleLabel.text = withUser.fullname
                        guard let online = withUser.isOnline else {return}
                        if online {
                            self.subTitleLabel.text = "Online"
                        } else {
                            self.subTitleLabel.text = "Offline"
                        }
                        self.avatarButton.addTarget(self, action: #selector(self.showUserProfile), for: .touchUpInside)
                    }
                }
            }
        }
    }
    
    @objc func showGroup() {
        
    }
    
    @objc func showUserProfile(){
        let profileVC = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "ProfileViewController") as? ProfileViewController
        if let firstUser = self.withUsers.first {
            profileVC?.fUser = firstUser
        }
        DispatchQueue.main.async {
            self.navigationController?.pushViewController(profileVC ?? UIViewController(), animated: true)
        }
    }
    
    @objc func infoBtn() {
        print("show image message")
    }
    
    //load message
    private func loadMessageFromFirebase() {
        if FirebaseUser.currentId() != "" {
            FHelperClass.shared.reference(.Message).document(FirebaseUser.currentId()).collection(self.chatRoomId ?? "").order(by: kDATE, descending: true).limit(to: 11).getDocuments { (snapshot, error) in
                if error != nil {
                    DispatchQueue.main.async {
                        debugPrint(error?.localizedDescription as Any)
                        ProgressHUD.error("Error in loading chat")
                        return
                    }
                }else{
                    guard let snap = snapshot else {
                        self.initLaodComplete = true
                        return
                    }
                    let sortedSnap = ((HelperClass.shared.dictFromSnapShot(snapShot: snap.documents)) as NSArray).sortedArray(using: [NSSortDescriptor(key: kDATE, ascending: true)]) as? [NSDictionary]
                    guard let sortedSnap = sortedSnap else {return}
                    self.loadedMessage = self.removeAnyBadMessage(allMessage: sortedSnap)
                    self.insertAllJSQMessage()
                    self.finishReceivingMessage(animated: true)
                    self.initLaodComplete = true
                    self.getAllOldMessageFromFirebaseInBackGround()
                    self.listenForNewMessagesFromFirebase()
                    
                }
            }
        }
    }
    
    private func listenForNewMessagesFromFirebase() {
        var lastMessageDate = "0"
        if self.loadedMessage.count > 0 {
            if let lastObj = self.loadedMessage.last {
                lastMessageDate = lastObj[kDATE] as? String ?? ""
            }
        }
        if FirebaseUser.currentId() != "" {
            if let chatRoomID = self.chatRoomId {
                self.newChatListener = FHelperClass.shared.reference(.Message).document(FirebaseUser.currentId()).collection(chatRoomID).whereField(kDATE, isGreaterThan: lastMessageDate).addSnapshotListener({ (snapShot, error) in
                    if error != nil {
                        DispatchQueue.main.async {
                            ProgressHUD.error("Error in Getting new Message")
                        }
                        return
                    } else {
                        guard let snap = snapShot else { return }
                        
                        for snapDict in snap.documentChanges {
                            if snapDict.type == .added {
                                let item = snapDict.document.data() as NSDictionary
                                if let type = item[kTYPE] as? String {
                                    if self.legitType.contains(type) {
                                        if type == kPICTURE {
                                            // Handle picture type
                                        }

                                        if self.insertInitJSQMessage(withMesssage: item) {
                                            JSQSystemSoundPlayer.jsq_playMessageReceivedSound()
                                        }
                                        self.finishReceivingMessage(animated: true)
                                    }
                                }
                            }
                        }
                    }
                })
            }
        }
    }

    
    private func insertAllJSQMessage() {
        self.maxMessageCount = self.loadedMessage.count - self.loadMessageCount
        self.minMessageCount = self.maxMessageCount - kNUMBEROFMESSAGES
        if self.minMessageCount < 0 {
            self.minMessageCount = 0
        }
        for num in self.minMessageCount..<self.maxMessageCount {
            let messageDict = self.loadedMessage[num]
            self.insertInitJSQMessage(withMesssage: messageDict)
            self.loadMessageCount += 1
            
        }
        self.showLoadEarlierMessagesHeader = (loadMessageCount != loadedMessage.count)
    }
    
    private func insertInitJSQMessage(withMesssage : NSDictionary) -> Bool {
        let incommingMessage = ChatUIIncomingHandler(_collectionView: self.collectionView)
        if let senderId = withMesssage[kSENDERID] as? String {
            if (FirebaseUser.currentId() != ""){
                if senderId != FirebaseUser.currentId() {
                    
                }
    
                let incommingMsg = incommingMessage.createMessage(withMessage: withMesssage, havingChatRoomId: self.chatRoomId ?? "")
                if incommingMsg != nil {
                    self.objectMessage.append(withMesssage)
                    if let iMsg = incommingMsg {
                        self.jsqMessageArray.append(iMsg)
                    }
                }
            }
        }
        return self.isIncommingMessageOrOutGoingMessage(havingMessage: withMesssage)
    }
    
    
    private func isIncommingMessageOrOutGoingMessage(havingMessage message : NSDictionary) -> Bool {
        if FirebaseUser.currentId() != "" {
            guard let senderId =  message[kSENDERID] as? String else {return false}
            if  FirebaseUser.currentId() == senderId {
                return false
            }else{
                return true
            }
        }
        return false
    }
    
    private func removeAnyBadMessage(allMessage : [NSDictionary]) -> [NSDictionary] {
        var tempMessage : [NSDictionary] = allMessage
        for message in tempMessage {
            if message[kTYPE] != nil {
                if !self.legitType.contains(message[kTYPE] as? String ?? "") {
                    if let idx = tempMessage.firstIndex(of: message) {
                        tempMessage.remove(at: idx)
                    }
                }
            }else{
                if let idx = tempMessage.firstIndex(of: message) {
                    tempMessage.remove(at: idx)
                }
            }
        }
        return tempMessage
    }
    
    private func prepareForChatControllerView() {
        self.navigationItem.largeTitleDisplayMode = .never
        self.navigationItem.leftBarButtonItems = [
            UIBarButtonItem(image: UIImage.init(named: "Back"), style: .plain, target: self, action: #selector(barButtonAction(_ :)))
        ]
        collectionView.collectionViewLayout.incomingAvatarViewSize = CGSize.zero
        collectionView.collectionViewLayout.outgoingAvatarViewSize = CGSize.zero
        if FirebaseUser.currentId() != "", let fullName = FirebaseUser.currentUser()?.fullname {
            self.senderId = FirebaseUser.currentId()
            self.senderDisplayName = fullName
        }
        // fixing the screen for iPhoneX and later
        let constraint = perform(Selector(("toolbarBottomLayoutGuide"))).takeUnretainedValue() as? NSLayoutConstraint
        constraint?.priority = UILayoutPriority(rawValue: 999)
        self.inputToolbar.bottomAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.bottomAnchor).isActive = true
        self.inputToolbar.contentView.rightBarButtonItem.setImage(UIImage.init(named: "mic"), for: .normal)
        self.inputToolbar.contentView.rightBarButtonItem.setTitle("", for: .normal)
    }
    
    override func didPressAccessoryButton(_ sender: UIButton!) {
        let cameraObj : CameraHelper = CameraHelper(_delegate: self)
        let alert : UIAlertController = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        let camera = UIAlertAction(title: "Camera", style: .default, handler: { (action) in
            cameraObj.PresentMultyCamera(target: self, canEdit: false)
        })
        let photo = UIAlertAction(title: "Photo Library", style: .default, handler: { (action) in
            cameraObj.presentPhotoLib(usingTheViewController: self, andItsEditable: false)
        })
        let video = UIAlertAction(title: "Video Library", style: .default, handler: { (action) in
            cameraObj.presentPhotoLib(usingTheViewController: self, andItsEditable: false)
        })
        let location = UIAlertAction(title: "Share Location", style: .default, handler: { (action) in
            
        })
        let cancel = UIAlertAction(title: "Cancel", style: .cancel, handler: { (action) in
            
        })
        camera.setValue(UIImage.init(named: "camera"), forKey: "image")
        photo.setValue(UIImage.init(named: "picture"), forKey: "image")
        video.setValue(UIImage.init(named: "video"), forKey: "image")
        location.setValue(UIImage.init(named: "location"), forKey: "image")
        alert.addAction(camera)
        alert.addAction(photo)
        alert.addAction(video)
        alert.addAction(location)
        alert.addAction(cancel)
        self.present(alert, animated: true, completion: nil)
    }
    
    override func didPressSend(_ button: UIButton!, withMessageText text: String!, senderId: String!, senderDisplayName: String!, date: Date!) {
        if !text.isEmpty {
            guard let text = text else {return}
            self.prepareForUpdateSendBtn(isMessageSended : false)
            self.sendMessageAndShowMessageInView(withContainText: text, date: date, picture: nil, location: nil, video: nil, audio: nil)
        }else{
            debugPrint("This is an Audio Message")
        }
    }
    
    private func loadMoreEarlierMessage(maxNumber: Int, minNumber : Int) {
        if laodAll {
            self.maxMessageCount = minNumber - 1
            self.minMessageCount = self.maxMessageCount - kNUMBEROFMESSAGES
        }else {
            if self.minMessageCount < 0 {
                self.minMessageCount = 0
            }
            for numCount in (self.minMessageCount ... self.maxMessageCount).reversed() {
                let messageDict = self.loadedMessage[numCount]
                self.insertNewMessagesForEarlier(withMesssage: messageDict)
                self.loadMessageCount += 1
            }
            self.laodAll = true
            self.showLoadEarlierMessagesHeader = (self.loadedMessage.count != self.loadMessageCount)
        }
    }
    
    private func insertNewMessagesForEarlier(withMesssage: NSDictionary) {
        let incommingMessage : ChatUIIncomingHandler = ChatUIIncomingHandler.init(_collectionView: self.collectionView)
        let message = incommingMessage.createMessage(withMessage: withMesssage, havingChatRoomId: self.chatRoomId ?? "")
        self.objectMessage.insert(withMesssage, at: 0)
        if let jmessage = message {
            self.jsqMessageArray.insert(jmessage, at: 0)
        }
    }
    
    override func collectionView(_ collectionView: JSQMessagesCollectionView!, header headerView: JSQMessagesLoadEarlierHeaderView!, didTapLoadEarlierMessagesButton sender: UIButton!) {
        self.loadMoreEarlierMessage(maxNumber: self.maxMessageCount, minNumber: self.minMessageCount)
        DispatchQueue.main.async {
            self.collectionView.reloadData()
        }
    }
    
    
    private func prepareForUpdateSendBtn(isMessageSended : Bool){
        if isMessageSended {
            self.inputToolbar.contentView.rightBarButtonItem.setImage(UIImage.init(named: "send"), for: .normal)
        }else{
            self.inputToolbar.contentView.rightBarButtonItem.setImage(UIImage.init(named: "mic"), for: .normal)
        }
    }
    
    override func textViewDidChange(_ textView: UITextView) {
        if !textView.text.isEmpty {
            self.prepareForUpdateSendBtn(isMessageSended: true)
        } else {
            self.prepareForUpdateSendBtn(isMessageSended: false)
        }
    }
    
    
    private func sendMessageAndShowMessageInView(withContainText: String?, date: Date, picture: UIImage?, location: String?, video: NSURL?, audio: String?) {
        var outgoingMessage : ChatUIOutgoingHandler?
        if let user = FirebaseUser.currentUser() {
            let currentUser = user
            if let text = withContainText {
                outgoingMessage = ChatUIOutgoingHandler(messageContent: text, senderId: currentUser.objectId ?? "", senderName: currentUser.firstname ?? "", date: date, status: kDELIVERED, type: kTEXT)
                JSQSystemSoundPlayer.jsq_playMessageSentSound()
                self.finishSendingMessage()
                outgoingMessage?.sendMessage(withChatRoomID: self.chatRoomId ?? "", message: outgoingMessage?.message ?? [:], memberIds: self.memberId, memberToPush: self.memberIdToPush)
            }
            
            if let pic = picture {
                guard let chatRoomID = self.chatRoomId else {return}
                guard let selfView = self.navigationController?.view else {return}
                DownloadHelper.shared.uploadImage(withImage: pic, onChatRoomID: chatRoomID, whichView: selfView) { imageLink in
                    if (imageLink != nil) && (FirebaseUser.currentId() != "") {
                        let text = "[\(kPICTURE)]"
                        outgoingMessage = ChatUIOutgoingHandler(messageContent: text, pictureLink: imageLink ?? "", senderId: currentUser.objectId ?? "", senderName: currentUser.firstname ?? "", date: date, status: kDELIVERED, type: kPICTURE)
                        JSQSystemSoundPlayer.jsq_playMessageSentSound()
                        self.finishSendingMessage()
                        outgoingMessage?.sendMessage(withChatRoomID: self.chatRoomId ?? "", message: outgoingMessage?.message ?? [:], memberIds: self.memberId, memberToPush: self.memberIdToPush)
                    }
                }
                return
            }
            
            
            if let video = video {
                guard let chatRoomID = self.chatRoomId else {return}
                guard let selfView = self.navigationController?.view else {return}
                guard let videoContent = video.path else {return}
                let videoData = NSData(contentsOfFile: videoContent) ?? NSData()
                let videoThumbnail = DownloadHelper.shared.getVideoThumbnail(withVideo: video)
                let dataThumbnail = videoThumbnail.jpegData(compressionQuality: 0.3)
                DownloadHelper.shared.uploadVideo(withVideo: videoData, havingChatRoomID: chatRoomID, view: selfView) { videoLink in
                    if (videoLink != nil) && (FirebaseUser.currentId() != "") {
                        let text = "[\(kVIDEO)]"
                        outgoingMessage = ChatUIOutgoingHandler(messageContent: text, videoLink: videoLink ?? "", thumbnail: dataThumbnail as? NSData ?? NSData(), senderId: currentUser.objectId ?? "", senderName: currentUser.firstname ?? "", date: date, status: kDELIVERED, type: kPICTURE)
                        JSQSystemSoundPlayer.jsq_playMessageSentSound()
                        self.finishSendingMessage()
                        outgoingMessage?.sendMessage(withChatRoomID: self.chatRoomId ?? "", message: outgoingMessage?.message ?? [:], memberIds: self.memberId, memberToPush: self.memberIdToPush)
                    }
                }
                return
            }
            
        }
    }
    
    
    
    @objc func barButtonAction(_ sender : UIBarButtonItem){
        self.navigationController?.popViewController(animated: true)
    }
    
}


extension ChatViewController {
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = super.collectionView(collectionView, cellForItemAt: indexPath) as? JSQMessagesCollectionViewCell
        let data = self.jsqMessageArray[indexPath.row]
        if FirebaseUser.currentId() != "" {
            if data.senderId == FirebaseUser.currentId(){
                cell?.textView?.textColor = .white
            }else{
                cell?.textView?.textColor = .black
            }
        }
        return cell ?? JSQMessagesCollectionViewCell()
    }
    
    
    override func collectionView(_ collectionView: JSQMessagesCollectionView!, messageDataForItemAt indexPath: IndexPath!) -> JSQMessageData! {
        return self.jsqMessageArray[indexPath.row]
    }
    
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.jsqMessageArray.count
    }
    
    override func collectionView(_ collectionView: JSQMessagesCollectionView!, messageBubbleImageDataForItemAt indexPath: IndexPath!) -> JSQMessageBubbleImageDataSource! {
        let data = self.jsqMessageArray[indexPath.row]
        if FirebaseUser.currentId() != "" {
            if data.senderId == FirebaseUser.currentId() {
                return self.outgoingMessageBubble
            }else{
                return self.incommingMessageBubble
            }
        }
        return self.outgoingMessageBubble
    }
}


extension ChatViewController {
    override func collectionView(_ collectionView: JSQMessagesCollectionView!, attributedTextForCellTopLabelAt indexPath: IndexPath!) -> NSAttributedString! {
        if indexPath.item % 3 == 0 {
            let message = self.jsqMessageArray[indexPath.row]
            return JSQMessagesTimestampFormatter().attributedTimestamp(for: message.date)
        }else{
            return nil
        }
    }
    
    override func collectionView(_ collectionView: JSQMessagesCollectionView!, layout collectionViewLayout: JSQMessagesCollectionViewFlowLayout!, heightForCellTopLabelAt indexPath: IndexPath!) -> CGFloat {
        if indexPath.item % 3 == 0 {
            return kJSQMessagesCollectionViewCellLabelHeightDefault
        }
        return 0.0
    }
    
    
    override func collectionView(_ collectionView: JSQMessagesCollectionView!, attributedTextForCellBottomLabelAt indexPath: IndexPath!) -> NSAttributedString! {
        let message = self.objectMessage[indexPath.row]
        var status : NSAttributedString?
        let attributedStringColor = [NSAttributedString.Key.foregroundColor : UIColor.darkGray]
        guard let messageStatus = message[kSTATUS] as? String else {
            return NSAttributedString(string: "")
        }
        switch messageStatus {
        case kDELIVERED:
            status = NSAttributedString(string: kDELIVERED)
            break
        case kREAD:
            let statusRead = "Read" + " " + HelperClass.shared.readTimeFrom(theDateString: (message[kREADDATE] as? String) ?? "")
            status = NSAttributedString(string: statusRead, attributes: attributedStringColor)
        default:
            status = NSAttributedString(string: "✅")
        }
        if indexPath.row == (self.jsqMessageArray.count - 1) {
            return status
        }else {
            return NSAttributedString(string: "")
        }
    }
    
    override func collectionView(_ collectionView: JSQMessagesCollectionView!, layout collectionViewLayout: JSQMessagesCollectionViewFlowLayout!, heightForCellBottomLabelAt indexPath: IndexPath!) -> CGFloat {
        let data = self.jsqMessageArray[indexPath.row]
        if FirebaseUser.currentId() != ""{
            if data.senderId == FirebaseUser.currentId() {
                return kJSQMessagesCollectionViewCellLabelHeightDefault
            }else{
                return 0.0
            }
        }
        return 0.0
    }
}



extension ChatViewController {
    private func getAllOldMessageFromFirebaseInBackGround() {
        DispatchQueue.global(qos: .background).async {
            if self.loadedMessage.count > 10 {
                if let firstObject = self.loadedMessage.first {
                    if let currentDate = firstObject[kDATE] as? String {
                        if FirebaseUser.currentId() != "", let chatRoomID = self.chatRoomId {
                            FHelperClass.shared.reference(.Message).document(FirebaseUser.currentId()).collection(chatRoomID).whereField(kDATE, isLessThan: currentDate).getDocuments { (snapshot, snapError) in
                                if snapError != nil {
                                    DispatchQueue.main.async {
                                        ProgressHUD.error("Error in loading Earlier Message")
                                    }
                                    return
                                }else{
                                    guard let snap = snapshot else {return}
                                    let sortedArray = ((HelperClass.shared.dictFromSnapShot(snapShot: snap.documents)) as NSArray).sortedArray(using: [NSSortDescriptor(key: kDATE, ascending: true)]) as? [NSDictionary]
                                    self.loadedMessage = self.removeAnyBadMessage(allMessage: sortedArray ?? []) + self.loadedMessage
                                    self.maxMessageCount = self.loadedMessage.count - self.loadMessageCount - 1
                                    self.minMessageCount = self.maxMessageCount - kNUMBEROFMESSAGES
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}


extension ChatViewController : UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        let video = info[UIImagePickerController.InfoKey.mediaURL] as? NSURL
        let picture = info[UIImagePickerController.InfoKey.originalImage] as? UIImage
        self.sendMessageAndShowMessageInView(withContainText: nil, date: Date(), picture: picture, location: nil, video: video, audio: nil)
        picker.dismiss(animated: true, completion: nil)
    }
    
    
    override func collectionView(_ collectionView: JSQMessagesCollectionView!, didTapMessageBubbleAt indexPath: IndexPath!) {
        let messageDict = self.objectMessage[indexPath.row]
        let messageType = (messageDict[kTYPE] as? String ) ?? ""
        switch messageType {
        case kPICTURE:
            DispatchQueue.main.async {
                let message = self.jsqMessageArray[indexPath.row]
                guard let mediaItem = message.media as? JSQPhotoMediaItem, let image = mediaItem.image else { return }
                if !image.size.equalTo(.zero) {
                    let photos = IDMPhoto.photos(withImages: [image])
                    let brower = IDMPhotoBrowser(photos: photos)
                    if let bVC = brower {
                        self.present(bVC, animated: true, completion: nil)
                    }
                }
            }
            break
        case kVIDEO:
            let message = self.jsqMessageArray[indexPath.row]
            guard let mediaItem = message.media as? VideoMessge else {return}
            guard let fileUrl = mediaItem.fileURl as? URL else {return}
            let player : AVPlayer = AVPlayer(url: fileUrl)
            let moviePlayer = AVPlayerViewController()
            let session = AVAudioSession.sharedInstance()
            do{
                try session.setCategory(.playAndRecord, mode: .default, options: .defaultToSpeaker)
                moviePlayer.player = player
                self.present(moviePlayer, animated: true) {
                    moviePlayer.player?.play()
                }
            }catch{
                ProgressHUD.error("Error in Playing Video")
                return
            }
            break
        case kLOCATION:
            break
        default:
            debugPrint("Unknown Message Tapped")
            break
        }
    }
}
