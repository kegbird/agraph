//
//  DownloadFileListViewController.swift
//  ProjectMobidev
//
//  Created by Pietro Prebianca on 29/07/2019.
//  Copyright © 2019 Pietro Prebianca. All rights reserved.
//

import UIKit
import SwiftyDropbox

protocol DisplayFileList
{
    func displayDownloadedFileList(files : [Files.Metadata])
}

/*
 This view controller just downloads all the .csv file list (just names not their content)
 of all .csv files, available in the user's dropbox directory.
 This list is displayed by filesviewcontroller.
*/

class DownloadFileListViewController: UIViewController {
    
    @IBOutlet weak var infoLabel: UILabel!
    
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    
    var implementer : DisplayFileList?
    
    override var prefersStatusBarHidden: Bool
    {
        return true
    }
    
    override func viewDidLoad() {
        downloadFileList()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: animated)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        navigationController?.setNavigationBarHidden(false, animated: animated)
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
                        
                        guard self != nil else { return }
                        
                        var files:[Files.Metadata]=[]
                        
                        for file in extractedFiles
                        {
                            files.append(file)
                        }
                        
                        self?.dismiss(animated: true, completion: (
                            { [weak self] in
                                
                                guard self != nil else { return }
                            self?.implementer?.displayDownloadedFileList(files: files)
                            }))
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
                
                guard self != nil else { return }
                
                self?.activityIndicator.stopAnimating()
                
                    Alert.DisplayPopUpAndDismiss(viewController: self, title: "Error", message: message, style: .destructive)
        }
    }
}
