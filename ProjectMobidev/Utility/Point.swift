//
//  Point.swift
//  ProjectMobidev
//
//  Created by Pietro Prebianca on 06/09/2019.
//  Copyright © 2019 Pietro Prebianca. All rights reserved.
//

import Foundation
import ARKit

class Point
{
    var position : SCNVector3
    var color : UIColor
    
    init(position : SCNVector3, color : UIColor) {
        self.position = position
        self.color = color
    }
}
