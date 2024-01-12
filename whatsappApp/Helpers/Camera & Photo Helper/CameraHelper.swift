//
//  CameraHelper.swift
//  whatsappApp
//
//  Created by Abhishek Biswas on 11/01/24.
//

import Foundation
import UIKit
import MobileCoreServices
import UniformTypeIdentifiers


class CameraHelper {
    var delegate : UIImagePickerControllerDelegate & UINavigationControllerDelegate
    init(_delegate: UIImagePickerControllerDelegate & UINavigationControllerDelegate) {
        self.delegate = _delegate
    }
    
    
    public func presentPhotoLib(usingTheViewController viewController : UIViewController, andItsEditable editable: Bool) -> Void {
        if !UIImagePickerController.isSourceTypeAvailable(.photoLibrary) && !UIImagePickerController.isSourceTypeAvailable(.savedPhotosAlbum) {
            debugPrint("Photo Lib and Saved Albem is Not Present")
            return
        }
        
        let type = kUTTypeImage as String
        let imagePicker = UIImagePickerController()
        if UIImagePickerController.isSourceTypeAvailable(.photoLibrary) {
            imagePicker.sourceType = .photoLibrary
            if let availableTypes = UIImagePickerController.availableMediaTypes(for: .photoLibrary) {
                if (availableTypes as NSArray).contains(type) {
                    imagePicker.mediaTypes = [type]
                    imagePicker.allowsEditing = editable
                }
            }
        } else if UIImagePickerController.isSourceTypeAvailable(.savedPhotosAlbum) {
            imagePicker.sourceType = .savedPhotosAlbum
            if let availableTypes = UIImagePickerController.availableMediaTypes(for: .savedPhotosAlbum) {
                if (availableTypes as NSArray).contains(type) {
                    imagePicker.mediaTypes = [type]
                }
            }
        } else {
            return
        }
        imagePicker.allowsEditing = editable
        imagePicker.delegate = delegate
        viewController.present(imagePicker, animated: true, completion: nil)
        return
    }
    
    
    func PresentMultyCamera(target: UIViewController,  canEdit: Bool) {
        
        if !UIImagePickerController.isSourceTypeAvailable(UIImagePickerController.SourceType.camera) {
            return
        }
        let type1 = kUTTypeImage as String
        let type2 = kUTTypeMovie as String
        let imagePicker = UIImagePickerController()
        if UIImagePickerController.isSourceTypeAvailable(.camera) {
            
            if let availableTypes = UIImagePickerController.availableMediaTypes(for: .camera) {
                
                if (availableTypes as NSArray).contains(type1) {
                    
                    imagePicker.mediaTypes = [type1, type2]
                    imagePicker.sourceType = UIImagePickerController.SourceType.camera
                }
            }
            if UIImagePickerController.isCameraDeviceAvailable(.rear) {
                imagePicker.cameraDevice = UIImagePickerController.CameraDevice.rear
            }
            else if UIImagePickerController.isCameraDeviceAvailable(.front) {
                imagePicker.cameraDevice = UIImagePickerController.CameraDevice.front
            }
        } else {
            //show alert, no camera available
            return
        }
        
        imagePicker.allowsEditing = canEdit
        imagePicker.showsCameraControls = true
        imagePicker.delegate = delegate
        target.present(imagePicker, animated: true, completion: nil) // presents the imagepicker to the user
    }
    
    
    func PresentPhotoCamera(target: UIViewController,  canEdit: Bool) {
        if !UIImagePickerController.isSourceTypeAvailable(UIImagePickerController.SourceType.camera) {
            return
        }
        let type1 = kUTTypeImage as String
        let imagePicker = UIImagePickerController()
        if UIImagePickerController.isSourceTypeAvailable(.camera) {
            if let availableTypes = UIImagePickerController.availableMediaTypes(for: .camera) {
                if (availableTypes as NSArray).contains(type1) {
                    imagePicker.mediaTypes = [type1]
                    imagePicker.sourceType = UIImagePickerController.SourceType.camera
                }
            }
            if UIImagePickerController.isCameraDeviceAvailable(.rear) {
                imagePicker.cameraDevice = UIImagePickerController.CameraDevice.rear
            }
            else if UIImagePickerController.isCameraDeviceAvailable(.front) {
                imagePicker.cameraDevice = UIImagePickerController.CameraDevice.front
            }
        } else {
            return
        }
        imagePicker.allowsEditing = canEdit
        imagePicker.showsCameraControls = true
        imagePicker.delegate = delegate
        target.present(imagePicker, animated: true, completion: nil) // presents the imagepicker to the user
    }
    
    
}
