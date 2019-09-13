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
    
    func setGraphColor(color : UIColor)
    {
        node.geometry?.firstMaterial!.multiply.contents = color
    }
    
    func getGraphWorldPosition() -> SCNVector3
    {
        return node.worldPosition
    }
    
    func getGraphCurrentColor() -> UIColor
    {
        return node.geometry!.materials.first?.multiply.contents as! UIColor
    }
    
    func getGraphScale() -> SCNVector3
    {
        return node.scale
    }
    
    func runActionOnGraph(action : SCNAction)
    {
        node.runAction(action)
    }
    
    func setGraphWorldPosition(worldPosition : SCNVector3, distanceFromPlane : Float, scene : ARSCNView?)
    {
        guard scene != nil else { return }
        
        node.worldPosition = worldPosition
        
        node.position.z = distanceFromPlane
        
        let removeButtonWorldPosition = node.convertPosition(node.boundingBox.max, to: scene?.scene.rootNode)
        
        relatedRemoveButtonNode.worldPosition = removeButtonWorldPosition
    }
}
