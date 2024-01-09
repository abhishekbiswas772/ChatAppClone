//
//  SplashViewController.swift
//  whatsappApp
//
//  Created by Abhishek Biswas on 09/01/24.
//

import UIKit
import FirebaseAuth
import FirebaseCore

class SplashViewController: UIViewController {
    
    var authListener : AuthStateDidChangeListenerHandle?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        prepareForAutoLoginForUser()
    }
    
    private func prepareForAutoLoginForUser() {
        authListener = Auth.auth().addStateDidChangeListener({ (auth, authUser) in
            guard let authListen = self.authListener else {return}
            Auth.auth().removeStateDidChangeListener(authListen)
            if authUser != nil {
                if (userDefaults.object(forKey: kCURRENTUSER) != nil) {
                    NotificationCenter.default.post(name: NSNotification.Name(rawValue: USER_DID_LOGIN_NOTIFICATION), object: nil, userInfo: [kUSERID : FirebaseUser.currentId()])
                    let tabVC = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "TabViewController") as? TabViewController
                    tabVC?.modalPresentationStyle = .fullScreen
                    self.present(tabVC ?? UIViewController(), animated: true, completion: nil)
                }
            }
        })
    }
}
