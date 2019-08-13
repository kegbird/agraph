//
//  Point.swift
//  ProjectMobidev
//
//  Created by Pietro Prebianca on 01/08/2019.
//  Copyright © 2019 Pietro Prebianca. All rights reserved.
//

import Foundation
import UIKit.UIColor

struct Point
{
    var x: Float
    var y: Float
    var z: Float
    
    var color: UIColor
    
    
    init(x: Float, y: Float, z: Float, r: Int, g: Int, b: Int) {
        self.x = x
        self.y = y
        self.z = z
        
        self.color = UIColor(red: CGFloat(r), green: CGFloat(g), blue: CGFloat(b), alpha: CGFloat(125))
    }
}
