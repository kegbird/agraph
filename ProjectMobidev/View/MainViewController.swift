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

class MainViewController: UIViewController, ARSCNViewDelegate {

    @IBOutlet var sceneView: ARSCNView!
    
    var editMode = false
    
    var initialPanDepth : CGFloat?
    
    var lastPanLocation : SCNVector3?
    
    var selectedObject : SCNNode?
    
    var graphs : [SCNNode?] = []
    
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
            displayWhitePlane(imageAnchor: imageAnchor, node: node)
        }
        
        return node
    }
    
    
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        
        if selectedObject != nil
        {
            selectedObject?.removeAllActions()
            hideSelectedObject()
            selectedObject = nil
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

    //
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        
        
    }
    
    //Gesture recognizer actions
    
    @IBAction func tapEvent(_ gestureRecognizer: UITapGestureRecognizer)
    {
        guard gestureRecognizer.view != nil else { return }
        print("touch")
    }
    
    @IBAction func panEvent(_ gestureRecognizer: UIPanGestureRecognizer)
    {
        guard gestureRecognizer.view != nil && editMode else { return }
        /*let location = gestureRecognizer.location(in: sceneView)
        
        switch gestureRecognizer.state {
        case .began:
            //Controllo se c'è qualcosa da muovere
            guard let hitTestResult = sceneView.hitTest(location, options: nil).first else { return }
            lastPanLocation = hitTestResult.worldCoordinates
            initialPanDepth = CGFloat(sceneView.projectPoint(lastPanLocation!).z)
            selectedObject = hitTestResult.node
            print(lastPanLocation)
        case .changed:
            let worldTouchPosition = sceneView.unprojectPoint(SCNVector3(location.x, location.y, initialPanDepth!))
            let movementVector = SCNVector3(
                worldTouchPosition.x - lastPanLocation!.x,
                worldTouchPosition.y - lastPanLocation!.y,
                worldTouchPosition.z - lastPanLocation!.z)
            selectedObject?.localTranslate(by: movementVector)
            self.lastPanLocation = worldTouchPosition
            print(lastPanLocation)
            break
        default:
            print("stop pan")
            break
        }*/
    }
    
    @IBAction func longPressEvent(_ gestureRecognizer: UILongPressGestureRecognizer)
    {
        switch gestureRecognizer.state {
        case .began:
            let location = gestureRecognizer.location(in: sceneView)
            let result = getTouchedObject(location: location)
            if isInteractiveObject(object: result)
            {
                editMode = true
                selectedObject = result?.node
                highlightSelectedObject()
                shakeAllObjects()
            }

            break
        case .ended:
            if selectedObject != nil
            {
                print("deselezionato")
                selectedObject?.removeAllActions()
                hideSelectedObject()
                selectedObject = nil
            }
            break
        case .changed:
            print("changed")
            break
        case .failed:
            print("failed")
            break
        default:
            print("default")
            break
        }
        /*if gestureRecognizer.state == .began
        {
            let touchLocation = gestureRecognizer.location(in: sceneView)
            let hitTest = sceneView?.hitTest(touchLocation, options: nil)
            
            if !hitTest!.isEmpty
            {
                print("Edit mode on")
                editMode = true
            }
        }*/
    }
    
    //Utility functions
    
    func shakeAllObjects()
    {
        for graph in graphs
        {
            let a1 = SCNAction.rotateBy(x: 0, y: 0, z: 0.1, duration: 0.05)
            let a2 = SCNAction.rotateBy(x: 0, y: 0, z: -0.1, duration: 0.05)
            let a3 = SCNAction.rotateBy(x: 0, y: 0, z: -0.1, duration: 0.05)
            let a4 = SCNAction.rotateBy(x: 0, y: 0, z: 0.1, duration: 0.05)
            let sequence = SCNAction.sequence([a1,a2,a3,a4])
            let animation = SCNAction.repeatForever(sequence)
            graph?.runAction(animation)
        }
    }
    
    func highlightSelectedObject()
    {
        guard selectedObject != nil else { return }
        
        let currentColor = selectedObject?.geometry?.materials.first?.diffuse.contents as! UIColor
        
        let selectedColor = UIColor(red: 1.0, green: 0.0, blue: 0.0, alpha: 1.0)
        
        let duration: TimeInterval = 0.2
        
        let animation = SCNAction.customAction(duration: duration, action: { (node, elapsedTime) in
            let percentage = elapsedTime / CGFloat(duration)
            node.geometry?.firstMaterial?.diffuse.contents = self.changeColor(from: currentColor, to: selectedColor, percentage: percentage)
        })
        
        selectedObject?.runAction(animation)
    }
    
    func hideSelectedObject()
    {
        
        let currentColor =  selectedObject?.geometry?.materials.first?.diffuse.contents as! UIColor
        
        let selectedColor = UIColor(red: 1.0, green: 1.0, blue: 1.0, alpha: 1.0)
        
        let duration: TimeInterval = 0.2
        
        let animation = SCNAction.customAction(duration: duration, action: { (node, elapsedTime) in
            let percentage = elapsedTime / CGFloat(duration)
            node.geometry?.firstMaterial?.diffuse.contents = self.changeColor(from: currentColor, to: selectedColor, percentage: percentage)
        })
        
        selectedObject?.runAction(animation)
    }
    
    func changeColor(from: UIColor, to: UIColor, percentage: CGFloat) -> UIColor {
        let fromComponents = from.cgColor.components!
        let toComponents = to.cgColor.components!
        let color = UIColor(red: fromComponents[0] + (toComponents[0] - fromComponents[0]) * percentage,
                            green: fromComponents[1] + (toComponents[1] - fromComponents[1]) * percentage,
                            blue: fromComponents[2] + (toComponents[2] - fromComponents[2]) * percentage,
                            alpha: fromComponents[3] + (toComponents[3] - fromComponents[3]) * percentage)
        return color
    }
    
    func displayWhitePlane(imageAnchor: ARImageAnchor, node: SCNNode)
    {
        DispatchQueue.main.async
        { [weak self] in
            let plane = SCNPlane(width: imageAnchor.referenceImage.physicalSize.width, height: imageAnchor.referenceImage.physicalSize.height)
            
            plane.firstMaterial?.diffuse.contents = UIColor(white: 1, alpha: 0.8)
            
            let planeNode = SCNNode(geometry: plane)
            
            planeNode.eulerAngles.x = -.pi/2
            
            node.addChildNode(planeNode)
            
            let (min, max) = planeNode.boundingBox
            
            let size = SCNVector3Make(max.x - min.x, max.y - min.y, max.z - min.z)
            
            let widthRatio = Float(imageAnchor.referenceImage.physicalSize.width)/size.x
            let heightRatio = Float(imageAnchor.referenceImage.physicalSize.height)/size.z
            // Pick smallest value to be sure that object fits into the image.
            let finalRatio = [widthRatio, heightRatio].min()!
            
            let appearAnimation = SCNAction.scale(to: CGFloat(finalRatio), duration: 0.4)
            
            appearAnimation.timingMode = .easeOut
            
            planeNode.scale = SCNVector3(0.001, 0.001, 0.001)
            
            planeNode.runAction(appearAnimation)
            if let shipScene = SCNScene(named: "art.scnassets/ship.scn")
            {
                 let shipNode = shipScene.rootNode.childNodes.first
                 shipNode?.position = SCNVector3Zero
                 shipNode?.position.z = 0.15
                 self?.graphs.append(shipNode)
                 planeNode.addChildNode(shipNode!)
            }
        }
    }
    
    func isInteractiveObject(object: SCNHitTestResult?) -> Bool
    {
        guard object != nil else { return false }
        guard let node = object?.node else { return false }
        
        if graphs.contains(node)
        {
            return true
        }
        
        return false
    }
    
    func getTouchedObject(location: CGPoint) -> SCNHitTestResult?
    {
        //let options = SCNHitTestOption(rawValue: SCNHitTestOption.firstFoundOnly.rawValue)
        //return sceneView.hitTest(po)
        return sceneView.hitTest(location, options: [SCNHitTestOption.firstFoundOnly:true]).first
    }
    
    func authorizeApp(){
        DropboxClientsManager.authorizeFromController(UIApplication.shared,
                                                      controller: self,
                                                      openURL: { (url: URL) -> Void in
                                                        UIApplication.shared.open(url, options: [:], completionHandler: nil)
        })
    }
}
