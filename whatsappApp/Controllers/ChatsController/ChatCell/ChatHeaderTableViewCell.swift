//
//  ChatHeaderTableViewCell.swift
//  whatsappApp
//
//  Created by Abhishek Biswas on 11/01/24.
//

import UIKit

protocol ChatHeaderTableViewCellDelegate {
    func grpButtonTap()
}

class ChatHeaderTableViewCell: UITableViewCell {
    
    @IBOutlet weak var newGrpChatBtn: UIButton!
    
    var delegate : ChatHeaderTableViewCellDelegate?
    
    static let cellId = "ChatHeaderTableViewCell"
    static func nib() -> UINib {
        return UINib(nibName: "ChatHeaderTableViewCell", bundle: nil)
    }

    override func awakeFromNib() {
        super.awakeFromNib()
        newGrpChatBtn.addTarget(self, action: #selector(grpAction(_ :)), for: .touchUpInside)
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
    
    @objc func grpAction(_ sender: UIButton) {
        self.delegate?.grpButtonTap()
    }
    
}
