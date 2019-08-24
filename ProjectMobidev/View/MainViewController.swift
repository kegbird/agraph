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
    
    //var initialPanDepth : CGFloat?
    
    var lastPanLocation : SCNVector3!
    
    var selectedObject : SCNNode?
    
    var originalScale = Float(0)
    
    var originalColor = UIColor.white
    
    var graphs : [SCNNode?] = []
    
    var initialPanDepth : CGFloat?
    
    var referencePlaneNode : SCNNode!
    
    var minBound = SCNVector3(x:0, y:0, z:0)
    
    var maxBound = SCNVector3(x:0, y:0, z:0)
    
    let distanceFromPlane : Float = 0.15
    
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
        
        if editMode, let location = touches.first?.location(in: sceneView)
        {
            if !isInteractiveObject(object: getTouchedObject(location: location))
            {
                print("edit mode off")
                stopAllShakingObjects()
                editMode = false
                selectedObject = nil
                originalScale = 0
                originalColor = UIColor(red: 255/255, green: 255/255, blue: 255/255, alpha: 255/255)
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
    
    //Gesture recognizer actions
    
    @IBAction func panEvent(_ gestureRecognizer: UIPanGestureRecognizer)
    {
        guard gestureRecognizer.view != nil, referencePlaneNode != nil else { return }
        
        let location = gestureRecognizer.location(in: sceneView)
        let hitTestResult = sceneView.hitTest(location, options: nil).first
        
        switch gestureRecognizer.state {
        case .began:
            //Controllo se c'è qualcosa da muovere
            guard editMode, selectedObject != nil else { return }
            lastPanLocation = hitTestResult!.worldCoordinates
            initialPanDepth = CGFloat(sceneView.projectPoint(lastPanLocation!).z)
            
        case .changed:
            guard editMode, selectedObject != nil else { return }
            
            let worldTouchPosition = sceneView.unprojectPoint(SCNVector3(location.x, location.y, initialPanDepth!))
            
            let movementVector = SCNVector3(
                worldTouchPosition.x - lastPanLocation!.x,
                worldTouchPosition.y - lastPanLocation!.y,
                0)
            
            
            if var finalPosition = selectedObject?.position
            {
                finalPosition.x = simd_clamp(movementVector.x + finalPosition.x, minBound.x, maxBound.x)
                
                finalPosition.y = simd_clamp(movementVector.y + finalPosition.y, minBound.y, maxBound.y)
                
                selectedObject?.position = finalPosition
            }
            
            self.lastPanLocation = worldTouchPosition
            
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
            let result = getTouchedObject(location: location)
            if isInteractiveObject(object: result)
            {
                selectedObject = result?.node
                highlightSelectedObject()
                
                if !editMode
                {
                    print("edit mode on")
                    editMode = true
                    shakeAllObjects()
                }
            }

            break
        case .ended:
            if selectedObject != nil
            {
                print("deselezionato")
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
        case .possible:
            print("possible")
            break
        default:
            print("default")
            break
        }
    }
    
    //Utility functions
    
    func getPlaneNormal() -> SCNVector3
    {
        let (min,max) = referencePlaneNode.boundingBox.self
        
        let normal = SCNVector3(x: max.y * min.z - max.z * min.y,
                                y: max.z * min.x - max.x * min.z,
                                z: max.x * min.y - max.y * min.x)
        
        print(normal)
        
        return normal
    }
    
    /*func calculateTranslation(hitTestResult: SCNHitTestResult) -> SCNVector3
    {
        /*var normalPlane = SCNVector4(0,0,1,0)
        
        let dotProd = normalPlane.x*movementVector.x + normalPlane.y*movementVector.y + normalPlane.z*movementVector.z
        
        normalPlane.x=normalPlane.x*dotProd
        
        normalPlane.y=normalPlane.y*dotProd
        
        normalPlane.z=normalPlane.z*dotProd
        
        let projection = SCNVector3(movementVector.x - normalPlane.x, movementVector.y - normalPlane.y, movementVector.z - normalPlane.z)*/
        
        /*let worldBottomLeft = referencePlaneNode.convertPosition(bottomLeft, to: referencePlaneNode.parent)
        
        let worldTopRight = referencePlaneNode.convertPosition(topRight, to: referencePlaneNode.parent)
        
        let worldBottomRight = referencePlaneNode.convertPosition(bottomRight, to: referencePlaneNode.parent)*/
        
        return movementVector
    }*/
    
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
            graph?.runAction(animation, forKey: "shake")
        }
    }
    
    func stopAllShakingObjects()
    {
        for graph in graphs
        {
            graph?.removeAction(forKey: "shake")
            graph?.rotation = SCNVector4(x:0, y:0, z:0, w:1)
        }
    }
    
    func highlightSelectedObject()
    {
        guard selectedObject != nil else { return }
        
        let currentColor = selectedObject?.geometry?.materials.first?.diffuse.contents as! UIColor
        
        originalColor = currentColor
        
        let selectedColor = UIColor(red: 255/255, green: 0/255, blue: 0/255, alpha: 255/255)
        
        let duration: TimeInterval = 0.2
        
        let colorAnimation = SCNAction.customAction(duration: duration, action: { (node, elapsedTime) in
            let percentage = elapsedTime / CGFloat(duration)
            node.geometry?.firstMaterial?.diffuse.contents = self.changeColor(from: currentColor, to: selectedColor, percentage: percentage)
        })
        
        
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
        
        let currentColor =  selectedObject?.geometry?.materials.first?.diffuse.contents as! UIColor
        
        let duration: TimeInterval = 0.1
        
        let colorAnimation = SCNAction.customAction(duration: 0.2, action: { (node, elapsedTime) in
            let percentage = elapsedTime / CGFloat(duration)
            node.geometry?.firstMaterial?.diffuse.contents = self.changeColor(from: currentColor, to: self.originalColor, percentage: percentage)
        })
        
        let scaleAnimation : SCNAction
        
        let finalScale = originalScale
        
        scaleAnimation = SCNAction.scale(to: CGFloat(finalScale) , duration: 0.1)
        
        selectedObject?.runAction(colorAnimation)
        selectedObject?.runAction(scaleAnimation)
    }
    
    func changeColor(from: UIColor, to: UIColor, percentage: CGFloat) -> UIColor {
        let fromComponents = from.cgColor.components!
        let toComponents = to.cgColor.components!
        let color = UIColor(red: fromComponents[0] + (toComponents[0] - fromComponents[0]) * percentage,
                            green: fromComponents[1] + (toComponents[1] - fromComponents[1]) * percentage,
                            blue: fromComponents[2] + (toComponents[2] - fromComponents[2]) * percentage,
                            alpha: toComponents[3])
        return color
    }
    
    func displayWhitePlane(imageAnchor: ARImageAnchor, node: SCNNode)
    {
        DispatchQueue.main.async
            { [weak self] in
                let plane = SCNPlane(width: imageAnchor.referenceImage.physicalSize.width, height: imageAnchor.referenceImage.physicalSize.height)
                
                plane.firstMaterial?.diffuse.contents = UIColor(red: 255/255, green: 255/255, blue: 255/255, alpha: 0.8)
                
                let planeNode = SCNNode(geometry: plane)
                
                planeNode.eulerAngles.x = -.pi/2
                
                node.addChildNode(planeNode)
                
                var (min, max) = planeNode.boundingBox
                
                let size = SCNVector3Make(max.x - min.x, max.y - min.y, max.z - min.z)
                
                let widthRatio = Float(imageAnchor.referenceImage.physicalSize.width)/size.x
                let heightRatio = Float(imageAnchor.referenceImage.physicalSize.height)/size.z
                // Pick smallest value to be sure that object fits into the image.
                let finalRatio = [widthRatio, heightRatio].min()!
                
                let appearAnimation = SCNAction.scale(to: CGFloat(finalRatio), duration: 0.4)
                
                appearAnimation.timingMode = .easeOut
                
                planeNode.scale = SCNVector3(0.001, 0.001, 0.001)
                
                planeNode.runAction(appearAnimation)
                
                self?.minBound = min
                
                self?.maxBound = max
                
                if let shipScene = SCNScene(named: "art.scnassets/ship.scn")
                {
                    let shipNode = shipScene.rootNode.childNodes.first
                    shipNode?.position = SCNVector3(x: 0, y: 0, z: self!.distanceFromPlane)
                    self?.graphs.append(shipNode)
                    planeNode.addChildNode(shipNode!)
                }
                
                self?.referencePlaneNode = node
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
