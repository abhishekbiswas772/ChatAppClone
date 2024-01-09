//
//  HomeViewController.swift
//  whatsappApp
//
//  Created by Abhishek Biswas on 08/01/24.
//

import UIKit

class HomeViewController: UIViewController {
    
    @IBOutlet weak var barProfileBtn : UIBarButtonItem!
    @IBOutlet weak var tableView: UITableView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        barProfileBtn.target = self
        barProfileBtn.action = #selector(profileAction(_ :))
        self.navigationController?.title = "Chats"
        self.navigationController?.navigationBar.prefersLargeTitles = true
        self.tableView.delegate = self
        self.tableView.dataSource = self
        self.tableView.register(ChatTableViewCell.nib(), forCellReuseIdentifier: ChatTableViewCell.cellId)
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
        <#code#>
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        <#code#>
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableView.automaticDimension
    }
}
