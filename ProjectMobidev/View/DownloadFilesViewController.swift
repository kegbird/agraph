//
//  DownloadFileViewController.swift
//  ProjectMobidev
//
//  Created by Pietro Prebianca on 30/07/2019.
//  Copyright © 2019 Pietro Prebianca. All rights reserved.
//

import UIKit
import SceneKit

protocol ReturnToRoot
{
    var maxNumberOfPoints : Int { get set }
    
    var currentNumberOfPoints : Int! { get set }
    
    func ReturnToRootViewController(graphs : [Graph])
}

/*
 This view controller downloads all .csv file selected by the user
 and checks, if their content is valid.
 Valid files have this structure:
 
 Title of the graph
 X Value;Y Value;Z Value;Red Value;Green Value;Blue Value
 X Value;Y Value;Z Value;Red Value;Green Value;Blue Value
 X Value;Y Value;Z Value;Red Value;Green Value;Blue Value
 ...
 
 Where X,Y,Z are a point coordinates and RGB is a color.
 
 Valid graphs are loaded in the mainviewcontroller, where they are rendered.
 
 Furthermore, this viewcontroller checks if the number of points that the user
 wants to add to the scene is under the imposed limit of 1000.
 This limit avoid the application to run of out memory.
 If the limit is respected, then it creates all new graph objects, and returns them
 to the FileViewController.
*/

class DownloadFilesViewController: UIViewController {

    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    
    var filesToDownload : [String]=[]
    
    var filesContents : [String]=[]
    
    var implementer : ReturnToRoot!
    
    var fail = false

    override var prefersStatusBarHidden: Bool
    {
        return true
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        downloadFiles()
    }
    
    func downloadFiles()
    {
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            
            guard self != nil else { return }
            
            let dispatchGroup = DispatchGroup()
            
            for path in self!.filesToDownload
            {
                dispatchGroup.enter()
                self?.downloadFile(path: path, group: dispatchGroup)
                dispatchGroup.wait()
                
                if self!.fail
                {
                    break
                }
            }
        }
    }
    
    func downloadFile(path: String, group: DispatchGroup)
    {
        Dropbox.getDropboxClient()?.files.download(path: path).response(queue: DispatchQueue(label: "downloadSelectedFiles")) { response, error in
            if let response = response
            {
                let stringContent = String(data: response.1, encoding: .utf8)
                if CsvChecker.checkContent(fileContent: stringContent)
                {
                    DispatchQueue.main.async { [weak self] in
                        
                        guard self != nil else { return }
                        
                        self?.filesContents.append(stringContent!)
                        
                        if self?.filesContents.count == self?.filesToDownload.count
                        {
                            var graphsToCreate : [Graph] = []
                            
                            var pointCounter = 0
                            
                            let maxNumberOfPoints = self!.implementer.maxNumberOfPoints
                            
                            let currentNumberOfPoints = self!.implementer.currentNumberOfPoints
                            
                            for file in self!.filesContents
                            {
                                var data = file.components(separatedBy: .newlines)
                                
                                let title = data.first ?? ""
                                
                                var points : [Point] = []
                                
                                data.removeFirst()
                                
                                data.removeAll(where: {$0 == ""})
                                
                                pointCounter = pointCounter + data.count
                                
                                if pointCounter + currentNumberOfPoints! > maxNumberOfPoints
                                {
                                    Alert.DisplayPopUpAndDismiss(viewController: self!, title: "Error", message: "Too many points to be rendered! Remove some graphs before add others.", style: .destructive)
                                    return
                                }
                                
                                for line in data
                                {
                                    let values = line.components(separatedBy: ";")
                                    
                                    let x = Float(values[0]) as Float?
                                    let y = Float(values[1]) as Float?
                                    let z = Float(values[2]) as Float?
                                    
                                    var position = SCNVector3(x: x!, y: y!, z: z!)
                                    
                                    if(position.x<0)
                                    {
                                        position.x*=(-1)
                                    }
                                    
                                    if(position.y<0)
                                    {
                                        position.y*=(-1)
                                    }
                                    
                                    if(position.z<0)
                                    {
                                        position.z*=(-1)
                                    }
                                    
                                    let r = Float(values[3])!/255.0
                                    let g = Float(values[4])!/255.0
                                    let b = Float(values[5])!/255.0
                                    
                                    let color = UIColor(red: CGFloat(r), green: CGFloat(g), blue:CGFloat(b), alpha: CGFloat(1))
                                    
                                    let point = Point(position: position, color: color)
                                    
                                    points.append(point)
                                }
                                
                                graphsToCreate.append(Graph(title: title, points: points))
                            }
                            
                            self?.implementer.ReturnToRootViewController(graphs: graphsToCreate)
                                
                            self?.dismiss(animated: true, completion: nil)
                        }
                    }
                    
                    group.leave()
                }
                else
                {
                    DispatchQueue.main.async { [weak self] in
                        
                        guard self != nil else { return }
                        
                        let message = "The file "+path+" is not a valid .csv"
                        
                        Alert.DisplayPopUpAndDismiss(viewController: self, title: "Error", message: message, style: .destructive)
                        
                        self?.fail = true
                    }
                    
                    group.leave()
                }
            }
            else if error != nil
            {
                DispatchQueue.main.async { [weak self] in
                    
                    guard self != nil else { return }
                    
                    let message = "An error occured during the download of a file"
                    
                    Alert.DisplayPopUpAndDismiss(viewController: self, title: "Error", message: message, style: .destructive)
                    
                    self?.fail = true
                }
                
                group.leave()
            }
        }
    }
}
