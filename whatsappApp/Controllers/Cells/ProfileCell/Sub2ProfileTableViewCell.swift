//
//  Sub2ProfileTableViewCell.swift
//  whatsappApp
//
//  Created by Abhishek Biswas on 09/01/24.
//

import UIKit

class Sub2ProfileTableViewCell: UITableViewCell {
    
    @IBOutlet weak var blockBtn: UIButton!
    
    static let cellId = "Sub2ProfileTableViewCell"
    static func nib() -> UINib{
        return UINib(nibName: "Sub2ProfileTableViewCell", bundle: nil)
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
