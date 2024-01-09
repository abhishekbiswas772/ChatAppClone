//
//  UserViewController.swift
//  whatsappApp
//
//  Created by Abhishek Biswas on 08/01/24.
//

import Foundation
import UIKit
import Firebase
import ProgressHUD
import FirebaseFirestoreInternal


class UserViewController : UIViewController{
    
    @IBOutlet weak var segmentedUser: UISegmentedControl!
    @IBOutlet weak var tableView: UITableView!
    
    var allFirebaseUser : [FirebaseUser] = []
    var filteredUser : [FirebaseUser] = []
    var allUsrGrouped : [String : [FirebaseUser]] = [:]
    var allSectionTitle : [String] = []
    
    var searchBarController : UISearchController = UISearchController(searchResultsController: nil)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(UserTableViewCell.nib(), forCellReuseIdentifier: UserTableViewCell.cellId)
        loadAllUser(withFilter: kCITY)
        self.segmentedUser.addTarget(self, action: #selector(segmentedAction(_ :)), for: .valueChanged)
        self.title = "Users"
        self.navigationItem.largeTitleDisplayMode = .never
        self.navigationItem.searchController = self.searchBarController
        self.searchBarController.searchResultsUpdater = self
        self.searchBarController.dimsBackgroundDuringPresentation = false
        definesPresentationContext = true
        self.tableView.tableFooterView = UIView()
    }
    
    @objc func segmentedAction(_ sender: UISegmentedControl) {
        switch sender.selectedSegmentIndex {
        case 0:
            loadAllUser(withFilter: kCITY)
            break
        case 1:
            loadAllUser(withFilter: kCOUNTRY)
            break
        case 2:
            loadAllUser(withFilter: "")
        default:
            return
            
        }
    }
    
}

extension UserViewController : UITableViewDelegate, UITableViewDataSource {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        if searchBarController.isActive && searchBarController.searchBar.text != "" {
            return 1
        }else{
            return allUsrGrouped.count
        }
    }
    
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if searchBarController.isActive && searchBarController.searchBar.text != ""{
            return self.filteredUser.count
        }else{
            let sectionTitle = self.allSectionTitle[section]
            let users = self.allUsrGrouped[sectionTitle]
            return users?.count ?? 0
        }
    }
    
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: UserTableViewCell.cellId, for: indexPath) as? UserTableViewCell
        var user : FirebaseUser
        if self.searchBarController.isActive && self.searchBarController.searchBar.text != "" {
            user = filteredUser[indexPath.row]
        }else{
            let sectionTitle = self.allSectionTitle[indexPath.section]
            let users = self.allUsrGrouped[sectionTitle]
            user = users?[indexPath.row] ?? FirebaseUser(_dictionary: [:])
        }
        cell?.delegate = self
        cell?.genrateCell(withUser: user, index: indexPath)
        return cell ?? UITableViewCell()
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableView.automaticDimension
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        var user : FirebaseUser?
        if self.searchBarController.isActive && self.searchBarController.searchBar.text != "" {
            user = filteredUser[indexPath.row]
        }else{
            let sectionTitle = self.allSectionTitle[indexPath.section]
            let users = self.allUsrGrouped[sectionTitle]
            user = users?[indexPath.row] ?? FirebaseUser(_dictionary: [:])
        }
        // Move to chat
        if let user2 = user, let user1 = FirebaseUser.currentUser(){
            let chatRecent : String? = ChatHandler.shared.startPrivateChatBtw(withPersonOne: user1, toPersonTwo: user2)
            print(chatRecent)
        }
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if searchBarController.isActive && searchBarController.searchBar.text != "" {
            return ""
        }else{
            return self.allSectionTitle[section]
            
        }
    }
    
    func sectionIndexTitles(for tableView: UITableView) -> [String]? {
        if searchBarController.isActive && searchBarController.searchBar.text != "" {
            return nil
        }else{
            return self.allSectionTitle
            
        }
    }
    
    func tableView(_ tableView: UITableView, sectionForSectionIndexTitle title: String, at index: Int) -> Int {
        return index
    }
    
    private func splitDataIntoSection() {
        var sectionTitle : String = ""
        for itemUser in 0..<self.allFirebaseUser.count {
            let currentRecordedUser = self.allFirebaseUser[itemUser]
            if let firstChar = currentRecordedUser.firstname?.first {
                let firstCharStr = "\(firstChar)"
                if firstCharStr != sectionTitle {
                    sectionTitle = firstCharStr
                    self.allUsrGrouped[sectionTitle] = []
                    self.allSectionTitle.append(sectionTitle)
                }
                self.allUsrGrouped[firstCharStr]?.append(currentRecordedUser)
            }
        }
    }
}

extension UserViewController : UISearchResultsUpdating {
    
    private func loadAllUser(withFilter: String) {
        ProgressHUD.animate()
        var query: Query?
        switch withFilter {
        case kCITY:
            query = FHelperClass.shared.reference(.User)
                .whereField(kCITY, isEqualTo: FirebaseUser.currentUser()?.city ?? "")
                .order(by: kFIRSTNAME, descending: false)
        case kCOUNTRY:
            query = FHelperClass.shared.reference(.User)
                .whereField(kCOUNTRY, isEqualTo: FirebaseUser.currentUser()?.country ?? "")
                .order(by: kFIRSTNAME, descending: false)
        default:
            query = FHelperClass.shared.reference(.User)
                .order(by: kFIRSTNAME, descending: false)
        }
        
        query?.getDocuments(completion: { [weak self] (snapshot, error) in
            guard let self = self else { return }
            
            DispatchQueue.main.async {
                ProgressHUD.dismiss()
            }
            
            if let error = error {
                print("Error fetching documents: \(error)")
                DispatchQueue.main.async {
                    self.tableView.reloadData()
                }
                return
            }
            
            guard let snapshot = snapshot else {
                DispatchQueue.main.async {
                    self.tableView.reloadData()
                }
                return
            }
            
            if !snapshot.isEmpty {
                self.allFirebaseUser = []
                
                for usr in snapshot.documents {
                    let userDict = usr.data() as NSDictionary
                    let fUser = FirebaseUser(_dictionary: userDict)
                    
                    if fUser.objectId != FirebaseUser.currentId() {
                        self.allFirebaseUser.append(fUser)
                    }
                }
                
                self.splitDataIntoSection()
                
                DispatchQueue.main.async {
                    self.tableView.reloadData()
                }
            }
        })
    }
    
    private func filterContentForSearchText(searchText: String, scope: String = "All") {
        self.filteredUser = self.allFirebaseUser.filter({ (fUser) -> Bool in
            return fUser.firstname?.lowercased().contains(searchText.lowercased()) ?? false
        })
        DispatchQueue.main.async {
            self.tableView.reloadData()
        }
    }
    
    
    func updateSearchResults(for searchController: UISearchController) {
        filterContentForSearchText(searchText: searchController.searchBar.text ?? "")
    }
}

extension UserViewController : UserTableViewCellDelegate {
    func didTapAvatarImage(withIndexPath: IndexPath) {
        DispatchQueue.main.async {
            let profileVC = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "ProfileViewController") as? ProfileViewController
            var user : FirebaseUser?
            if self.searchBarController.isActive && self.searchBarController.searchBar.text != "" {
                profileVC?.fUser = self.filteredUser[withIndexPath.row]
            }else{
                let sectionTitle = self.allSectionTitle[withIndexPath.section]
                let users = self.allUsrGrouped[sectionTitle]
                user = users?[withIndexPath.row] ?? FirebaseUser(_dictionary: [:])
            }
            profileVC?.fUser = user
            self.navigationController?.pushViewController(profileVC ?? UIViewController(), animated: true)
        }
    }
}
