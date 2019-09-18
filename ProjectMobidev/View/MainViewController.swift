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

//TODO Riscrivere meglio la fase di placing degli oggetti

class MainViewController: UIViewController, ARSCNViewDelegate, UIGestureRecognizerDelegate, DisplayFileList {
    
    @IBOutlet var sceneView: ARSCNView!
    
    @IBOutlet var infoLabel: UILabel!
    
    var currentMode : WorkingMode = .watchingMode
    
    var lastAdjustment = Double(0.0)
    
    var updateFrequency = Double(0.1)
    
    var lastPanLocation = SCNVector3(x: 0, y:0, z:0)
    
    var selectedObject : Graph!
    
    var graphToBePlaced : Graph!
    
    var originalScale = Float(0)
    
    var aimOnThePlane = false
    
    var placeTheGraph = false
    
    var labelModifyCount : Int = 0
    
    var graphs : [Graph] = []

    var graphToCreate : [Graph] = []
    
    var planeRoot : SCNNode!
    
    var planeNode : SCNNode!
    
    let distanceFromPlane : Float = 0.3
    
    var middleScreen : CGPoint?
    
    override var prefersStatusBarHidden: Bool
    {
        return true
    }
    
    @IBAction func prepareForUnwind(segue: UIStoryboardSegue) {
        if graphToCreate.count > 0
        {
            graphs.append(contentsOf: graphToCreate)
            currentMode = .placingMode
            updateInfoLabel(infoType: .AimToThePlane)
        }
        else
        {
            currentMode = .watchingMode
            updateInfoLabel(infoType: .NothingToDo)
            labelModifyCount += 1
            let copy = labelModifyCount
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                [weak self] in
                if copy == self?.labelModifyCount
                {
                    self?.updateInfoLabel(infoType: .TapOnAddAdvice)
                    self?.labelModifyCount = 0
                }
            }
        }
    }

    //View Controller Events
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Set the view's delegate
        sceneView.delegate = self
        
        // Show statistics such as fps and timing information
        sceneView.showsStatistics = true
        
        sceneView.debugOptions = [SCNDebugOptions.showCreases, SCNDebugOptions.showBoundingBoxes]

        // Create a new scene
        let scene = SCNScene(named: "art.scnassets/GraphScene.scn")!

        // Set the scene to the view
        sceneView.scene = scene
        
        middleScreen = self.view.center
    }
    
    override func viewWillAppear(_ animated: Bool) {
        
        super.viewWillAppear(animated)
        
        navigationController?.setNavigationBarHidden(true, animated: true)
        
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
        
        navigationController?.setNavigationBarHidden(false, animated: animated)
        
        // Pause the view's session
        sceneView.session.pause()
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        if segue.identifier == "toDownloadFileListViewController"
        {
            let destination = segue.destination as! DownloadFileListViewController
            destination.implementer = self
        }
        else if segue.identifier == "toFilesTableViewController"
        {
            let destination = segue.destination as! FilesViewController
            destination.files = sender as! [Files.Metadata]
        }
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
        guard planeRoot != nil, planeNode != nil else { return }
        
        if time - lastAdjustment > updateFrequency
        {
            adjustCoordinateSystem()
            lastAdjustment = time
        }
        
        if currentMode == .placingMode
        {
            // guarda dove mira e aggiorna il label
            let projectedPoint = getProjectedPoint(location: middleScreen!)
            
            if placeTheGraph
            {
                guard graphToBePlaced != nil else { return }
                graphToBePlaced.setGraphColor(color: UIColor.white)
                graphToBePlaced = nil
                
                DispatchQueue.main.async
                    { [weak self] in
                        self?.placeTheGraph = false
                        
                        if self?.graphToCreate.count == 0
                        {
                            self?.currentMode = .watchingMode
                            
                            self?.labelModifyCount += 1
                            let copy = self?.labelModifyCount
                            
                            self?.updateInfoLabel(infoType: .AllGraphPlaced)
                            
                            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                                [weak self] in
                                if copy == self?.labelModifyCount
                                {
                                    self?.updateInfoLabel(infoType: .NothingToDo)
                                    self?.labelModifyCount = 0
                                }
                            }
                        }
                }
                return
            }
            
            if CheckIfPointOverReferencePlane(projectedPoint: projectedPoint)
            {
                DispatchQueue.main.async
                { [weak self] in
                    self?.updateInfoLabel(infoType: .TapToPlace)
                }
                displayGraphPreview(worldPosition: projectedPoint)
                aimOnThePlane = true
            }
            else
            {
                DispatchQueue.main.async
                { [weak self] in
                    self?.updateInfoLabel(infoType: .AimToThePlane)
                    self?.aimOnThePlane = false
                }
            }
        }
    }
    
    //Input buttons
    
    @IBAction func btnAddTouchDown(_ sender: Any) {
        guard currentMode != .placingMode else {
            Alert.DisplayPopUpAndDismiss(viewController: self, title: "Reminder", message: "Place all selected graphs before.", style: .default)
            return
        }
        
        if Dropbox.getDropboxClient() == nil
        {
            authorizeApp()
        }
        else
        {
            self.performSegue(withIdentifier: "toDownloadFileListViewController", sender: nil)

            if currentMode == .editMode
            {
                disableEditMode()
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
    
    //Gesture recognizer actions
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        
        if currentMode == .editMode, let location = touches.first?.location(in: sceneView)
        {
            let result = sceneView.hitTest(location, options: nil).first
            
            guard let node = result?.node
            else
            {
                if currentMode == .editMode
                {
                    disableEditMode()
                }
                return
            }
            
            if node.categoryBitMask == 5
            {
                let i = getRemoveButtonIndex(removeButton: node)
                
                guard i != -1 else { return }
                
                let graphToRemove = graphs[i]
                
                graphs.remove(at: i)
                
                graphToRemove.removeGraphFromScene()
                
                updateInfoLabel(infoType: .GraphRemoved)
                labelModifyCount += 1
                let copy = labelModifyCount
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                    [weak self] in
                    if copy == self?.labelModifyCount
                    {
                        self?.updateInfoLabel(infoType: .NothingToDo)
                        self?.labelModifyCount = 0
                    }
                }
            }
            else if node.categoryBitMask != 4
            {
                disableEditMode()
            }
        }
        else if currentMode == .placingMode && aimOnThePlane
        {
            placeTheGraph = true
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
        guard gestureRecognizer.view != nil, planeRoot != nil, currentMode == .editMode, selectedObject != nil else { return }
        
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
            
            var finalPosition = selectedObject.getGraphWorldPosition()
            
            finalPosition.x += movementVector.x
            
            finalPosition.z += movementVector.z
            
            selectedObject.setGraphWorldPosition(worldPosition: finalPosition, distanceFromPlane: distanceFromPlane, scene: sceneView)
            
            lastPanLocation = currentPanLocation

            break
        default:
            print("stop pan")
            break
        }
    }
    
    @IBAction func longPressEvent(_ gestureRecognizer: UILongPressGestureRecognizer)
    {
        guard currentMode != .placingMode else { return }
        
        switch gestureRecognizer.state {
        case .began:
            let location = gestureRecognizer.location(in: sceneView)
            let result = sceneView.hitTest(location, options: [SCNHitTestOption.firstFoundOnly:true,SCNHitTestOption.categoryBitMask:4]).first
            
            guard result != nil else { return }
            
            selectedObject = getGraphObject(node: result?.node)
            selectedObject.highlightGraphNode()
                
            if currentMode == .watchingMode
            {
                currentMode = .editMode
                
                updateInfoLabel(infoType: .EditModeOn)
                
                labelModifyCount += 1
                let copy = labelModifyCount
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                    [weak self] in
                    
                    if copy == self?.labelModifyCount
                    {
                        self?.updateInfoLabel(infoType: .NothingToDo)
                        self?.labelModifyCount = 0
                    }
                }
                
                shakeAllObjects()
            }
            
            break
        case .changed:
            break
        case .ended:
            if selectedObject != nil
            {
                selectedObject.deselectGraphNode()
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
    
    func displayNewGraph(worldPosition: SCNVector3) -> Graph?
    {
        let newGraph = graphToCreate.first
            
        graphToCreate.removeFirst()
        
        newGraph?.setParentNode(parent: planeNode)
        
        newGraph?.runAppearAnimation()
        
        newGraph?.setGraphWorldPosition(worldPosition: worldPosition, distanceFromPlane: distanceFromPlane, scene: sceneView)
        
        return newGraph
    }
    
    func disableEditMode()
    {
        updateInfoLabel(infoType: .EditModeOff)
        
        labelModifyCount += 1
        
        let copy = labelModifyCount
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            [weak self] in
            
            if copy == self?.labelModifyCount
            {
                self?.updateInfoLabel(infoType: .NothingToDo)
                self?.labelModifyCount = 0
            }
        }
        
        print("edit mode off")
        stopAllShakingObjects()
        currentMode = .watchingMode
        selectedObject = nil
        originalScale = 0
        return
    }
    
    func getProjectedPoint(location: CGPoint) -> SCNVector3
    {
        var projectedPoint = sceneView.unprojectPoint(location, ontoPlane: simd_float4x4(sceneView.scene.rootNode.transform))
        
        if projectedPoint == nil
        {
            projectedPoint = simd_float3(planeNode.worldPosition)
        }
        
        let normal = getReferencePlaneNormal()
        
        //proietto il punto sul piano movimento
        projectedPoint!.x += normal.x * distanceFromPlane
        projectedPoint!.y += normal.y * distanceFromPlane
        projectedPoint!.z += normal.z * distanceFromPlane
        
        //calcolo min max tramite vettori del piano
        var (worldMin, worldMax) = getMinMaxWorldCoordinates()
        
        worldMax.x += normal.x * distanceFromPlane
        worldMax.y += normal.y * distanceFromPlane
        worldMax.z += normal.z * distanceFromPlane
        
        worldMin.x += normal.x * distanceFromPlane
        worldMin.y += normal.y * distanceFromPlane
        worldMin.z += normal.z * distanceFromPlane
        
        //clamp
        projectedPoint!.x = simd_clamp(projectedPoint!.x, worldMin.x, worldMax.x)
        projectedPoint!.z = simd_clamp(projectedPoint!.z, -worldMin.z, -worldMax.z)
    
        return SCNVector3(projectedPoint!)
    }
    
    func CheckIfPointOverReferencePlane(projectedPoint: SCNVector3) -> Bool
    {
        var (worldMin,worldMax) = getMinMaxWorldCoordinates()
        
        let normal = getReferencePlaneNormal()
        
        worldMax.x += normal.x * distanceFromPlane
        worldMax.y += normal.y * distanceFromPlane
        worldMax.z += normal.z * distanceFromPlane
        
        worldMin.x += normal.x * distanceFromPlane
        worldMin.y += normal.y * distanceFromPlane
        worldMin.z += normal.z * distanceFromPlane
        
        if projectedPoint.x.distance(to: worldMin.x).isZero || projectedPoint.x.distance(to: worldMax.x).isZero ||
            projectedPoint.z.distance(to: -worldMin.z).isZero ||
            projectedPoint.z.distance(to: -worldMax.z).isZero
        {
            return false
        }
        
        return true
    }
    
    func shakeAllObjects()
    {
        for graph in graphs
        {
            graph.shakeGraph()
        }
    }
    
    func stopAllShakingObjects()
    {
        for graph in graphs
        {
            graph.stopShake()
        }
    }
    
    func adjustCoordinateSystem()
    {
        let transform = simd_float4x4(planeRoot.transform)
        self.sceneView.session.setWorldOrigin(relativeTransform: transform)
    }
    
    func displayReferencePlane(imageAnchor: ARImageAnchor, node: SCNNode)
    {
                let plane = SCNPlane(width: imageAnchor.referenceImage.physicalSize.width, height: imageAnchor.referenceImage.physicalSize.height)
                
                plane.firstMaterial?.diffuse.contents = UIColor(red: 0/255, green: 0/255, blue: 0/255, alpha: 0.5)
                
                planeNode = SCNNode(geometry: plane)
                
                planeNode.eulerAngles.x = -.pi/2
                
                node.addChildNode(planeNode)
                
                node.categoryBitMask = 0
                
                planeRoot = node
            
                for graph in graphs
                {
                    planeNode.addChildNode(graph.getGraphNode())
                    planeNode.addChildNode(graph.getTitleNode())
                    planeNode.addChildNode(graph.getRemoveButtonNode())
                }
    }
    
    func getGraphIndex(graph: SCNNode) -> Int
    {
        var i = 0
        for g in graphs
        {
            if graph == g.getGraphNode()
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
    
    func getReferencePlaneNormal() -> SCNVector3
    {
        let referencePlaneTransform = simd_float4x4(planeRoot.worldTransform)
        
        let (_,normal,_,_) = referencePlaneTransform.columns
        
        return SCNVector3(x: normal.x, y: normal.y, z: normal.z)
    }
    
    func getMinMaxWorldCoordinates() -> (worldMin: SCNVector3,worldMax: SCNVector3)
    {
        let plane = planeRoot.childNodes.first!.geometry as! SCNPlane
        
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
        
        return (worldMin, worldMax)
    }
    
    func displayGraphPreview(worldPosition: SCNVector3)
    {
        if graphToBePlaced == nil
        {
            graphToBePlaced = displayNewGraph(worldPosition: worldPosition)
        }
        else
        {
            graphToBePlaced.setGraphWorldPosition(worldPosition: worldPosition, distanceFromPlane: distanceFromPlane, scene: sceneView)
        }
    }
    
    func getGraphObject(node: SCNNode?) -> Graph?
    {
        guard node != nil else { return nil }
        for g in graphs
        {
            if g.getGraphNode() == node
            {
                return g
            }
        }
        
        return nil
    }
    
    func updateInfoLabel(infoType : InfoUpdate)
    {
        switch infoType {
        case .EditModeOn:
            infoLabel.text = "Edit mode activated"
            break
        case .EditModeOff:
            infoLabel.text = "Edit mode disabled"
            break
        case .TapOnAddAdvice:
            infoLabel.text = "Add some graphs first"
            break
        case .NothingToDo:
            infoLabel.text = ""
            break
        case .AimToThePlane:
            infoLabel.text = "Aim to the marker"
            break
        case .TapToPlace:
            infoLabel.text = "Tap to place a graph"
            break
        case .AllGraphPlaced:
            infoLabel.text = "All graph have been placed"
            break
        case .GraphRemoved:
            infoLabel.text = "Graph removed"
            break
        default:
            break
        }
        
    }
    
    func clearSceneGraph()
    {
        if planeRoot != nil
        {
            planeRoot.removeFromParentNode()
            planeNode.removeFromParentNode()
            planeRoot = nil
            planeNode = nil
        }
    }
    
    // Protocols stubs
    
    func displayDownloadedFileList(files: [Files.Metadata]) {
        // qui performare il segue dopo il dismiss
        if files.count > 0
        {
            performSegue(withIdentifier: "toFilesTableViewController", sender: files)
            
            clearSceneGraph()
        }
    }
}
