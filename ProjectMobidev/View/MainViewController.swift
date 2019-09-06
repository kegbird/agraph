//
//  ViewController.swift
//  ProjectMobidev
//
//  Created by Pietro Prebianca on 17/07/2019.
//  Copyright © 2019 Pietro Prebianca. All rights reserved.
//

import UIKit
import SceneKit
import ARKit
import SwiftyDropbox

class MainViewController: UIViewController, ARSCNViewDelegate, UIGestureRecognizerDelegate {
    
    @IBOutlet var sceneView: ARSCNView!
    
    var editMode = false
    
    var lastAdjustment = Double(0.0)
    
    var updateFrequency = Double(0.25)
    
    var lastPanLocation = SCNVector3(x: 0, y:0, z:0)
    
    var selectedObject : SCNNode?
    
    var originalScale = Float(0)
    
    var originalColor = UIColor.white
    
    var graphsToBePlaced : [String] = []
    
    var graphs : [Graph] = []
    
    var planeRoot : SCNNode!
    
    var planeNode : SCNNode!
    
    let distanceFromPlane : Float = 0.3
    
    let buttonScale = SCNVector3(x: 0.045, y: 0.045, z: 0.045)
    
    override var prefersStatusBarHidden: Bool
    {
        return true
    }
    
    //View Controller Events
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Set the view's delegate
        sceneView.delegate = self
        
        // Show statistics such as fps and timing information
        sceneView.showsStatistics = true
        
        sceneView.debugOptions = SCNDebugOptions.showWorldOrigin
        
        // Create a new scene
        let scene = SCNScene(named: "art.scnassets/GraphScene.scn")!

        // Set the scene to the view
        sceneView.scene = scene
    }
    
    override func viewWillAppear(_ animated: Bool) {
        
        super.viewWillAppear(animated)
        
        let configuration = ARWorldTrackingConfiguration()
        
        guard let trackedImages = ARReferenceImage.referenceImages(inGroupNamed: "Scheme", bundle: nil)
            else
        {
            print("No images available")
            return
        }
        
        configuration.detectionImages = trackedImages
        configuration.maximumNumberOfTrackedImages = 1
        
        // Run the view's session
        sceneView.session.run(configuration)
        
        loadOldGraphs()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        // Pause the view's session
        sceneView.session.pause()
    }
    
    //AR Events
    
    func renderer(_ renderer: SCNSceneRenderer, nodeFor anchor: ARAnchor) -> SCNNode? {
        
        let node = SCNNode()
        
        if let imageAnchor = anchor as? ARImageAnchor
        {
            displayReferencePlane(imageAnchor: imageAnchor, node: node)
        }
        
        return node
    }
    
    func renderer(_ renderer: SCNSceneRenderer, updateAtTime time: TimeInterval) {
        guard planeRoot != nil else { return }
        //ridurre la frequenza di aggiornamenti
        
        if time - lastAdjustment > updateFrequency
        {
            adjustCoordinateSystem()
            lastAdjustment = time
        }
    }
    
    //Input buttons
    
    @IBAction func btnAddTouchDown(_ sender: Any) {
        
        if Dropbox.getDropboxClient() == nil
        {
            authorizeApp()
        }
        else
        {
            self.performSegue(withIdentifier: "toDownloadFileListViewController", sender: nil)
            
            let appDelegate = UIApplication.shared.delegate as! AppDelegate
            
            appDelegate.graphs = graphs
            
            disableEditMode()
        }
    }
    
    @IBAction func btnTakePhotoTouchDown(_ sender: Any) {
        let snapShot = self.sceneView.snapshot()
        UIImageWriteToSavedPhotosAlbum(snapShot, self, #selector(saveImageCallback(_:didFinishSavingWithError:contextInfo:)), nil)
    }
    
    @objc func saveImageCallback(_ image: UIImage, didFinishSavingWithError error: Error?, contextInfo: UnsafeRawPointer) {
        
        if let error = error {
            print("Error Saving ARKit Scene \(error)")
        } else {
            print("ARKit Scene Successfully Saved")
        }
    }
    
    //Gesture recognizer actions
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        
        if editMode, let location = touches.first?.location(in: sceneView)
        {
            let result = sceneView.hitTest(location, options: nil).first
            
            guard let node = result?.node
            else
            {
                disableEditMode()
                return
            }
            
            if node.categoryBitMask == 5
            {
                let i = getRemoveButtonIndex(removeButton: node)
                
                guard i != -1 else { return }
                
                let removedGraph = graphs[i]
                
                graphs.remove(at: i)
                
                removedGraph.getNode().categoryBitMask = 6
                removedGraph.getRemoveButtonNode().categoryBitMask = 6

                let duration : TimeInterval = 0.2
                
                let fadeAnimation = SCNAction.customAction(duration: duration) { (node, elapsedTime) -> () in
                    
                    let percentage = elapsedTime / CGFloat(duration)
                    
                    if percentage == 1
                    {
                        node.removeFromParentNode()
                    }
                    else
                    {
                        node.opacity = 1 * (1 - percentage)
                    }
                    
                }
                
                removedGraph.getNode().runAction(fadeAnimation)
                removedGraph.getRemoveButtonNode().runAction(fadeAnimation)
            }
            else if node.categoryBitMask != 4
            {
                disableEditMode()
            }
        }
    }
    
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        
        if otherGestureRecognizer is UILongPressGestureRecognizer
        {
            return true
        }
        
        return false
    }
    
    @IBAction func panEvent(_ gestureRecognizer: UIPanGestureRecognizer)
    {
        guard gestureRecognizer.view != nil, planeRoot != nil, editMode, selectedObject != nil else { return }
        
        let location = gestureRecognizer.location(in: sceneView)
        
        switch gestureRecognizer.state {
        case .began:
            
            let hitTestResult = sceneView.hitTest(location, options: nil).first
            
            guard hitTestResult != nil else { return }
            
            lastPanLocation = getProjectedPoint(location: location)
            
            break
            
        case .changed:
            
            let currentPanLocation = getProjectedPoint(location: location)
            
            var movementVector = currentPanLocation
            
            movementVector.x -= lastPanLocation.x
            
            movementVector.z -= lastPanLocation.z
            
            var finalPosition = selectedObject!.worldPosition
            
            finalPosition.x += movementVector.x
            
            finalPosition.z += movementVector.z
            
            selectedObject?.worldPosition = finalPosition
            
            //aggiusto la profondità
            selectedObject?.position.z = distanceFromPlane
            
            let i = getGraphIndex(graph: selectedObject!)
                
            graphs[i].getRemoveButtonNode().worldPosition =  (selectedObject?.convertPosition((selectedObject?.boundingBox.max)!, to: sceneView.scene.rootNode))!
            
            lastPanLocation = currentPanLocation
            
            break
        default:
            print("stop pan")
            break
        }
    }
    
    @IBAction func longPressEvent(_ gestureRecognizer: UILongPressGestureRecognizer)
    {
        switch gestureRecognizer.state {
        case .began:
            let location = gestureRecognizer.location(in: sceneView)
            let result = sceneView.hitTest(location, options: [SCNHitTestOption.firstFoundOnly:true,SCNHitTestOption.categoryBitMask:4]).first
            
            guard result != nil else { return }
            
            selectedObject = result?.node
            highlightSelectedObject()
                
            if !editMode
            {
                print("edit mode on")
                editMode = true
                shakeAllObjects()
            }
            
            break
        case .changed:
            break
        case .ended:
            if selectedObject != nil
            {
                print("deselezionato")
                hideSelectedObject()
                selectedObject = nil
            }
            break
        case .failed:
            print("failed")
            break
        case .possible:
            print("possible")
            break
        default:
            print("default")
            break
        }
    }
    
    //Utility functions
    
    func addGraph()
    {
        if let shipScene = SCNScene(named: "art.scnassets/GraphModel.scn")
        {
            let graphNode = shipScene.rootNode.childNodes.first!
            
            graphNode.position = SCNVector3(x: 0, y: 0, z: distanceFromPlane)
            
            graphNode.categoryBitMask = 4
            
            planeNode.addChildNode(graphNode)
            
            let removeButtonPlane = SCNPlane(width: 1, height: 1)
            
            let removeButtonMaterial = SCNMaterial()
            
            removeButtonMaterial.diffuse.contents = UIImage(named: "removeIcon")
            
            removeButtonPlane.materials = [removeButtonMaterial]
            
            let removeButtonNode = SCNNode(geometry: removeButtonPlane)
            
            removeButtonNode.categoryBitMask = 5
            
            planeNode.addChildNode(removeButtonNode)
            
            removeButtonNode.isHidden = true
            
            removeButtonNode.opacity = 0
            
            removeButtonNode.scale = buttonScale
            
            removeButtonNode.worldPosition = graphNode.convertPosition(graphNode.boundingBox.max, to: sceneView.scene.rootNode)
            
            let billBoardCostraint = SCNBillboardConstraint()
            
            removeButtonNode.constraints = [billBoardCostraint]
        
            let newGraph = Graph(content: "", node: graphNode, relatedRemoveButtonNode: removeButtonNode)
            
            self.graphs.append(newGraph)
        }
    }
    
    func disableEditMode()
    {
        print("edit mode off")
        stopAllShakingObjects()
        editMode = false
        selectedObject = nil
        originalScale = 0
        originalColor = UIColor(red: 255/255, green: 255/255, blue: 255/255, alpha: 255/255)
        return
    }
    
    func getProjectedPoint(location: CGPoint) -> SCNVector3
    {
        guard var projectedPoint = sceneView.unprojectPoint(location, ontoPlane: simd_float4x4(planeRoot.transform)) else {
            return SCNVector3(x: 0, y: 0, z:0)
        }
        
        let referencePlaneTransform = simd_float4x4(planeRoot.worldTransform)
        
        let (_,normal,_,_) = referencePlaneTransform.columns
        
        //proietto il punto sul piano movimento
        projectedPoint.x += normal.x * distanceFromPlane
        projectedPoint.y += normal.y * distanceFromPlane
        projectedPoint.z += normal.z * distanceFromPlane
        
        let plane = planeRoot.childNodes.first!.geometry as! SCNPlane
        
        //calcolo min max tramite vettori del piano
        
        var worldMax = planeRoot.worldPosition
        var worldMin = planeRoot.worldPosition
        
        worldMax.x += planeRoot.worldRight.x * Float(plane.width/2)
        worldMax.y += planeRoot.worldRight.y * Float(plane.width/2)
        worldMax.z += planeRoot.worldRight.z * Float(plane.width/2)
        
        worldMax.x += planeRoot.worldFront.x * Float(plane.width/2)
        worldMax.y += planeRoot.worldFront.y * Float(plane.width/2)
        worldMax.z += planeRoot.worldFront.z * Float(plane.width/2)
        
        worldMin.x -= planeRoot.worldRight.x * Float(plane.width/2)
        worldMin.y -= planeRoot.worldRight.y * Float(plane.width/2)
        worldMin.z -= planeRoot.worldRight.z * Float(plane.width/2)
        
        worldMin.x -= planeRoot.worldFront.x * Float(plane.width/2)
        worldMin.y -= planeRoot.worldFront.y * Float(plane.width/2)
        worldMin.z -= planeRoot.worldFront.z * Float(plane.width/2)
        
        worldMax.x += normal.x * distanceFromPlane
        worldMax.y += normal.y * distanceFromPlane
        worldMax.z += normal.z * distanceFromPlane
        
        worldMin.x += normal.x * distanceFromPlane
        worldMin.y += normal.y * distanceFromPlane
        worldMin.z += normal.z * distanceFromPlane
        
        //clamp
        projectedPoint.x = simd_clamp(projectedPoint.x, worldMin.x, worldMax.x)
        
        projectedPoint.z = simd_clamp(projectedPoint.z, -worldMin.z, -worldMax.z)
    
        return SCNVector3(projectedPoint)
    }
    
    func shakeAllObjects()
    {
        var i = 0
        
        let appearRemoveButton = SCNAction.fadeOpacity(to: 1, duration: 0.2)
        
        for graph in graphs
        {
            let a1 = SCNAction.rotateBy(x: 0, y: 0, z: 0.1, duration: 0.075)
            let a2 = SCNAction.rotateBy(x: 0, y: 0, z: -0.1, duration: 0.075)
            let a3 = SCNAction.rotateBy(x: 0, y: 0, z: -0.1, duration: 0.075)
            let a4 = SCNAction.rotateBy(x: 0, y: 0, z: 0.1, duration: 0.075)
            let sequence = SCNAction.sequence([a1,a2,a3,a4])
            let animation = SCNAction.repeatForever(sequence)
            graph.getNode().runAction(animation, forKey: "shake")
            //mostro il suo remove button
            graph.getRemoveButtonNode().isHidden = false
            graph.getRemoveButtonNode().runAction(appearRemoveButton)
            i=i+1
        }
    }
    
    func stopAllShakingObjects()
    {
        var i = 0
        
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
        
        for graph in graphs
        {
            let graphNode = graph.getNode()
            let removeButtonNode = graph.getRemoveButtonNode()
            graphNode.removeAction(forKey: "shake")
            graphNode.rotation = SCNVector4(x:0, y:0, z:0, w:0)
            removeButtonNode.removeAllActions()
            removeButtonNode.runAction(hideRemoveGraphButton)
            i=i+1
        }
    }
    
    func highlightSelectedObject()
    {
        guard selectedObject != nil else { return }
        
        let currentColor = selectedObject?.geometry?.materials.first?.multiply.contents as! UIColor
        
        originalColor = currentColor
        
        let selectedColor = UIColor(red: 255/255, green: 0/255, blue: 0/255, alpha: 255/255)
        
        let duration: TimeInterval = 0.2
        
        let colorAnimation = SCNAction.customAction(duration: duration) { (node, elapsedTime) -> () in
            let percentage = elapsedTime / CGFloat(duration)
            
            let (fromRed, fromGreen, fromBlue, _) = currentColor.getComponents()
            
            let (toRed, toGreen, toBlue, _) = selectedColor.getComponents()
            
            let finalColor = UIColor(red: fromRed*(1-percentage)+toRed*percentage, green: fromGreen*(1-percentage)+toGreen*percentage, blue: fromBlue*(1-percentage)+toBlue*percentage, alpha: 255/255)
            
            node.geometry!.firstMaterial!.multiply.contents = finalColor
        }
        
        let scaleAnimation : SCNAction
        
        originalScale = Float(selectedObject?.scale.x ?? 1)
        
        var finalScale = selectedObject?.scale.x ?? 1
        finalScale = finalScale * 1.25
        scaleAnimation = SCNAction.scale(to: CGFloat(finalScale) , duration: 0.1)
        
        selectedObject?.runAction(colorAnimation)
        selectedObject?.runAction(scaleAnimation)
    }
    
    func hideSelectedObject()
    {
        let currentColor =  selectedObject?.geometry?.materials.first?.multiply.contents as! UIColor
            
        let duration: TimeInterval = 0.2
            
        let colorAnimation = SCNAction.customAction(duration: duration) { (node, elapsedTime) -> () in
            let percentage = elapsedTime / CGFloat(duration)
                
            let (fromRed, fromGreen, fromBlue, _) = currentColor.getComponents()
                
            let (toRed, toGreen, toBlue, _) = self.originalColor.getComponents()
                
            let finalColor = UIColor(red: fromRed*(1-percentage)+toRed*percentage, green: fromGreen*(1-percentage)+toGreen*percentage, blue: fromBlue*(1-percentage)+toBlue*percentage, alpha: 255/255)
            
            node.geometry!.firstMaterial!.multiply.contents = finalColor
        }
        
        let scaleAnimation : SCNAction
        
        let finalScale = originalScale
        
        scaleAnimation = SCNAction.scale(to: CGFloat(finalScale) , duration: 0.1)
        
        selectedObject?.runAction(colorAnimation)
        selectedObject?.runAction(scaleAnimation)
    }
    
    func adjustCoordinateSystem()
    {
        let transform = simd_float4x4(planeRoot.transform)
        self.sceneView.session.setWorldOrigin(relativeTransform: transform)
    }
    
    func displayReferencePlane(imageAnchor: ARImageAnchor, node: SCNNode)
    {
        DispatchQueue.main.async
            { [weak self] in
                let plane = SCNPlane(width: imageAnchor.referenceImage.physicalSize.width, height: imageAnchor.referenceImage.physicalSize.height)
                
                plane.firstMaterial?.diffuse.contents = UIColor(red: 0/255, green: 0/255, blue: 0/255, alpha: 0.8)
                
                let planeNode = SCNNode(geometry: plane)
                
                planeNode.eulerAngles.x = -.pi/2
                
                node.addChildNode(planeNode)
                
                node.opacity = CGFloat(0)
                
                node.categoryBitMask = 0
                
                let appearAnimation = SCNAction.fadeOpacity(to: 1.0, duration: 0.35)
                
                appearAnimation.timingMode = .easeOut
                
                self?.planeNode = planeNode
                
                self?.renderOldGraphs()
                
                //self?.addGraph()
                
                node.runAction(appearAnimation)
                
                self?.planeRoot = node
        }
    }
    
    func getGraphIndex(graph: SCNNode) -> Int
    {
        var i = 0
        for g in graphs
        {
            if graph == g.getNode()
            {
                return i
            }
            
            i = i+1
        }
        
        return -1
    }
    
    func getRemoveButtonIndex(removeButton: SCNNode) -> Int
    {
        var i = 0
        for g in graphs
        {
            if removeButton == g.getRemoveButtonNode()
            {
                return i
            }
            
            i = i+1
        }
        
        return -1
    }
    
    func authorizeApp(){
        DropboxClientsManager.authorizeFromController(UIApplication.shared,
                                                      controller: self,
                                                      openURL: { (url: URL) -> Void in
                                                        UIApplication.shared.open(url, options: [:], completionHandler: nil)
        })
    }
    
    // AR persistency
    
    func loadOldGraphs()
    {
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        
        if appDelegate.graphs.count != 0
        {
            graphs = appDelegate.graphs
            appDelegate.graphs.removeAll()
        }
    }
    
    func renderOldGraphs()
    {
        for graph in graphs
        {
            planeNode.addChildNode(graph.getNode())
            planeNode.addChildNode(graph.getRemoveButtonNode())
        }
    }
}
