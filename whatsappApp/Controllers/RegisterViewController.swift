//
//  RegisterViewController.swift
//  whatsappApp
//
//  Created by Abhishek Biswas on 05/01/24.
//

import Foundation
import UIKit
import ProgressHUD


class RegisterViewController : UIViewController {
    
    @IBOutlet weak var cancelBtn: UIButton!
    @IBOutlet weak var doneBtn: UIButton!
    @IBOutlet weak var profileImg: UIImageView!
    @IBOutlet weak var nameField: UITextField!
    @IBOutlet weak var surnameField: UITextField!
    @IBOutlet weak var countryField: UITextField!
    @IBOutlet weak var cityField: UITextField!
    @IBOutlet weak var phoneField: UITextField!
    @IBOutlet weak var imageProfile: UIImageView!
    
    
    var emailId : String?
    var password : String?
    var avatarImage : UIImage?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        cancelBtn.addTarget(self, action: #selector(cancelBtnAction(_ :)), for: .touchUpInside)
        doneBtn.addTarget(self, action: #selector(doneBtnAction(_ :)), for: .touchUpInside)
    }
    
    @objc func doneBtnAction(_ sender: UIButton){
        self.dismissKeyboard()
        ProgressHUD.animate("Registering User ....")
        guard let nametxt = nameField.text else {return}
        guard let surnametxt = surnameField.text else {return}
        guard let countrytxt = countryField.text else {return}
        guard let citytxt = cityField.text, let phonetxt = phoneField.text else {return}
        if !nametxt.isEmpty && !surnametxt.isEmpty && !countrytxt.isEmpty && !citytxt.isEmpty && !phonetxt.isEmpty {
            if let email = emailId , let passwordPrev = password {
                FirebaseUser.registerUser(withEmail: email, withPassword: passwordPrev, withFirstName: nametxt, withLastName: surnametxt, withAvatar: "") { error in
                    if error != nil {
                        ProgressHUD.dismiss()
                        ProgressHUD.error(error?.localizedDescription)
                    }else {
                        self.registerUser()
                    }
                }
            }
        }else{
            ProgressHUD.error("Fields cannot be empty")
        }
    }
    
    
    private func registerUser() {
        guard let nametxt = nameField.text else {return}
        guard let surnametxt = surnameField.text else {return}
        guard let countrytxt = countryField.text else {return}
        guard let citytxt = cityField.text, let phonetxt = phoneField.text else {return}
        let fullName : String = nametxt + " " + surnametxt
        var tempDictForFirebase : [String : Any] = [
            kFIRSTNAME : nametxt,
            kLASTNAME : surnametxt,
            kFULLNAME : fullName,
            kCOUNTRY : countrytxt,
            kCITY : citytxt,
            kPHONE : phonetxt
        ]
        if self.avatarImage == nil {
            HelperClass.shared.imageFromInitials(withFirstName: nametxt, lastName: surnametxt) { image in
                let avatarData = image.pngData()
                let avatarString = avatarData?.base64EncodedString(options: NSData.Base64EncodingOptions(rawValue: 0))
                tempDictForFirebase[kAVATAR] = avatarString
            }
        }else{
            let avatarData = self.avatarImage?.pngData()
            let avatarDataString = avatarData?.base64EncodedString(options: NSData.Base64EncodingOptions(rawValue: 0))
            tempDictForFirebase[kAVATAR] = avatarDataString
        }
        self.finishRegisterUser(withValue: tempDictForFirebase)
    }
    
    
    private func finishRegisterUser(withValue: [String: Any]) {
        FHelperClass.shared.updateCurrentUserInFirestore(withValues: withValue) { error in
            if error != nil {
                DispatchQueue.main.async {
                    ProgressHUD.error("Error in Saving The User, \(error?.localizedDescription ?? "")")
                    return
                }
            }else{
                self.prepareForHome()
            }
        }
    }
    
    private func prepareForHome() {
        ProgressHUD.dismiss()
        self.cleanTxtFields()
        self.dismissKeyboard()
        print("Show User Home Screen")
        NotificationCenter.default.post(name: NSNotification.Name(rawValue: USER_DID_LOGIN_NOTIFICATION), object: nil, userInfo: [kUSERID : FirebaseUser.currentId()])
        let tabVC = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "TabControllerHome") as? UITabBarController
        tabVC?.modalPresentationStyle = .fullScreen
        self.present(tabVC ?? UIViewController(), animated: true, completion: nil)
    }
    
    
    @objc func cancelBtnAction(_ sender: UIButton){
        cleanTxtFields()
        dismissKeyboard()
        self.dismiss(animated: true, completion: nil)
    }
    
    
    private func cleanTxtFields() {
        self.nameField.text = ""
        self.surnameField.text = ""
        self.countryField.text = ""
        self.cityField.text = ""
        self.phoneField.text = ""
    }
    
    private func dismissKeyboard() {
        self.view.endEditing(false)
    }
}
