//
//  Helpers.swift
//  whatsappApp
//
//  Created by Abhishek Biswas on 05/01/24.
//

import Foundation
import FirebaseFirestore
import UIKit

final class HelperClass {
    static let shared = HelperClass()
    private let dateFormat = "yyyyMMddHHmmss"
    
    public func dateFormatter() -> DateFormatter {
        let dateFormatter = DateFormatter()
        dateFormatter.timeZone = TimeZone(secondsFromGMT: TimeZone.current.secondsFromGMT())
        dateFormatter.dateFormat = self.dateFormat
        return dateFormatter
    }
    
    
    
    public func imageFromData(withData: String, onCompleation: @escaping(_ image: UIImage?) -> Void) {
        var img : UIImage?
        let decodedData = NSData(base64Encoded: withData, options: NSData.Base64DecodingOptions(rawValue: 0))
        if let image = UIImage(data: (decodedData as? Data) ?? Data()) {
            img = image
            onCompleation(img)
        }else{
            onCompleation(nil)
        }
    }
    
    public func imageFromInitials(withFirstName : String, lastName : String, withCompleation: @escaping(_ image : UIImage) -> Void?) {
        var string : String?
        var size = 36
        if withFirstName.isEmpty && lastName.isEmpty {
            string = (withFirstName.first?.uppercased() ?? "A") + (lastName.first?.uppercased() ?? "B")
        }else{
            string = withFirstName.first?.uppercased() ?? "A"
            size = 72
        }
        
        let lblNameInitialize = UILabel()
        lblNameInitialize.frame.size = CGSize(width: 100, height: 100)
        lblNameInitialize.textColor = .white
        lblNameInitialize.font = UIFont(name: lblNameInitialize.font.fontName, size: CGFloat(size))
        lblNameInitialize.text = string
        lblNameInitialize.textAlignment = NSTextAlignment.center
        lblNameInitialize.backgroundColor = UIColor.lightGray
        lblNameInitialize.layer.cornerRadius = 25
        
        UIGraphicsBeginImageContext(lblNameInitialize.frame.size)
        lblNameInitialize.layer.render(in: UIGraphicsGetCurrentContext()!)
        
        let img = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        withCompleation(img ?? UIImage())
    }
    
    public func timeElapsed(date: Date) -> String {
        let seconds = NSDate().timeIntervalSince(date)
        var elapsed: String?
        if (seconds < 60) {
            elapsed = "Just now"
        } else if (seconds < 60 * 60) {
            let minutes = Int(seconds / 60)
            var minText = "min"
            if minutes > 1 {
                minText = "mins"
            }
            elapsed = "\(minutes) \(minText)"
            
        } else if (seconds < 24 * 60 * 60) {
            let hours = Int(seconds / (60 * 60))
            var hourText = "hour"
            if hours > 1 {
                hourText = "hours"
            }
            elapsed = "\(hours) \(hourText)"
        } else {
            let currentDateFormater = self.dateFormatter()
            currentDateFormater.dateFormat = "dd/MM/YYYY"
            elapsed = "\(currentDateFormater.string(from: date))"
        }
        return elapsed!
    }

    func formatCallTime(date: Date) -> String {
        let seconds = NSDate().timeIntervalSince(date)
        var elapsed: String?
        if (seconds < 60) {
            elapsed = "Just now"
        }  else if (seconds < 24 * 60 * 60) {
            let currentDateFormater = self.dateFormatter()
            currentDateFormater.dateFormat = "HH:mm"
            elapsed = "\(currentDateFormater.string(from: date))"
        } else {
            let currentDateFormater = self.dateFormatter()
            currentDateFormater.dateFormat = "dd/MM/YYYY"
            elapsed = "\(currentDateFormater.string(from: date))"
        }
        return elapsed!
    }

}



extension UIImage {
    
    var isPortrait:  Bool    { return size.height > size.width }
    var isLandscape: Bool    { return size.width > size.height }
    var breadth:     CGFloat { return min(size.width, size.height) }
    var breadthSize: CGSize  { return CGSize(width: breadth, height: breadth) }
    var breadthRect: CGRect  { return CGRect(origin: .zero, size: breadthSize) }
    
    var circleMasked: UIImage? {
        UIGraphicsBeginImageContextWithOptions(breadthSize, false, scale)
        defer { UIGraphicsEndImageContext() }
        guard let cgImage = cgImage?.cropping(to: CGRect(origin: CGPoint(x: isLandscape ? floor((size.width - size.height) / 2) : 0, y: isPortrait  ? floor((size.height - size.width) / 2) : 0), size: breadthSize)) else { return nil }
        UIBezierPath(ovalIn: breadthRect).addClip()
        UIImage(cgImage: cgImage).draw(in: breadthRect)
        return UIGraphicsGetImageFromCurrentImageContext()
    }
    
    
    
    func scaleImageToSize(newSize: CGSize) -> UIImage {
        var scaledImageRect = CGRect.zero
        
        let aspectWidth = newSize.width/size.width
        let aspectheight = newSize.height/size.height
        
        let aspectRatio = max(aspectWidth, aspectheight)
        
        scaledImageRect.size.width = size.width * aspectRatio;
        scaledImageRect.size.height = size.height * aspectRatio;
        scaledImageRect.origin.x = (newSize.width - scaledImageRect.size.width) / 2.0;
        scaledImageRect.origin.y = (newSize.height - scaledImageRect.size.height) / 2.0;
        
        UIGraphicsBeginImageContext(newSize)
        draw(in: scaledImageRect)
        let scaledImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return scaledImage!
    }
}
