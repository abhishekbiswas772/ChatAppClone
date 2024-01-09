//
//  ViewController.swift
//  whatsappApp
//
//  Created by Abhishek Biswas on 05/01/24.
//

import UIKit
import ProgressHUD

class WelcomeViewController: UIViewController {
    
    
    @IBOutlet weak var emailTxt: UITextField!
    @IBOutlet weak var passwordTxt: UITextField!
    @IBOutlet weak var rPasswordtxt: UITextField!
    @IBOutlet weak var registerBtn: UIButton!
    @IBOutlet weak var logBtn: UIButton!
    @IBOutlet var tapGesture: UITapGestureRecognizer!
    
    
    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        logBtn.addTarget(self, action: #selector(loginAction(_ :)), for: .touchUpInside)
        registerBtn.addTarget(self, action: #selector(registerAction(_ :)), for: .touchUpInside)
        tapGesture.addTarget(self, action: #selector(tapAction(_ :)))
        
    }
   
    
    @objc func loginAction(_ sender: UIButton) {
        self.dismissKeyBoard()
        guard let emailTxt = self.emailTxt.text else {return}
        guard let passwordtxt = self.passwordTxt.text else {return}
        if !emailTxt.isEmpty && !passwordtxt.isEmpty {
            loginActionForUser(withEmail: emailTxt, withPassword: passwordtxt)
        }else{
            ProgressHUD.failed("Please Fill All The Fields")
        }
    }
    
    private func loginActionForUser(withEmail: String, withPassword: String) {
        FirebaseUser.loginUser(withEmail: withEmail, withPassword: withPassword) { error in
            if error != nil {
                ProgressHUD.failed(error?.localizedDescription)
                return
            }else{
                self.prepareForHome()
            }
        }
    }
    
    private func prepareForHome() {
        ProgressHUD.dismiss()
        self.clearTxtFields()
        self.dismissKeyBoard()
        print("Show User Home Screen")
        NotificationCenter.default.post(name: NSNotification.Name(rawValue: USER_DID_LOGIN_NOTIFICATION), object: nil, userInfo: [kUSERID : FirebaseUser.currentId()])
        let tabVC = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "TabControllerHome") as? UITabBarController
        tabVC?.modalPresentationStyle = .fullScreen
        self.present(tabVC ?? UIViewController(), animated: true, completion: nil)
    }
    
    
    @objc func registerAction(_ sender: UIButton) {
        self.dismissKeyBoard()
        guard let emailTxt = self.emailTxt.text else {return}
        guard let passwordtxt = self.passwordTxt.text else {return}
        guard let rpasswordtxt = self.rPasswordtxt.text else {return}
        if !emailTxt.isEmpty && !passwordtxt.isEmpty && !rpasswordtxt.isEmpty {
            if passwordtxt == rpasswordtxt {
                registerActionForUser(withEmail: emailTxt, withPassword: passwordtxt)
            }else{
                ProgressHUD.failed("Password are not same")
            }
        }else{
            ProgressHUD.failed("Please Fill All The Fields")
        }
    }
    
    private func registerActionForUser(withEmail: String, withPassword: String) {
        clearTxtFields()
        dismissKeyBoard()
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let registerVC = storyboard.instantiateViewController(withIdentifier: "RegisterViewController") as? RegisterViewController
        registerVC?.modalPresentationStyle = .fullScreen
        registerVC?.emailId = withEmail
        registerVC?.password = withPassword
        self.present(registerVC ?? UIViewController(), animated: true, completion: nil)
    }
    
    @objc func tapAction(_ sender: UITapGestureRecognizer) {
        self.dismissKeyBoard()
    }
    
    
    private func clearTxtFields() {
        self.emailTxt.text = ""
        self.passwordTxt.text = ""
        self.rPasswordtxt.text = ""
    }
    
    private func dismissKeyBoard() {
        self.view.endEditing(false)
    }
}

