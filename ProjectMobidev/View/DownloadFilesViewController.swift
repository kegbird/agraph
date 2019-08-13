//
//  DownloadFileViewController.swift
//  ProjectMobidev
//
//  Created by Pietro Prebianca on 30/07/2019.
//  Copyright © 2019 Pietro Prebianca. All rights reserved.
//

import UIKit

class DownloadFilesViewController: UIViewController {

    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    
    var filesToDownload : [String]=[]
    
    var filesContents : [String]=[]
    
    var fail = false

    override func viewDidLoad() {
        super.viewDidLoad()
        downloadFiles()
    }
    
    func downloadFiles()
    {
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            
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
                        self?.filesContents.append(stringContent!)
                        
                        if self?.filesContents.count == self?.filesToDownload.count
                        {
                            self?.performSegue(withIdentifier: "toMainViewController", sender: nil)
                        }
                    }
                    group.leave()
                }
                else
                {
                    print("marcio")
                    DispatchQueue.main.async { [weak self] in
                        let message = "The file "+path+" is not a valid .csv"
                        
                        let alert = UIAlertController(title: "Error", message: message, preferredStyle: .alert)
                        
                        
                        alert.addAction(UIAlertAction(title: "Ok", style: .destructive, handler: { (action) in
                            self?.dismiss(animated: true, completion: nil)
                        }))
                        
                        self?.present(alert, animated: true, completion: nil)
                        self?.fail = true
                        group.leave()
                    }
                }
            }
            else if error != nil
            {
                print("errore")
                DispatchQueue.main.async { [weak self] in
                    let alert = UIAlertController(title: "Error", message: "An error occured during the download of a file", preferredStyle: .alert)
                    
                    
                    alert.addAction(UIAlertAction(title: "Ok", style: .destructive, handler: { (action) in
                        self?.dismiss(animated: true, completion: nil)
                    }))
                    
                    self?.present(alert, animated: true, completion: nil)
                    self?.fail = true
                    group.leave()
                }
            }
        }
    }
}
