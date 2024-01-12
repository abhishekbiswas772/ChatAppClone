//
//  PhotoMediaItem.swift
//  whatsappApp
//
//  Created by Abhishek Biswas on 12/01/24.
//

import Foundation
import JSQMessagesViewController

class PhotoMediaItem : JSQPhotoMediaItem{
    override func mediaViewDisplaySize() -> CGSize {
        let defaultSize : CGFloat = 256.0
        var thumbSize : CGSize = CGSize(width: defaultSize, height: defaultSize)
        if (self.image != nil) && (self.image.size.height > 0) && (self.image.size.width > 0){
            let aspect : CGFloat = self.image.size.width / self.image.size.height
            if self.image.size.width > self.image.size.height {
                thumbSize = CGSize(width: defaultSize, height: defaultSize / aspect)
            }else{
                thumbSize = CGSize(width: defaultSize * aspect, height: defaultSize )
            }
        }
        return thumbSize
    }
}


class VideoMessge : JSQPhotoMediaItem {
    var videoImage : UIImage?
    var videoImageView : UIImageView?
    var status : Int?
    var fileURl : NSURL?
    
    init(withFileURl : NSURL, maskOutgoing: Bool) {
        super.init(maskAsOutgoing: maskOutgoing)
        self.fileURl = withFileURl
        self.videoImageView = nil
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init coder has not been implemented")
    }
    
    override func mediaView() -> UIView! {
        if let statusLocal = self.status {
            if statusLocal == 1 {
                return nil
            } else if statusLocal == 2 && (self.videoImageView == nil) {
                let size = self.mediaViewDisplaySize()
                let outgoing = self.appliesMediaViewMaskAsOutgoing
                let icon = UIImage.jsq_defaultPlay().jsq_imageMasked(with: .white)
                let iconView = UIImageView(image: icon)
                iconView.frame = CGRect(x: 0, y: 0, width: size.width, height: size.height)
                iconView.contentMode = .center
                let imgView = UIImageView(image: self.videoImage ?? UIImage())
                imgView.frame = CGRect(x: 0, y: 0, width: size.width, height: size.height)
                imgView.contentMode = .scaleAspectFill
                imgView.clipsToBounds = true
                imgView.addSubview(iconView)
                JSQMessagesMediaViewBubbleImageMasker.applyBubbleImageMask(toMediaView: imgView, isOutgoing: outgoing)
                self.videoImageView = imgView
            }
        }
        return self.videoImageView
    }
}



