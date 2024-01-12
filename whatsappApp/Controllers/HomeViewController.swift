//
//  HomeViewController.swift
//  whatsappApp
//
//  Created by Abhishek Biswas on 08/01/24.
//

import UIKit
import FirebaseFirestore
import ProgressHUD

class HomeViewController: UIViewController {
    
    @IBOutlet weak var barProfileBtn : UIBarButtonItem!
    @IBOutlet weak var tableView: UITableView!
    
    var recentChatArray : [NSDictionary] = []
    var filteredChatsArray : [NSDictionary] = []
    var listenerRecentChats : ListenerRegistration?
    var searchController : UISearchController = UISearchController(searchResultsController: nil)
    

    override func viewDidLoad() {
        super.viewDidLoad()
        self.prepareForSetupHome()
    }
    
    private func prepareForSetupHome() {
        barProfileBtn.target = self
        barProfileBtn.action = #selector(profileAction(_ :))
        self.navigationController?.title = "Chats"
        self.navigationController?.navigationBar.prefersLargeTitles = true
        self.tableView.delegate = self
        self.tableView.dataSource = self
        self.tableView.register(ChatTableViewCell.nib(), forCellReuseIdentifier: ChatTableViewCell.cellId)
        self.tableView.register(ChatHeaderTableViewCell.nib(), forCellReuseIdentifier: ChatHeaderTableViewCell.cellId)
        self.navigationItem.searchController = self.searchController
        self.navigationItem.hidesSearchBarWhenScrolling = true
        self.searchController.searchResultsUpdater = self
        self.searchController.dimsBackgroundDuringPresentation = false
        definesPresentationContext = true
    }
    
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.tableView.tableFooterView = UIView()
        prepareForLoadChats()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        self.listenerRecentChats?.remove()
    }
    
    private func prepareForLoadChats() {
        ProgressHUD.animate("Loading Recent Chats")
        if FirebaseUser.currentId() != ""{
            listenerRecentChats = FHelperClass.shared.reference(.Recent).whereField(kUSERID, isEqualTo: FirebaseUser.currentId()).addSnapshotListener({ (qSnapshot, error) in
                if error != nil {
                    ProgressHUD.dismiss()
                    ProgressHUD.error("Error in Loading / Preparing of Chats")
                }else{
                    guard let snap = qSnapshot else {return}
                    self.recentChatArray = []
                    if !snap.isEmpty {
                        let sorted = ((HelperClass.shared.dictFromSnapShot(snapShot: snap.documents)) as NSArray).sortedArray(using: [NSSortDescriptor(key: kDATE, ascending: false)]) as? [NSDictionary]
                        guard let sortArray = sorted else {return}
                        for recent in sortArray {
                            if (recent[kLASTMESSAGE] as? String) != "" && recent[kCHATROOMID] != nil && recent[kRECENTID] != nil {
                                self.recentChatArray.append(recent)
                            }
                        }
                        DispatchQueue.main.async {
                            ProgressHUD.dismiss()
                            self.tableView.reloadData()
                        }
                    }else{
                        ProgressHUD.dismiss()
                        ProgressHUD.animate("No Recent Chat Found!")
                        DispatchQueue.main.asyncAfter(deadline: .now() + 5.0) {
                            ProgressHUD.dismiss()
                            self.tableView.reloadData()
                        }
                    }
                }
            })
        }
    }
    
    @objc func profileAction(_ sender: UIBarButtonItem) {
        let vc = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "UserViewController") as? UserViewController
        vc?.modalPresentationStyle = .fullScreen
        self.navigationController?.pushViewController(vc ?? UIViewController(), animated: true)
    }
}

extension HomeViewController : UITableViewDelegate, UITableViewDataSource {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if (self.searchController.isActive) && (self.searchController.searchBar.text != "") {
            return self.filteredChatsArray.count + 1
        }
        return self.recentChatArray.count + 1
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if indexPath.row == 0 {
            let chatHeaderCell = tableView.dequeueReusableCell(withIdentifier: ChatHeaderTableViewCell.cellId, for: indexPath) as? ChatHeaderTableViewCell
            chatHeaderCell?.delegate = self
            chatHeaderCell?.selectionStyle = .none
            return chatHeaderCell ?? UITableViewCell()
        } else {
            let modifiedIndexPath = IndexPath(row: indexPath.row - 1, section: indexPath.section)
            let chatCell = tableView.dequeueReusableCell(withIdentifier: ChatTableViewCell.cellId, for: modifiedIndexPath) as? ChatTableViewCell
            var recent: [String: Any] = [:]

            if self.searchController.isActive && self.searchController.searchBar.text != "" {
                recent = self.filteredChatsArray[modifiedIndexPath.row] as? [String: Any] ?? [:]
            } else {
                recent = self.recentChatArray[modifiedIndexPath.row] as? [String: Any] ?? [:]
            }
            chatCell?.delegate = self
            chatCell?.genrateCell(withRecentChat: recent, indexPath: modifiedIndexPath)
            return chatCell ?? UITableViewCell()
        }
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableView.automaticDimension
    }
    
    func tableView(_ tableView: UITableView, leadingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        return nil
    }
    
    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        if indexPath.row != 0 {
            let modifiedIndexPath = IndexPath(row: indexPath.row - 1, section: indexPath.section)
            var chatDict: NSDictionary?
            if self.searchController.isActive, let text = self.searchController.searchBar.text {
                chatDict = self.filteredChatsArray[modifiedIndexPath.row]
            } else {
                chatDict = self.recentChatArray[modifiedIndexPath.row]
            }
            
            guard let tempDict = chatDict else {
                return nil
            }
            
            var muteTitle = "Unmute"
            var mute = false
            
            if let memToPush = tempDict[kMEMBERSTOPUSH] as? String, !FirebaseUser.currentId().isEmpty {
                mute = memToPush.contains(FirebaseUser.currentId())
                muteTitle = mute ? "Mute" : "Unmute"
            }
            let deleteAction = UIContextualAction(style: .destructive, title: "Delete") { _, _, handler in
                self.recentChatArray.remove(at: modifiedIndexPath.row)
                guard let chatDict = chatDict else {return}
                ChatHandler.shared.deleteRecentChat(withChatDict: chatDict)
                DispatchQueue.main.async {
                    self.tableView.reloadData()
                }
                handler(true)
            }
            
            let muteAction = UIContextualAction(style: .normal, title: muteTitle) { _, _, handler in
                handler(true)
            }
            
            muteAction.backgroundColor = mute ? .red : .blue
            return UISwipeActionsConfiguration(actions: [deleteAction, muteAction])
        }else{
            return nil
        }
    }
    
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        var recentChat : NSDictionary = [:]
        if indexPath.row != 0 {
            let modifiedIndexPath = IndexPath(row: indexPath.row - 1, section: indexPath.section)
            if searchController.isActive && searchController.searchBar.text != "" {
                recentChat = self.filteredChatsArray[modifiedIndexPath.row]
            }else{
                recentChat = self.recentChatArray[modifiedIndexPath.row]
            }
            ChatHandler.shared.restartRecentChat(withChatRecent: recentChat)
            self.prepareForChatVC(withRecentChat: recentChat)
        }
    }
    
    private func prepareForChatVC(withRecentChat : NSDictionary) {
        let chatVc = ChatViewController()
        chatVc.hidesBottomBarWhenPushed = true
        chatVc.memberId = withRecentChat[kMEMBERS] as? [String] ?? []
        chatVc.memberIdToPush = withRecentChat[kMEMBERSTOPUSH] as? [String] ?? []
        chatVc.chatRoomId = withRecentChat[kCHATROOMID] as? String ?? ""
        chatVc.chatTitle = withRecentChat[kWITHUSERFULLNAME] as? String ?? ""
        chatVc.isGroup = (withRecentChat[kTYPE] as? String) ?? kPRIVATE == kGROUP
//        chatVc.isGroup = false
        self.navigationController?.pushViewController(chatVc, animated: true)
    }

}

extension HomeViewController: ChatTableViewCellDelegate {
    func avatarImageDidTap(onIndex: IndexPath) {
        DispatchQueue.main.async {
            var recentChats : NSDictionary?
            if (self.searchController.isActive) && (self.searchController.searchBar
                .text != ""){
                recentChats = self.filteredChatsArray[onIndex.row]
            }else{
                recentChats = self.recentChatArray[onIndex.row]
            }
            guard let recentChats = recentChats else {return}
            if (recentChats[kTYPE] as? String) == kPRIVATE {
                if let recentChatUserID = recentChats[kWITHUSERUSERID] as? String {
                    FHelperClass.shared.reference(.User).document(recentChatUserID).getDocument { (snapshot, error) in
                        if error != nil {
                            print(error?.localizedDescription ?? "Error Occurced")
                            return
                        }else{
                            guard let snap = snapshot else {return}
                            if snap.exists {
                                let snapDict = snap.data()
                                let fUser = FirebaseUser.init(_dictionary: (snapDict as? NSDictionary) ?? [:])
                                self.showUserProfile(withFirebaseUser: fUser)
                            }
                        }
                    }
                }
            }else{
                // For Group
                
            }
        }
    }
    
    private func showUserProfile(withFirebaseUser: FirebaseUser) {
        let profileVC = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "ProfileViewController") as? ProfileViewController
        profileVC?.fUser = withFirebaseUser
        self.navigationController?.pushViewController(profileVC ?? UIViewController(), animated: true)
    }
}


extension HomeViewController : UISearchResultsUpdating {
    
    private func filterContentForSearchText(searchText: String, scope: String = "All") {
        self.filteredChatsArray = self.recentChatArray.filter({ (recentChats) -> Bool in
            if let chatUserNames = recentChats[kWITHUSERFULLNAME] as? String {
                return chatUserNames.lowercased().contains(searchText.lowercased())
            }
            return false
        })
        DispatchQueue.main.async {
            self.tableView.reloadData()
        }
    }
    
    
    func updateSearchResults(for searchController: UISearchController) {
        self.filterContentForSearchText(searchText: searchController.searchBar.text ?? "")
    }
}


extension HomeViewController : ChatHeaderTableViewCellDelegate {
    func grpButtonTap() {
        DispatchQueue.main.async {
            
        }
    }
}
