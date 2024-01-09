//
//  ProfileViewController.swift
//  whatsappApp
//
//  Created by Abhishek Biswas on 09/01/24.
//

import UIKit
import ProgressHUD

class ProfileViewController: UIViewController {
    
    
    @IBOutlet weak var tableView: UITableView!
    
    var fUser : FirebaseUser?
    var fullName : String?
    var phoneNumber : String?
    var avaTarImage : UIImage?
    var isBlockBtnHide : Bool?
    var isMailBtnHide : Bool?
    var isPhoneBtnHide : Bool?
    var currentTitleForBlock : String?
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.delegate = self
        tableView.dataSource = self
//        tableView.backgroundColor = .white
        tableView.register(ProfileTableViewCell.nib(), forCellReuseIdentifier: ProfileTableViewCell.cellId)
        tableView.register(SubProfile1TableViewCell.nib(), forCellReuseIdentifier: SubProfile1TableViewCell.cellId)
        tableView.register(Sub2ProfileTableViewCell.nib(), forCellReuseIdentifier: Sub2ProfileTableViewCell.cellId)
        prepareForSetup()
    }
    
    
    private func prepareForSetup() {
        if fUser != nil {
            self.title = "Profile"
            guard let user = fUser else {return}
            self.fullName = user.fullname ?? ""
            self.phoneNumber = user.phoneNumber ?? ""
            self.updateBlockStatus()
            HelperClass.shared.imageFromData(withData: user.avatar ?? "") { image in
                if image != nil {
                    self.avaTarImage = image?.circleMasked
                }
            }
            
            DispatchQueue.main.async {
                self.tableView.reloadData()
            }
        }
    }
    
    private func updateBlockStatus() {
        guard let user = fUser else {return}
        if let uid = user.objectId {
            if uid != FirebaseUser.currentId() {
                self.isBlockBtnHide = false
                self.isMailBtnHide = false
                self.isPhoneBtnHide = false
            }else{
                self.isBlockBtnHide = true
                self.isMailBtnHide = true
                self.isPhoneBtnHide = true
            }
            
            
            if ((FirebaseUser.currentUser()?.blockedUsers?.contains(uid)) != nil) {
                self.currentTitleForBlock = "unblock user"
            }else{
                self.currentTitleForBlock = "block user"
            }
        }
    }
}

extension ProfileViewController : UITableViewDelegate, UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return 3
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if indexPath.section == 0 {
            let profileNameCell = tableView.dequeueReusableCell(withIdentifier: ProfileTableViewCell.cellId, for: indexPath) as? ProfileTableViewCell
            profileNameCell?.profileName.text = self.fullName ?? ""
            profileNameCell?.profileContactNumber.text = self.phoneNumber ?? ""
            profileNameCell?.profileImageView.image = self.avaTarImage ?? UIImage(systemName: "person.circle")
            return profileNameCell ?? UITableViewCell()
        } else if indexPath.section == 1 {
            let mailPhoneCell = tableView.dequeueReusableCell(withIdentifier: SubProfile1TableViewCell.cellId, for: indexPath) as? SubProfile1TableViewCell
            mailPhoneCell?.phoneNumberBtn.addTarget(self, action: #selector(phoneBtnAction(_:)), for: .touchUpInside)
            mailPhoneCell?.emailBtn.addTarget(self, action: #selector(mailBtnAction(_:)), for: .touchUpInside)
            mailPhoneCell?.phoneNumberBtn.isHidden = self.isMailBtnHide ?? false
            mailPhoneCell?.emailBtn.isHidden = self.isPhoneBtnHide ?? false
            return mailPhoneCell ?? UITableViewCell()
        } else {
            let blockCell = tableView.dequeueReusableCell(withIdentifier: Sub2ProfileTableViewCell.cellId, for: indexPath) as? Sub2ProfileTableViewCell
            blockCell?.blockBtn.setTitle(self.currentTitleForBlock ?? "Block User", for: .normal)
            blockCell?.blockBtn.isHidden = self.isBlockBtnHide ?? false
            blockCell?.blockBtn.addTarget(self, action: #selector(blockAction(_:)), for: .touchUpInside)
            return blockCell ?? UITableViewCell()
        }
    }

    
//    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
//        return UIView()
//    }
//    
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableView.automaticDimension
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        return UIView()
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        if section == 0 {
            return 0.0
        }else {
            return 30.0
        }
    }
}


extension ProfileViewController {
    @objc func phoneBtnAction(_ sender : UIButton){
        print("Call The user")
    }
    
    @objc func mailBtnAction(_ sender : UIButton) {
        print("Mail the user")
    }
    
    @objc func blockAction(_ sender: UIButton){
        guard let user = fUser else {return}
        if let uid = user.objectId {
            var currentBlockIds = FirebaseUser.currentUser()?.blockedUsers ?? []
            if currentBlockIds.contains(uid) {
                if let indexForBlock : Int = currentBlockIds.firstIndex(of: uid) {
                    currentBlockIds.remove(at: indexForBlock)
                }
            }else{
                currentBlockIds.append(uid)
            }
            
            FHelperClass.shared.updateCurrentUserInFirestore(withValues: [kBLOCKEDUSERID : currentBlockIds]) { error in
                if error != nil {
                    DispatchQueue.main.async {
                        ProgressHUD.error("Failed to Block User")
                    }
                    return
                }else{
                    self.updateBlockStatus()
                }
            }
        }
    }
}
