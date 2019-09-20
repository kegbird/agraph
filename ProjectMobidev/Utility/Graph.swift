//
//  Graph.swift
//  ProjectMobidev
//
//  Created by Pietro Prebianca on 06/09/2019.
//  Copyright © 2019 Pietro Prebianca. All rights reserved.
//

import Foundation
import ARKit

/*
 This class is just a wrapper that implements and stores all features and information
 related to an ar graph objects.
*/

class Graph
{
    static let graphBitMask = 4
    
    static let removeButtonBitMask = 5
    
    static let pointBitMask = 10
    
    static let buttonOffset : Float = 0.045
    
    static let titleOffset : Float = 0.18

    static let placingColor = UIColor.yellow
    
    static let defaultColor = UIColor.white

    static let highlightColor = UIColor.red
    
    static let graphScale : Float = 0.15
    
    static let buttonScale : Float = 0.065
    
    static let titleScale : Float = 0.0075
    
    var graphNode : SCNNode!
    
    var titleNode : SCNNode!
    
    var relatedRemoveButtonNode : SCNNode!
    
    var points : [(Point, SCNNode)] = []
    
    init(title: String, points : [Point]) {

        if let graphScene = SCNScene(named: "art.scnassets/GraphModel.scn")
        {
            self.graphNode = graphScene.rootNode.childNodes.first!
            
            graphNode.categoryBitMask = Graph.graphBitMask
            
            graphNode.geometry!.firstMaterial!.multiply.contents = Graph.placingColor
            
            graphNode.scale = SCNVector3(x: 0, y: 0, z: 0)
            
            let removeButtonPlane = SCNPlane(width: 1, height: 1)
            
            let removeButtonMaterial = SCNMaterial()
            
            removeButtonMaterial.diffuse.contents = UIImage(named: "removeIcon")
            
            removeButtonPlane.materials = [removeButtonMaterial]
            
            relatedRemoveButtonNode = SCNNode(geometry: removeButtonPlane)
            
            relatedRemoveButtonNode.categoryBitMask = Graph.removeButtonBitMask
            
            relatedRemoveButtonNode.castsShadow = false
            
            relatedRemoveButtonNode.isHidden = true
            
            relatedRemoveButtonNode.opacity = 0
            
            relatedRemoveButtonNode.scale = SCNVector3(x: Graph.buttonScale, y: Graph.buttonScale, z: Graph.buttonScale)

            let billBoardCostraint = SCNBillboardConstraint()
            
            billBoardCostraint.freeAxes = .all
            
            relatedRemoveButtonNode.constraints = [billBoardCostraint]
        }
        else
        {
            return
        }
        
        //normalizzo i dati
        if points.count > 0
        {
            var maxX : Float = 0
            var maxY : Float = 0
            var maxZ : Float = 0
            
            var minX : Float = 0
            var minY : Float = 0
            var minZ : Float = 0
            
            if points.count != 1
            {
                maxX = (points.first?.position.x)!
                maxY = (points.first?.position.y)!
                maxZ = (points.first?.position.z)!
                
                minX = (points.first?.position.x)!
                minY = (points.first?.position.y)!
                minZ = (points.first?.position.z)!
                
                for point in points
                {
                    if maxX < point.position.x
                    {
                        maxX = point.position.x
                    }
                    
                    if maxY < point.position.y
                    {
                        maxY = point.position.y
                    }
                    
                    if maxZ < point.position.z
                    {
                        maxZ = point.position.z
                    }
                    
                    if minX > point.position.x
                    {
                        minX = point.position.x
                    }
                    
                    if minY > point.position.y
                    {
                        minY = point.position.y
                    }
                    
                    if minZ > point.position.z
                    {
                        minZ = point.position.z
                    }
                }
            }
            
            for point in points
            {
                var pointNormalizedPosition = point.position
                
                if (maxX - minX) != 0
                {
                    pointNormalizedPosition.x = 2*(point.position.x - minX) / (maxX - minX)
                }
                
                if (maxY - minY) != 0
                {
                    pointNormalizedPosition.y = 2*(point.position.y - minY) / (maxY - minY)
                }
                
                if (maxZ - minZ) != 0
                {
                    pointNormalizedPosition.z = 2*(point.position.z - minZ) / (maxZ - minZ)
                }
                
                if let pointScene = SCNScene(named: "art.scnassets/PointModel.scn")
                {
                    let pointNode = pointScene.rootNode.childNodes.first!
                    
                    pointNode.categoryBitMask = Graph.pointBitMask
                    
                    graphNode.addChildNode(pointNode)
                    
                    pointNode.geometry!.firstMaterial!.diffuse.contents = point.color
                    
                    pointNode.position = pointNormalizedPosition
                    
                    pointNode.position.x -= 1
                    pointNode.position.y -= 1
                    pointNode.position.z -= 1
                    
                    self.points.append((point, pointNode))
                }
            }
        }
    
        let scnTitleText = SCNText(string: title, extrusionDepth: CGFloat(3))
        
        let textMaterial = SCNMaterial()
        
        textMaterial.diffuse.contents = UIColor.white
        
        scnTitleText.materials = [textMaterial]
        
        titleNode = SCNNode()
        
        titleNode.geometry = scnTitleText
        
        titleNode.position = SCNVector3(0, 0, 0)
        
        titleNode.eulerAngles = SCNVector3(0, 0, 0)
        
        titleNode.scale = SCNVector3(0, 0, 0)
        
        titleNode.castsShadow = false
        
        let (min,max) = titleNode.boundingBox
        
        titleNode.pivot = SCNMatrix4MakeTranslation((max.x - min.x) / 2, 0, 0);
    }
    
    func getGraphNode() -> SCNNode
    {
        return graphNode
    }
    
    func getTitleNode() -> SCNNode
    {
        return titleNode
    }
    
    func runAppearAnimation()
    {
        guard graphNode.parent != nil else { return }
        
        let appearGraphAnimation = SCNAction.scale(to: CGFloat(Graph.graphScale), duration: 0.1)
        
        let appearTitleAnimation = SCNAction.scale(to: CGFloat(Graph.titleScale), duration: 0.1)
        
        appearGraphAnimation.timingMode = .easeIn
        
        appearTitleAnimation.timingMode = .easeIn
        
        graphNode.runAction(appearGraphAnimation)
        titleNode.runAction(appearTitleAnimation)
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
        graphNode.geometry?.firstMaterial!.multiply.contents = color
    }
    
    func getGraphWorldPosition() -> SCNVector3
    {
        return graphNode.worldPosition
    }
    
    func getGraphCurrentColor() -> UIColor
    {
        return graphNode.geometry!.materials.first?.multiply.contents as! UIColor
    }
    
    func getGraphScale() -> SCNVector3
    {
        return graphNode.scale
    }
    
    func runActionOnGraph(action : SCNAction)
    {
        graphNode.runAction(action)
    }
    
    func runActionOnRemoveButton(action : SCNAction)
    {
        relatedRemoveButtonNode.runAction(action)
    }
    
    func runActionOnTitle(action : SCNAction)
    {
        titleNode.runAction(action)
    }
    
    func highlightGraphNode()
    {
        let currentColor = graphNode.geometry!.firstMaterial!.multiply.contents as! UIColor
        
        let duration: TimeInterval = 0.2
        
        let colorAnimation = SCNAction.customAction(duration: duration) { (node, elapsedTime) -> () in
            let percentage = elapsedTime / CGFloat(duration)
            
            let (fromRed, fromGreen, fromBlue, _) = currentColor.getComponents()
            
            let (toRed, toGreen, toBlue, _) = Graph.highlightColor.getComponents()
            
            let finalColor = UIColor(red: fromRed*(1-percentage)+toRed*percentage, green: fromGreen*(1-percentage)+toGreen*percentage, blue: fromBlue*(1-percentage)+toBlue*percentage, alpha: 255/255)
            
            node.geometry!.firstMaterial!.multiply.contents = finalColor
        }
        
        let scaleAnimation : SCNAction
        var finalScale = graphNode.scale.x
        finalScale = finalScale * 1.25
        scaleAnimation = SCNAction.scale(to: CGFloat(finalScale) , duration: 0.1)
        
        graphNode.runAction(colorAnimation, forKey: "highlightScale")
        graphNode.runAction(scaleAnimation, forKey: "highlightColor")
    }
    
    func deselectGraphNode()
    {
        let currentColor = graphNode.geometry!.firstMaterial!.multiply.contents as! UIColor
        let duration: TimeInterval = 0.2
        
        let colorAnimation = SCNAction.customAction(duration: duration) { (node, elapsedTime) -> () in
            let percentage = elapsedTime / CGFloat(duration)
            
            let (fromRed, fromGreen, fromBlue, _) = currentColor.getComponents()
            
            let (toRed, toGreen, toBlue, _) = Graph.defaultColor.getComponents()
            
            let finalColor = UIColor(red: fromRed*(1-percentage)+toRed*percentage, green: fromGreen*(1-percentage)+toGreen*percentage, blue: fromBlue*(1-percentage)+toBlue*percentage, alpha: 255/255)
            
            node.geometry!.firstMaterial!.multiply.contents = finalColor
        }
        
        let scaleAnimation : SCNAction
        
        let finalScale = Graph.graphScale
        
        scaleAnimation = SCNAction.scale(to: CGFloat(finalScale) , duration: 0.1)
        
        graphNode.runAction(colorAnimation)
        graphNode.runAction(scaleAnimation)
    }
    
    func shakeGraph()
    {
        let appearRemoveButton = SCNAction.fadeOpacity(to: 1, duration: 0.1)
        
        let a1 = SCNAction.rotateBy(x: 0, y: 0, z: 0.1, duration: 0.075)
        let a2 = SCNAction.rotateBy(x: 0, y: 0, z: -0.1, duration: 0.075)
        let a3 = SCNAction.rotateBy(x: 0, y: 0, z: -0.1, duration: 0.075)
        let a4 = SCNAction.rotateBy(x: 0, y: 0, z: 0.1, duration: 0.075)
        let sequence = SCNAction.sequence([a1,a2,a3,a4])
        let animation = SCNAction.repeatForever(sequence)
        graphNode.runAction(animation, forKey: "shake")
        
        //mostro il suo remove button
        relatedRemoveButtonNode.isHidden = false
        relatedRemoveButtonNode.runAction(appearRemoveButton)
    }
    
    func stopShake()
    {
        let duration: TimeInterval = 0.1
        
        let hideRemoveGraphButton = SCNAction.customAction(duration: duration) { (node, elapsedTime) -> () in
            
            let percentage = elapsedTime / CGFloat(duration)
            
            if percentage == 1
            {
                node.opacity = 0
                node.isHidden=true
            }
            else
            {
                node.opacity = 1 * (1-percentage)
            }
            
        }
        
        graphNode.removeAction(forKey: "shake")
        graphNode.removeAction(forKey: "highlightScale")
        graphNode.removeAction(forKey: "highlightColor")
        graphNode.rotation = SCNVector4(x:0, y:0, z:0, w:0)
        graphNode.scale = SCNVector3(Graph.graphScale, Graph.graphScale, Graph.graphScale)
        graphNode.geometry!.firstMaterial!.multiply.contents = Graph.defaultColor
        relatedRemoveButtonNode.removeAllActions()
        relatedRemoveButtonNode.runAction(hideRemoveGraphButton)
    }
    
    func setParentNode(parent : SCNNode)
    {
        parent.addChildNode(graphNode)
        parent.addChildNode(relatedRemoveButtonNode)
        parent.addChildNode(titleNode)
    }
    
    func removeGraphFromScene()
    {
        guard graphNode.parent != nil else { return }
        
        graphNode.categoryBitMask = 6
        relatedRemoveButtonNode.categoryBitMask = 6
        
        let duration : TimeInterval = 0.2
        
        let fadeAnimation = SCNAction.customAction(duration: duration) { (node, elapsedTime) -> () in
            
            let percentage = elapsedTime / CGFloat(duration)
            
            if percentage == 1
            {
                node.geometry?.firstMaterial?.normal.contents = nil
                node.geometry?.firstMaterial?.diffuse.contents = nil
                node.removeFromParentNode()
            }
            else
            {
                node.opacity = 1 * (1 - percentage)
            }
            
        }

        graphNode.runAction(fadeAnimation)
        relatedRemoveButtonNode.runAction(fadeAnimation)
        titleNode.runAction(fadeAnimation)
    }
    
    func getPointsCoordinateForNode(pointNode : SCNNode) -> Point?
    {
        for p in points
        {
            if p.1 == pointNode
            {
                return p.0
            }
        }
        
        return nil
    }
    
    func setGraphWorldPosition(worldPosition : SCNVector3, distanceFromPlane : Float, scene : ARSCNView?)
    {
        guard scene != nil else { return }
        
        graphNode.worldPosition = worldPosition
        
        graphNode.position.z = distanceFromPlane
        
        var removeButtonWorldPosition = graphNode.convertPosition(graphNode.boundingBox.max, to: scene?.scene.rootNode)
        
        removeButtonWorldPosition.x += Graph.buttonOffset
        removeButtonWorldPosition.y += Graph.buttonOffset
        removeButtonWorldPosition.z -= Graph.buttonOffset
        
        relatedRemoveButtonNode.worldPosition = removeButtonWorldPosition
        
        var titlePosition = worldPosition
        titlePosition.z -= Graph.titleOffset
        
        titleNode.worldPosition = titlePosition
        
    }
}
