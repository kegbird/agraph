//
//  DownloadFileViewController.swift
//  ProjectMobidev
//
//  Created by Pietro Prebianca on 30/07/2019.
//  Copyright © 2019 Pietro Prebianca. All rights reserved.
//

import UIKit

protocol ReturnToRoot
{
    func ReturnToRootViewController(filesContent : [String])
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
                            self?.implementer.ReturnToRootViewController(filesContent: self!.filesContents)
                            
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
