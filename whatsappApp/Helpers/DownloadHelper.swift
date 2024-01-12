//
//  DownloadHelper.swift
//  whatsappApp
//
//  Created by Abhishek Biswas on 12/01/24.
//

import Foundation
import FirebaseStorage
import Firebase
import MBProgressHUD
import AVFoundation
import ProgressHUD

class DownloadHelper {
    static let shared = DownloadHelper()
    private let storage = Storage.storage()
    
    public func uploadVideo(withVideo: NSData, havingChatRoomID: String, view: UIView, onCompletion: @escaping(_ videoLink: String?) -> Void) {
        let progessHud = MBProgressHUD.showAdded(to: view, animated: true)
        progessHud.mode = .determinateHorizontalBar
        let dateString = HelperClass.shared.dateFormatter().string(from: Date())
        if FirebaseUser.currentId() != "" {
            let videoFileName = "VideoMessage/\(FirebaseUser.currentId())/\(havingChatRoomID)/\(dateString).mov"
            let refStorage = storage.reference(forURL: kFILEREFERENCE).child(videoFileName)
            var task : StorageUploadTask?
            task = refStorage.putData(withVideo as Data, metadata: nil, completion: { (metaData, error) in
                task?.removeAllObservers()
                progessHud.hide(animated: true)
                if error != nil {
                    print(error?.localizedDescription as Any)
                    return
                }else{
                    refStorage.downloadURL { (url , error) in
                        if error != nil {
                            print(error?.localizedDescription as Any)
                            onCompletion(nil)
                            return
                        }else{
                            guard let url = url else {return}
                            onCompletion(url.absoluteString)
                        }
                    }
                }
            })
            task?.observe(StorageTaskStatus.progress, handler: { snap in
                if let unitCount = snap.progress?.completedUnitCount, let totalUnitCount = snap.progress?.totalUnitCount {
                    progessHud.progress = Float((unitCount))/Float(totalUnitCount)
                }
            })
        }
    }
    
    public func getVideoThumbnail(withVideo: NSURL) -> UIImage {
        let asset = AVURLAsset(url: withVideo as URL, options: nil)
        let imageGenerator = AVAssetImageGenerator(asset: asset)
        imageGenerator.appliesPreferredTrackTransform = true
        let time = CMTime(seconds: 0.5, preferredTimescale: 1000)
        var actualTime = CMTime.zero
        var image: CGImage?
        do {
            image = try imageGenerator.copyCGImage(at: time, actualTime: &actualTime)
        }
        catch let error as NSError {
            print(error.localizedDescription)
        }
        let thumbnail = UIImage(cgImage: image!)
        return thumbnail
    }
    
    public func downloadVideo(withVideoLink: String, callBackDownload: @escaping(_ isReadyToPlay: Bool, _ videoFileName: String) -> Void) {
        guard let videoUrl = URL(string: withVideoLink) else {
            return
        }

        let videoFileName = videoUrl.lastPathComponent
        if let components = videoFileName.components(separatedBy: "%").last?.components(separatedBy: "?").first {
            if checkFileExists(withFileName: components){
                callBackDownload(true, videoFileName)
            }else{
                let downloadQueue = DispatchQueue(label: "VideoDownloadQueue")
                downloadQueue.async {
                    let data = NSData(contentsOf: videoUrl)
                    if data != nil {
                        if var docUrl = self.getDocsUrl() {
                            docUrl = docUrl.appendingPathComponent(videoFileName, isDirectory: false)
                            do {
                                try data?.write(to: docUrl, atomically: true)
                                DispatchQueue.main.async {
                                    callBackDownload(true, videoFileName)
                                }
                            }catch _ {
                                DispatchQueue.main.async {
                                    callBackDownload(false, "")
                                }
                            }
                        }
                    }else{
                        DispatchQueue.main.async {
                            callBackDownload(false, "")
                        }
                    }
                }
            }
        }
    }
    
    public func uploadImage(withImage : UIImage, onChatRoomID: String, whichView: UIView, onCompleation: @escaping(_ imageLink: String?) -> Void) -> Void {
        let progessHud = MBProgressHUD.showAdded(to: whichView, animated: true)
        progessHud.mode = .determinateHorizontalBar
        let dateString = HelperClass.shared.dateFormatter().string(from: Date())
        if FirebaseUser.currentId() != "" {
            let photoFileName = "PictureMessage/\(FirebaseUser.currentId())/\(onChatRoomID)/\(dateString).jpg"
            let refStorage = storage.reference(forURL: kFILEREFERENCE).child(photoFileName)
            let imageData = withImage.jpegData(compressionQuality: 0.8)
            var task : StorageUploadTask?
            task = refStorage.putData(imageData ?? Data(), metadata: nil, completion: { (metaData, error) in
                task?.removeAllObservers()
                progessHud.hide(animated: true)
                if error != nil {
                    print(error?.localizedDescription as Any)
                    return
                }else{
                    refStorage.downloadURL { (url , error) in
                        if error != nil {
                            print(error?.localizedDescription as Any)
                            onCompleation(nil)
                            return
                        }else{
                            guard let url = url else {return}
                            onCompleation(url.absoluteString)
                        }
                    }
                }
            })
            task?.observe(StorageTaskStatus.progress, handler: { snap in
                if let unitCount = snap.progress?.completedUnitCount, let totalUnitCount = snap.progress?.totalUnitCount {
                    progessHud.progress = Float((unitCount))/Float(totalUnitCount)
                }
            })
        }
    }
    
    public func downloadImage(withImageUrl: String, callBackDownload: @escaping(_ image: UIImage?) -> Void){
        guard let imageUrl = URL(string: withImageUrl) else {
            return
        }

        let imageFileName = imageUrl.lastPathComponent
        if let components = imageFileName.components(separatedBy: "%").last?.components(separatedBy: "?").first {
            if checkFileExists(withFileName: components){
                if let contentOfFiles = UIImage(contentsOfFile: self.fileInFileDIR(withFileName: imageFileName) ?? "") {
                    callBackDownload(contentOfFiles)
                }else{
                    callBackDownload(nil)
                    return
                }
            }else{
                let downloadQueue = DispatchQueue(label: "ImageDownloadQueue")
                downloadQueue.async {
                    let data = NSData(contentsOf: imageUrl)
                    if data != nil {
                        if var docUrl = self.getDocsUrl() {
                            docUrl = docUrl.appendingPathComponent(imageFileName, isDirectory: false)
                            do {
                                try data?.write(to: docUrl, atomically: true)
                                let imageToShow = UIImage(data: (data as? Data) ?? Data())
                                DispatchQueue.main.async {
                                    callBackDownload(imageToShow)
                                }
                            }catch _ {
                                DispatchQueue.main.async {
                                    callBackDownload(nil)
                                }
                            }
                        }
                    }else{
                        DispatchQueue.main.async {
                            callBackDownload(nil)
                        }
                    }
                }
            }
        }
    }
    
    
    public func checkFileExists(withFileName: String) -> Bool {
        var doesExist : Bool = false
        if let filePath = self.fileInFileDIR(withFileName: withFileName){
            if filePath != "" {
                let fileManager = FileManager.default.fileExists(atPath: filePath)
                if fileManager {
                    doesExist = true
                }else {
                    doesExist = false
                }
            }
        }
        return doesExist
    }
    
    public func getDocsUrl() -> URL? {
        if let documentUrl = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).last {
            return documentUrl
        }
        return nil
    }
    
    public func fileInFileDIR(withFileName: String) -> String? {
        if let fileUrl = self.getDocsUrl()?.appendingPathComponent(withFileName) {
            return fileUrl.path
        }
        return nil
    }
}


extension DownloadHelper {
    public func downloadAudio(withAudio: String, havingChatRoomID: String, view: UIView, onCompletion: @escaping(_ audioLink: String?) -> Void) -> Void {
        let progessHud = MBProgressHUD.showAdded(to: view, animated: true)
        progessHud.mode = .determinateHorizontalBar
        let dateString = HelperClass.shared.dateFormatter().string(from: Date())
        if FirebaseUser.currentId() != "" {
            let audioFileName = "AudioMessage/\(FirebaseUser.currentId())/\(havingChatRoomID)/\(dateString).m4a"
            let refStorage = storage.reference(forURL: kFILEREFERENCE).child(audioFileName)
            var task : StorageUploadTask?
            var audioData = NSData(contentsOfFile: withAudio)
            task = refStorage.putData((audioData as? Data) ?? Data(), metadata: nil, completion: { (metaData, error) in
                task?.removeAllObservers()
                progessHud.hide(animated: true)
                if error != nil {
                    print(error?.localizedDescription as Any)
                    return
                }else{
                    refStorage.downloadURL { (url , error) in
                        if error != nil {
                            print(error?.localizedDescription as Any)
                            onCompletion(nil)
                            return
                        }else{
                            guard let url = url else {return}
                            onCompletion(url.absoluteString)
                        }
                    }
                }
            })
            task?.observe(StorageTaskStatus.progress, handler: { snap in
                if let unitCount = snap.progress?.completedUnitCount, let totalUnitCount = snap.progress?.totalUnitCount {
                    progessHud.progress = Float((unitCount))/Float(totalUnitCount)
                }
            })
        }
    }
}
