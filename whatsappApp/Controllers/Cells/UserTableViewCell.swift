//
//  UserTableViewCell.swift
//  whatsappApp
//
//  Created by Abhishek Biswas on 08/01/24.
//

import UIKit

protocol UserTableViewCellDelegate {
    func didTapAvatarImage(withIndexPath : IndexPath)
}

class UserTableViewCell: UITableViewCell {

    @IBOutlet weak var imageProfile: UIImageView!
    @IBOutlet weak var profileName: UILabel!
    
    static let cellId : String = "UserTableViewCell"
    var indexPath : IndexPath?
    var tapGesture : UITapGestureRecognizer?
    var delegate : UserTableViewCellDelegate?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        tapGesture = UITapGestureRecognizer()
        tapGesture?.addTarget(self, action: #selector(tagGestureAction(_ :)))
        self.imageProfile.isUserInteractionEnabled = true
        self.imageProfile.addGestureRecognizer(tapGesture ?? UITapGestureRecognizer())
    }
    
    @objc func tagGestureAction(_ sender: UITapGestureRecognizer) {
        if let indexPath = self.indexPath {
            delegate?.didTapAvatarImage(withIndexPath: indexPath)
        }
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }
    
    public static func nib() -> UINib {
        return UINib(nibName: "UserTableViewCell", bundle: nil)
    }
    
    public func genrateCell(withUser: FirebaseUser, index: IndexPath) {
        self.profileName.text = withUser.fullname
        self.indexPath = index
        guard let avatarResult = withUser.avatar else {return}
        if !avatarResult.isEmpty {
            HelperClass.shared.imageFromData(withData: withUser.avatar ?? "") { image in
                if image != nil {
                    DispatchQueue.main.async {
                        self.imageProfile.image = image?.circleMasked
                    }
                }
            }
        }
    }
}
