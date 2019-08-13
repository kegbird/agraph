//
//  DownloadFileListViewController.swift
//  ProjectMobidev
//
//  Created by Pietro Prebianca on 29/07/2019.
//  Copyright © 2019 Pietro Prebianca. All rights reserved.
//

import UIKit
import SwiftyDropbox

class DownloadFileListViewController: UIViewController {
    
    @IBOutlet weak var infoLabel: UILabel!
    
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    
    override func viewDidLoad() {
        downloadFileList()
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        if segue.identifier == "toFilesTableViewController"
        {
            let destination = segue.destination as! FilesViewController
            destination.files = sender as! [Files.Metadata]
        }
    }
    
    func downloadFileList()
    {
        if Dropbox.getDropboxClient() != nil
        {
            Dropbox.getDropboxClient()?.files.listFolder(path: "", recursive: true).response(queue: DispatchQueue(label: "downloadFileList"), completionHandler: { (response, error) in
                
                if let result = response
                {
                    let filter = FileFilter(root: "", extention: ".csv", arrayFiles: result.entries)
                    let extractedFiles = filter.extractFiles()
                    
                    DispatchQueue.main.async { [weak self] in
                        var files:[Files.Metadata]=[]
                        
                        for file in extractedFiles
                        {
                            files.append(file)
                        }
                        
                        self?.performSegue(withIdentifier: "toFilesTableViewController", sender: files)
                    }
                }
                else if let error = error
                {
                    switch error as CallError
                    {
                    case .authError:
                        Dropbox.deleteAccessToken()
                        self.DisplayErrorPopUp(message: "An error occured during the data fetching from dropbox")
                        break
                    default:
                        self.DisplayErrorPopUp(message: "An error occured during the data fetching from dropbox")
                        break
                        
                    }
                }
            })
        }
        else
        {
            DisplayErrorPopUp(message: "An error occured during the data fetching from dropbox")
        }
    }
    
    func authorizeApp(){
        DropboxClientsManager.authorizeFromController(UIApplication.shared,
                                                      controller: self,
                                                      openURL: { (url: URL) -> Void in
                                                        UIApplication.shared.open(url, options: [:], completionHandler: nil)
        })
    }
    
    func DisplayErrorPopUp(message: String)
    {
        DispatchQueue.main.async
            { [weak self] in
                self?.activityIndicator.stopAnimating()
                
                    Alert.DisplayPopUp(viewController: self, title: "Error", message: message, style: .destructive)
        }
    }
}
