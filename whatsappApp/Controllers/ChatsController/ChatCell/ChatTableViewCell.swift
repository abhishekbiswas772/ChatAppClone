//
//  ChatTableViewCell.swift
//  whatsappApp
//
//  Created by Abhishek Biswas on 09/01/24.
//

import UIKit

protocol ChatTableViewCellDelegate {
    func avatarImageDidTap(onIndex : IndexPath)
}

class ChatTableViewCell: UITableViewCell {
    
    @IBOutlet weak var chatImageView: UIImageView!
    @IBOutlet weak var nameLabelChat: UILabel!
    @IBOutlet weak var dateLabel: UILabel!
    @IBOutlet weak var recentMessage: UILabel!
    @IBOutlet weak var counterLabel: UILabel!
    @IBOutlet weak var chatView: UIView!
    
    
    var indexPath : IndexPath?
    var tapGesture : UITapGestureRecognizer?
    var delegate : ChatTableViewCellDelegate?
    
    
    override func awakeFromNib() {
        super.awakeFromNib()
        self.chatView.layer.cornerRadius = self.chatView.frame.size.width / 2
        self.tapGesture = UITapGestureRecognizer()
        self.tapGesture?.addTarget(self, action: #selector(tapGestureAction(_ :)))
        self.chatImageView.isUserInteractionEnabled = true
        self.chatImageView.addGestureRecognizer(self.tapGesture ?? UITapGestureRecognizer())
    }
    
    @objc func tapGestureAction(_ sender: UITapGestureRecognizer) {
        if let index = self.indexPath {
            delegate?.avatarImageDidTap(onIndex: index)
        }
    }
    
    public func genrateCell(withRecentChat : [String : Any], indexPath : IndexPath){
        self.indexPath = indexPath
        self.nameLabelChat.text = (withRecentChat[kWITHUSERFULLNAME] as? String) ?? ""
        self.recentMessage.text = (withRecentChat[kLASTMESSAGE] as? String) ?? ""
        self.counterLabel.text = (withRecentChat[kCOUNTER] as? String) ?? ""
        if let avaTarImage = withRecentChat[kAVATAR] as? String {
            HelperClass.shared.imageFromData(withData: avaTarImage) { image in
                if image != nil {
                    self.chatImageView.image = image?.circleMasked
                }else{
                    self.chatImageView.image = UIImage.init(systemName: "person.circle")
                }
            }
        }
        if (withRecentChat[kCOUNTER] as? Int) != 0 {
            self.counterLabel.text = "\(withRecentChat[kCOUNTER] as? Int ?? 0)"
            self.chatView.isHidden = false
            self.counterLabel.isHidden = false
        }else{
            self.chatView.isHidden = true
            self.counterLabel.isHidden = true
        }
        
        let date : Date?
        if let createdDate = (withRecentChat[kDATE] as? String) {
            if createdDate.count != 14 {
                date = Date()
            }else{
                date = HelperClass.shared.dateFormatter().date(from: createdDate)
            }
        }else{
            date = Date()
        }
        self.dateLabel.text = HelperClass.shared.timeElapsed(date: date ?? Date())
        
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }
    
    static let cellId = "ChatTableViewCell"
    static func nib() -> UINib {
        return UINib(nibName: "ChatTableViewCell", bundle: nil)
    }

    
}
