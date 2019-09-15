//
//  UIRoundButton.swift
//  ProjectMobidev
//
//  Created by Pietro Prebianca on 13/08/2019.
//  Copyright © 2019 Pietro Prebianca. All rights reserved.
//

import Foundation
import UIKit

@IBDesignable
class UIRoundButton: UIButton
{
    @IBInspectable var cornerRadius: CGFloat = 0
    {
        didSet
        {
            self.layer.cornerRadius = cornerRadius
        }
    }
    
    @IBInspectable var borderWidth: CGFloat = 0
        {
        didSet
        {
            self.layer.borderWidth = borderWidth
        }
    }
    
    func innerCirclePath () -> UIBezierPath
    {
        return UIBezierPath(roundedRect: CGRect(x:8, y:8, width:50, height:50), cornerRadius: 25)
    }
    
    @IBInspectable var borderColor: UIColor = UIColor.clear
        {
        didSet
        {
            self.layer.borderColor = borderColor.cgColor
        }
    }
    
}
