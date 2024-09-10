import Foundation
import UIKit

extension Double {
    func asCurrencyString() -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = Locale.current
        return formatter.string(from: NSNumber(value: self)) ?? "$0.00"
    }
}

extension UIImage {
    func squareImage() -> UIImage {
        let originalWidth = self.size.width
        let originalHeight = self.size.height
        let minLength = min(originalWidth, originalHeight)
        
        let cropRect = CGRect(
            x: (originalWidth - minLength) / 2,
            y: (originalHeight - minLength) / 2,
            width: minLength,
            height: minLength
        )
        
        if let cgImage = self.cgImage?.cropping(to: cropRect) {
            return UIImage(cgImage: cgImage, scale: self.scale, orientation: self.imageOrientation)
        }
        
        return self
    }
}