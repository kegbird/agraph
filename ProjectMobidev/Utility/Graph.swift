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
    var title : String
    
    var node : SCNNode!
    
    var relatedRemoveButtonNode : SCNNode!
    
    var points : [Point] = []
    
    init(title: String, points : [Point]) {
        
        self.title = title
        self.points = points
        
        //normalizzo i dati
        if points.count > 0
        {
            var maxX = points.first?.position.x
            var maxY = points.first?.position.y
            var maxZ = points.first?.position.z
            
            var minX = points.first?.position.x
            var minY = points.first?.position.y
            var minZ = points.first?.position.z
            
            for point in points
            {
                if maxX! < point.position.x
                {
                    maxX = point.position.x
                }
                
                if maxY! < point.position.y
                {
                    maxY = point.position.y
                }
                
                if maxZ! < point.position.z
                {
                    maxZ = point.position.z
                }
                
                if minX! > point.position.x
                {
                    minX = point.position.x
                }
                
                if minY! > point.position.y
                {
                    minY = point.position.y
                }
                
                if minZ! > point.position.z
                {
                    minZ! = point.position.z
                }
            }
            
            for point in points
            {
                point.position.x = (point.position.x - minX!) / (maxX! - minX!)
                point.position.y = (point.position.y - minY!) / (maxY! - minY!)
                point.position.z = (point.position.z - minZ!) / (maxZ! - minZ!)
            }
        }
    }
    
    func setNode(node: SCNNode)
    {
        self.node = node
    }
    
    func getPoints() -> [Point]
    {
        return points
    }
    
    func getNode() -> SCNNode
    {
        return node
    }
    
    func setRemoveButtonNode(relatedRemoveButtonNode: SCNNode)
    {
        self.relatedRemoveButtonNode = relatedRemoveButtonNode
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
