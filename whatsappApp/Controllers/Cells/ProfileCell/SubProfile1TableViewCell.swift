//
//  SubProfile1TableViewCell.swift
//  whatsappApp
//
//  Created by Abhishek Biswas on 09/01/24.
//

import UIKit

class SubProfile1TableViewCell: UITableViewCell {
    
    
    @IBOutlet weak var phoneNumberBtn: UIButton!
    @IBOutlet weak var emailBtn: UIButton!
    
    static let cellId = "SubProfile1TableViewCell"
    static func nib() -> UINib {
        return UINib(nibName: "SubProfile1TableViewCell", bundle: nil)
    }
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
}
