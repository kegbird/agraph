//
//  Graph.swift
//  ProjectMobidev
//
//  Created by Pietro Prebianca on 06/09/2019.
//  Copyright © 2019 Pietro Prebianca. All rights reserved.
//

import Foundation
import ARKit

class Graph
{
    var node : SCNNode!
    
    var relatedRemoveButtonNode : SCNNode!
    
    var points : [Point]!
    
    init(content:String, node: SCNNode, relatedRemoveButtonNode: SCNNode) {

        self.node = node
        self.relatedRemoveButtonNode = relatedRemoveButtonNode
    }
    
    func getNode() -> SCNNode
    {
        return node
    }
    
    func getRemoveButtonNode() -> SCNNode
    {
        return relatedRemoveButtonNode
    }
}
