//
//  SettingTableViewCell.swift
//  whatsappApp
//
//  Created by Abhishek Biswas on 06/01/24.
//

import UIKit

class SettingTableViewCell: UITableViewCell {

    @IBOutlet weak var labelForSettings: UILabel!
    static let cellId = "SettingTableViewCell"
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
    
    static func nib() -> UINib {
        return UINib(nibName: "SettingTableViewCell", bundle: nil)
    }
}
