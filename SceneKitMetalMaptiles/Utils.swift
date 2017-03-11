//
//  Utils.swift
//  SceneKitMetalMaptiles
//
//  Created by Lachlan Hurst on 12/3/17.
//  Copyright © 2017 Lachlan Hurst. All rights reserved.
//

import Foundation
import UIKit

class Utils {

    static func textToImage(_ drawText: String, size: CGSize, atPoint:CGPoint) -> UIImage {

        // Setup the font specific variables
        let textColor: UIColor = UIColor.white
        let textFont: UIFont = UIFont(name: "Avenir-Book", size: 14)!

        //Setup the image context using the passed image.
        UIGraphicsBeginImageContextWithOptions(size, false, 0.0)

        let c = UIGraphicsGetCurrentContext();

        let paragraphStyle = NSParagraphStyle.default.mutableCopy() as! NSMutableParagraphStyle
        paragraphStyle.lineBreakMode = .byTruncatingTail
        paragraphStyle.alignment = .right

        //Setups up the font attributes that will be later used to dictate how the text should be drawn
        let textFontAttributes = [
            NSFontAttributeName: textFont,
            NSForegroundColorAttributeName: textColor,
            NSParagraphStyleAttributeName: paragraphStyle
        ]

        // Creating a point within the space that is as bit as the image.
        let rect: CGRect = CGRect(x: atPoint.x, y: atPoint.y, width: size.width, height: size.height)
        c?.setFillColor(UIColor.black.withAlphaComponent(0.7).cgColor)
        c?.fill(rect)


        //Now Draw the text into an image.
        let textRect = CGRect(x: atPoint.x, y: atPoint.y, width: size.width - 5, height: size.height)
        drawText.draw(in: textRect, withAttributes: textFontAttributes)

        // Create a new image out of the images we have created
        let newImage: UIImage = UIGraphicsGetImageFromCurrentImageContext()!

        // End the context now that we have the image we need
        UIGraphicsEndImageContext()

        //And pass it back up to the caller.
        return newImage
        
    }

    static func colourForIndex(index:Int) -> UIColor {
        // from http://colorbrewer2.org/#type=qualitative&scheme=Pastel1&n=7
        let arr = ["#fbb4ae", "#b3cde3", "#ccebc5", "#decbe4", "#fed9a6", "#ffffcc", "#e5d8bd"]
        let arrIndex = index % arr.count
        return hexStringToUIColor(hex:arr[arrIndex])
    }

    static func hexStringToUIColor (hex:String) -> UIColor {
        var cString:String = hex.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()

        if (cString.hasPrefix("#")) {
            cString.remove(at: cString.startIndex)
        }

        if ((cString.characters.count) != 6) {
            return UIColor.gray
        }

        var rgbValue:UInt32 = 0
        Scanner(string: cString).scanHexInt32(&rgbValue)

        return UIColor(
            red: CGFloat((rgbValue & 0xFF0000) >> 16) / 255.0,
            green: CGFloat((rgbValue & 0x00FF00) >> 8) / 255.0,
            blue: CGFloat(rgbValue & 0x0000FF) / 255.0,
            alpha: CGFloat(1.0)
        )
    }

}
