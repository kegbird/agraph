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
    static var offset : Float = 0.045
    
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
                
                if point.position.x.isNaN
                {
                    point.position.x = 0
                }
                if point.position.y.isNaN
                {
                    point.position.y = 0
                }
                if point.position.z.isNaN
                {
                    point.position.z = 0
                }
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
    
    func add3dTitle()
    {
        let arTitle = SCNText(string: title, extrusionDepth: CGFloat(5))
        
        let textMaterial = SCNMaterial()
        
        textMaterial.diffuse.contents = UIColor.white
        
        arTitle.materials = [textMaterial]
        
        let arTitleNode = SCNNode()
        
        arTitleNode.geometry = arTitle
        
        node.addChildNode(arTitleNode)
        
        arTitleNode.position = SCNVector3(0, 1, 0)
        
        let (_,max) = arTitleNode.boundingBox
        
        arTitleNode.position.x -= (max.x/2) * arTitleNode.scale.x
        
        arTitleNode.scale = SCNVector3(0.05,0.05,0.05)
    }
    
    func addPointsToScene()
    {
        for point in points
        {
            if let pointScene = SCNScene(named: "art.scnassets/PointModel.scn")
            {
                let pointNode = pointScene.rootNode.childNodes.first!
                
                node.addChildNode(pointNode)
                
                pointNode.geometry!.firstMaterial!.diffuse.contents = point.color
                
                let (min,max) = node.boundingBox
                
                var diagonal = SCNVector3(x: max.x - min.x, y: max.y - min.y, z: max.z - min.z)
                
                diagonal.x = (point.position.x * diagonal.x) - diagonal.x * 0.5
                diagonal.y = (point.position.y * diagonal.y) - diagonal.y * 0.5
                diagonal.z = (point.position.z * diagonal.z) - diagonal.z * 0.5
                
                pointNode.position = diagonal
            }
        }
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
        
        var removeButtonWorldPosition = node.convertPosition(node.boundingBox.max, to: scene?.scene.rootNode)
        
        removeButtonWorldPosition.x += Graph.offset
        removeButtonWorldPosition.y += Graph.offset
        removeButtonWorldPosition.z -= Graph.offset
        
        relatedRemoveButtonNode.worldPosition = removeButtonWorldPosition
    }
}
