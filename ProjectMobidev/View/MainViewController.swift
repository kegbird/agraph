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

/*
 This viewcontroller manages all the AR features of this app.
 The app behaviour depends by the working mode; there are
 3 different working modes:
 
 - watchingMode: whenever you aim towards a 3d point of a graph, the app
 updates infolabel, in order to communicate the point value to the user.
 - placingMode: after had chosen, which graph to plot, this mode allows the
 user to place ar graphs into the scene, whenever the user aim towards the
 marker.
 - editMode: this mode allows to move (by panning) graphs and eventually
 remove them.
*/

class MainViewController: UIViewController, ARSCNViewDelegate, UIGestureRecognizerDelegate, DisplayFileList {
    
    @IBOutlet var sceneView: ARSCNView!
    
    //This is the label used to print messages for the user
    @IBOutlet var infoLabel: UILabel!
    
    //It's a enum that states the working mode of the application
    var currentMode : WorkingMode = .watchingMode
    
    //It stores the last adjustment of the world coordinate system
    var lastAdjustment = Double(0.0)
    
    //This states the frequency with which the world coordinate system is updated
    var updateFrequency = Double(0.25)
    
    //This is the last pan location (in world coordinates)
    var lastPanLocation = SCNVector3(x: 0, y:0, z:0)
    
    //This is the reference of the graph moved in edit mode
    var selectedGraph : Graph!
    
    //This is the reference of the graph to be placed in placing mode
    var graphToBePlaced : Graph!
    
    //Is the user aiming at the marker or not?
    var aimOnThePlane = false
    
    //This variable indicates that the user has confirmed the position of the graph
    //in placing mode
    var placeTheGraph = false
    
    //A support variable needed to update correctly infoLabel
    var labelModifyCount : Int = 0
    
    //This array contains all graph displayed in the scene
    //and those that are to be placed in placing mode.
    var graphs : [Graph] = []

    //This variable indicates how many graph needs to be placed in placing mode
    var graphToCreate : Int = 0
    
    var planeRoot : SCNNode!
    
    var planeNode : SCNNode!
    
    //It's the distance of graphs from the reference plane; the reference plane is the black plane displayed over the marker.
    let distanceFromPlane : Float = 0.3
    
    var middleScreen : CGPoint!
    
    //Used to clear the infoLabel
    var valuePrinted = false
    
    override var prefersStatusBarHidden: Bool
    {
        return true
    }
    
    override var shouldAutorotate: Bool
    {
        return false
    }

    @IBAction func prepareForUnwind(segue: UIStoryboardSegue) {
        
        /*
         Each time an unwind segue occurs, the application checks if there are
         new graphs to display.
         If graphToCreate > 0, then the app must run in placing mode, otherwise the app is in watching mode.
         */
        
        if graphToCreate > 0
        {
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
                
                guard self != nil else { return }
                
                if copy == self?.labelModifyCount
                {
                    self?.updateInfoLabel(infoType: .NoGraphAdded)
                    self?.labelModifyCount = 0
                }
            }
        }
    }

    //View Controller Events
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        sceneView.delegate = self

        let scene = SCNScene(named: "art.scnassets/GraphScene.scn")!

        sceneView.scene = scene
        
        middleScreen = self.view.center
        
        /*
         The notification center is used to perform the segue to the FilesViewController, when the user authorize the application
         to write, read, modify files from the user's dropbox.
         */
        
        if Dropbox.getDropboxClient() == nil
            {
            NotificationCenter.default.addObserver(
                self,
                selector: #selector(self.btnAddTouchDown),
                name: NSNotification.Name("performSegueToFilesViewController"),
                object: nil)
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        
        super.viewWillAppear(animated)
        
        navigationController?.setNavigationBarHidden(true, animated: true)
        
         //Everytime the view appears, a new session is launched.
        
        let configuration = ARWorldTrackingConfiguration()
        
        guard let trackedImages = ARReferenceImage.referenceImages(inGroupNamed: "Scheme", bundle: nil)
            else
        {
            print("No images available")
            return
        }
        
        configuration.detectionImages = trackedImages
        configuration.maximumNumberOfTrackedImages = 1
        
        sceneView.session.run(configuration)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        navigationController?.setNavigationBarHidden(false, animated: animated)
        
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
            /*
             If the download of the csv list from the user dropbox succeeds,
             the application loads the table view of the FilesViewController
             this list.
            */
            let destination = segue.destination as! FilesViewController
            
            var currentNumberOfPoints = 0
            
            for graph in graphs
            {
                currentNumberOfPoints = currentNumberOfPoints + graph.getPointsCount()
            }
            
            destination.files = sender as! [Files.Metadata]
            destination.currentNumberOfPoints = currentNumberOfPoints
        }
    }
    
    //AR Events
    
    func renderer(_ renderer: SCNSceneRenderer, nodeFor anchor: ARAnchor) -> SCNNode? {
        
        /*
         This method makes appear the reference plane in each ar session.
         It's called only the first time, the marker is viewed by the camera.
         */
        
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
            
            /*
             4 times in a second, this method adjust the world reference
             system with root node transform.
             By doing this, we avoid wrong movement vectors, when the user
             moves ar objects.
            */
            
            adjustCoordinateSystem()
            lastAdjustment = time
        }
        
        if currentMode == .placingMode
        {
            /*
             In placing mode, the app gets the projected point of the middle screen;
             with that point, the graph preview can be placed and moved.
             */
            
            let projectedPoint = getProjectedPoint(location: middleScreen!)

            if placeTheGraph
            {
                guard graphToBePlaced != nil else { return }
                graphToBePlaced.setGraphColor(color: UIColor.white)
                graphToBePlaced = nil
                
                DispatchQueue.main.async
                    { [weak self] in
                        
                        guard self != nil else { return }
                        
                        self?.placeTheGraph = false
                        
                        if self?.graphToCreate == 0
                        {
                            self?.currentMode = .watchingMode
                            
                            self?.labelModifyCount += 1
                            let copy = self?.labelModifyCount
                            
                            self?.updateInfoLabel(infoType: .AllGraphPlaced)
                            
                            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                                [weak self] in
                                
                                guard self != nil else { return }
                                
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
                    
                    guard self != nil else { return }
                    
                    self?.updateInfoLabel(infoType: .TapToPlace)
                }
                displayGraphPreview(worldPosition: projectedPoint)
                aimOnThePlane = true
            }
            else
            {
                DispatchQueue.main.async
                { [weak self] in
                    
                    guard self != nil else { return }
                    
                    self?.updateInfoLabel(infoType: .AimToThePlane)
                    self?.aimOnThePlane = false
                }
            }
        }
        else if currentMode == .watchingMode
        {
            /*
             In watching mode, for every frame, the application performs an hit test from the middle
             screen towards the ar scene.
             If the hit test returns an scnnode, then it checks if this node is a point of a graph,
             by comparing its bitmask with a specific value (Graph.pointBitMask).
             With the point, the application can get his 3d coordinates.
            */
            
            let result = sceneView.hitTest(middleScreen!, options: [SCNHitTestOption.categoryBitMask : Graph.pointBitMask]).first
            
            guard let node = result?.node
                else
            {
                return
            }
            
            if node.categoryBitMask == Graph.pointBitMask
            {
                let relativeGraph = getGraphObject(node: node.parent)
                
                if let point = relativeGraph?.getPointsCoordinateForNode(pointNode: node)
                {
                    let pointToPrint = String(format: "%.2f, %.2f, %.2f", point.position.x, point.position.y, point.position.z)
                    
                    labelModifyCount += 1
                    DispatchQueue.main.async
                    { [weak self] in
                        
                        guard self != nil else { return }
                        
                        self?.infoLabel.text = pointToPrint
                    }
                    
                    valuePrinted = true
                }
            }
        }
    }
    
    //Input buttons
    
    @IBAction func btnAddTouchDown(_ sender: Any) {
        AudioServicesPlaySystemSound(1103)
        
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
        
        let bounds = sceneView.bounds
        UIGraphicsBeginImageContextWithOptions(bounds.size, true, UIScreen.main.scale)
        sceneView.drawHierarchy(in: bounds, afterScreenUpdates: true)
        let screenShot = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        UIImageWriteToSavedPhotosAlbum(screenShot!, nil, nil, nil)
        
        updateInfoLabel(infoType: .PhotoTaken)
        labelModifyCount += 1
        let copy = labelModifyCount
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            [weak self] in
            
            guard self != nil else { return }
            
            if copy == self?.labelModifyCount
            {
                self?.updateInfoLabel(infoType: .NothingToDo)
                self?.labelModifyCount = 0
            }
        }
        
        AudioServicesPlaySystemSound(1108);
    }
    
    //Gesture recognizer actions
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {

        if currentMode == .editMode
        {
            let location = touches.first?.location(in: sceneView)
            
            guard location != nil else { return }
            
            let result = sceneView.hitTest(location!, options: nil).first
            
            guard let node = result?.node
            else
            {
                if currentMode == .editMode
                {
                    disableEditMode()
                }
                return
            }
            
            if node.categoryBitMask == Graph.removeButtonBitMask
            {
                let i = getRemoveButtonIndex(removeButton: node)
                
                guard i != -1 else { return }
                
                let graphToRemove = graphs[i]
                
                graphs.remove(at: i)
                
                graphToRemove.removeGraphFromScene()
                
                if graphs.count == 0
                {
                    updateInfoLabel(infoType: .GraphRemoved)
                    labelModifyCount += 1
                    let copy = labelModifyCount
                    
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                        [weak self] in
                        
                        guard self != nil else { return }
                        
                        if copy == self?.labelModifyCount
                        {
                            self?.updateInfoLabel(infoType: .AllGraphRemoved)
                            self?.labelModifyCount = 0
                        }
                    }
                    
                    currentMode = .watchingMode
                }
                else
                {
                    updateInfoLabel(infoType: .GraphRemoved)
                    labelModifyCount += 1
                    let copy = labelModifyCount
                    
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                        [weak self] in
                        
                        guard self != nil else { return }
                        
                        if copy == self?.labelModifyCount
                        {
                            self?.updateInfoLabel(infoType: .NothingToDo)
                            self?.labelModifyCount = 0
                        }
                    }
                }
            }
            else if node.categoryBitMask != Graph.graphBitMask && node.categoryBitMask != Graph.pointBitMask
            {
                disableEditMode()
            }
        }
        else if currentMode == .placingMode && aimOnThePlane
        {
            guard graphToBePlaced != nil else { return }
            placeTheGraph = true
        }
        else if currentMode == .watchingMode && valuePrinted
        {
            infoLabel.text = ""
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
        guard gestureRecognizer.view != nil, planeRoot != nil, currentMode == .editMode, selectedGraph != nil else { return }
        
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
            
            var finalPosition = selectedGraph.getGraphWorldPosition()
            
            finalPosition.x += movementVector.x
            
            finalPosition.z += movementVector.z
            
            selectedGraph.setGraphWorldPosition(worldPosition: finalPosition, distanceFromPlane: distanceFromPlane, scene: sceneView)
            
            lastPanLocation = currentPanLocation

            break
        default:
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
            
            selectedGraph = getGraphObject(node: result?.node)
            
            guard selectedGraph != nil else { return }
            
            selectedGraph.highlightGraphNode()
                
            if currentMode == .watchingMode
            {
                currentMode = .editMode
                
                updateInfoLabel(infoType: .EditModeOn)
                
                labelModifyCount += 1
                let copy = labelModifyCount
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                    [weak self] in
                    
                    guard self != nil else { return }
                    
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
            guard selectedGraph != nil else { return }
            selectedGraph.deselectGraphNode()
            selectedGraph = nil
            break
        default:
            break
        }
    }
    
    //Utility functions
    
    func displayNewGraph(worldPosition: SCNVector3) -> Graph?
    {
        let newGraph = graphs[graphs.count-graphToCreate]
        
        graphToCreate = graphToCreate - 1
        
        newGraph.runAppearAnimation()
        
        newGraph.setGraphWorldPosition(worldPosition: worldPosition, distanceFromPlane: distanceFromPlane, scene: sceneView)
        
        return newGraph
    }
    
    func disableEditMode()
    {
        updateInfoLabel(infoType: .EditModeOff)
        
        labelModifyCount += 1
        
        let copy = labelModifyCount
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            [weak self] in
            
            guard self != nil else { return }
            
            if copy == self?.labelModifyCount
            {
                self?.updateInfoLabel(infoType: .NothingToDo)
                self?.labelModifyCount = 0
            }
        }
        
        stopAllShakingObjects()
        currentMode = .watchingMode
        selectedGraph = nil
        return
    }
    
    func getProjectedPoint(location: CGPoint) -> SCNVector3
    {
        /*
         All ar object displayed are placed on a plane that is parallel
         to the marker; translation made are costraned on this plane.
         This method firstly calculate the world posion of a screen point,
         then it projects that point over the plane that is parallel to the marker.
         Finally the obtained point is clamped, according to the marker size.
         */
        
        var projectedPoint = sceneView.unprojectPoint(location, ontoPlane: simd_float4x4(sceneView.scene.rootNode.transform))
        
        if projectedPoint == nil
        {
            projectedPoint = simd_float3(planeNode.worldPosition)
        }
        
        let normal = getReferencePlaneNormal()
        
        projectedPoint!.x += normal.x * distanceFromPlane
        projectedPoint!.y += normal.y * distanceFromPlane
        projectedPoint!.z += normal.z * distanceFromPlane
        
        var (worldMin, worldMax) = getMinMaxWorldCoordinates()
        
        worldMax.x += normal.x * distanceFromPlane
        worldMax.y += normal.y * distanceFromPlane
        worldMax.z += normal.z * distanceFromPlane
        
        worldMin.x += normal.x * distanceFromPlane
        worldMin.y += normal.y * distanceFromPlane
        worldMin.z += normal.z * distanceFromPlane
        
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
                
                plane.firstMaterial?.diffuse.contents = UIColor(red: 0/255, green: 0/255, blue: 0/255, alpha: 0.8)
                
                planeNode = SCNNode(geometry: plane)
                
                planeNode.eulerAngles.x = -.pi/2
                
                node.addChildNode(planeNode)
                
                node.categoryBitMask = 0
                
                planeRoot = node
        
                /*
                Since everytime the app changes view, the session ends, it
                has to restore all graphs object, whenever the user aim towards
                the marker.
                */
        
                for graph in graphs
                {
                    planeNode.addChildNode(graph.getGraphNode())
                    planeNode.addChildNode(graph.getTitleNode())
                    planeNode.addChildNode(graph.getRemoveButtonNode())
                }
    }
    
    func getRemoveButtonIndex(removeButton: SCNNode) -> Int
    {
        var i = 0
        for g in graphs
        {
            if removeButton === g.getRemoveButtonNode()
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
                                                        UIApplication.shared.open(url, options: [:], completionHandler: {
                                                            status in
                                                            
                                                            Alert.DisplayPopUpAndDismiss(viewController: self, title: "Error", message: "Authentication canceled by the user.", style: .destructive)
                                                            return
                                                        })
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
        /*
         In placing mode, this method picks the first graph downloaded from
         dropbox and place it into the arscene, where the user is aiming.
         */
        
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
        valuePrinted = false
        
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
        case .AllGraphRemoved:
            infoLabel.text = "All graph have been removed"
            break
        case .PhotoTaken:
            infoLabel.text = "Photo taken!"
            break
        default:
            infoLabel.text = "No graph added"
            break
        }
        
    }
    
    func clearSceneGraph()
    {
        if planeRoot != nil
        {
            planeRoot.geometry?.firstMaterial!.normal.contents = nil
            planeNode.geometry?.firstMaterial!.normal.contents = nil
            planeNode.geometry!.firstMaterial!.diffuse.contents = nil
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
    
    deinit {
        NotificationCenter.default.removeObserver(self, forKeyPath: "performSegueToFilesViewController")
    }
}
