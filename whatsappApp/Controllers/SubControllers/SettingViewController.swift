//
//  SettingViewController.swift
//  whatsappApp
//
//  Created by Abhishek Biswas on 06/01/24.
//

import Foundation
import UIKit
import ProgressHUD

class SettingViewController : UIViewController {
    
    
    @IBOutlet weak var tableView : UITableView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(SettingTableViewCell.nib(), forCellReuseIdentifier: SettingTableViewCell.cellId)
        self.navigationController?.navigationBar.prefersLargeTitles = true
    }
}

extension SettingViewController : UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: SettingTableViewCell.cellId, for: indexPath) as? SettingTableViewCell
        if indexPath.row == 0 {
            cell?.labelForSettings.text = "Logout"
            cell?.labelForSettings.tintColor = .blue
        }
        return cell ?? UITableViewCell()
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if indexPath.row == 0 {
            prepareForLogout()
        }
    }
    
    private func prepareForLogout() {
        FirebaseUser.logoutCurrentUser { sucess in
            if sucess {
                DispatchQueue.main.async {
                    let welcomeVC = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "WelcomeViewController") as? WelcomeViewController
                    welcomeVC?.modalPresentationStyle = .fullScreen
                    self.present(welcomeVC ?? UIViewController(), animated: true, completion: nil)
                }
            }else {
                ProgressHUD.error("Error In Logout User..")
            }
        }
    }
}
