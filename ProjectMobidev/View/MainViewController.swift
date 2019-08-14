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
    
    var initialPanLocation : SCNVector3?
    
    var lastPanLocation : SCNVector3?
    
    var draggingNode : SCNNode?
    
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
            let plane = SCNPlane(width: imageAnchor.referenceImage.physicalSize.width, height: imageAnchor.referenceImage.physicalSize.height)
            
            plane.firstMaterial?.diffuse.contents = UIColor(white: 1, alpha: 0.8)
            
            let planeNode = SCNNode(geometry: plane)
            
            planeNode.eulerAngles.x = -.pi/2
            
            node.addChildNode(planeNode)
            
            if let shipScene = SCNScene(named: "art.scnassets/ship.scn")
            {
                let shipNode = shipScene.rootNode.childNodes.first
                shipNode?.position = SCNVector3Zero
                shipNode?.position.z = 0.15
                planeNode.addChildNode(shipNode!)
            }
            
        }
        
        return node
    }
    
    //Input Events
    
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
    
    @IBAction func tapEvent(_ gestureRecognizer: UITapGestureRecognizer)
    {
        guard gestureRecognizer.view != nil else { return }
        print("Edit mode off")
        editMode = false
    }
    
    @IBAction func panEvent(_ gestureRecognizer: UIPanGestureRecognizer)
    {
        guard gestureRecognizer.view != nil && editMode else { return }
        let location = gestureRecognizer.location(in: sceneView)
        
        switch gestureRecognizer.state {
        case .began:
            print("pan begin")
            guard let hitNodeResult = sceneView.hitTest(location, options: nil).first else { return }
            initialPanLocation = sceneView.projectPoint(lastPanLocation!)
            lastPanLocation = hitNodeResult.worldCoordinates
            draggingNode = hitNodeResult.node
            
        case .changed:
            let z = CGFloat(initialPanLocation!.z)
            
            let deltaVector = SCNVector3(x: Float(location.x), y: Float(location.y), z: Float(z))
            
            let worldTouchPosition = sceneView.unprojectPoint(deltaVector)
            
            let movementVector = SCNVector3(
                worldTouchPosition.x - lastPanLocation!.x,
                worldTouchPosition.y - lastPanLocation!.y,
                worldTouchPosition.z - lastPanLocation!.z)
            draggingNode?.localTranslate(by: movementVector)
            self.lastPanLocation = worldTouchPosition
        default:
            print("pan end")
        }
    }
    
    @IBAction func longPressEvent(_ gestureRecognizer: UILongPressGestureRecognizer)
    {
        if gestureRecognizer.state == .began
        {
            let touchLocation = gestureRecognizer.location(in: sceneView)
            let hitTest = sceneView?.hitTest(touchLocation, options: nil)
            
            if !hitTest!.isEmpty
            {
                print("Edit mode on")
                editMode = true
            }
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
    
    //Utility functions
    
    func authorizeApp(){
        DropboxClientsManager.authorizeFromController(UIApplication.shared,
                                                      controller: self,
                                                      openURL: { (url: URL) -> Void in
                                                        UIApplication.shared.open(url, options: [:], completionHandler: nil)
        })
    }
}
