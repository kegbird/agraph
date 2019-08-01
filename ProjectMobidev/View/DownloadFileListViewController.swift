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
    
    @IBOutlet weak var popUpView: UIView!
    
    @IBOutlet weak var infoLabel: UILabel!
    
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    
    override func viewDidLoad() {
        setUp()
        downloadFileList()
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        if segue.identifier == "toFilesTableViewController"
        {
            let destination = segue.destination as! FilesViewController
            destination.files = sender as! [Files.Metadata]
        }
    }
    
    func setUp()
    {
        popUpView.layer.cornerRadius = popUpView.bounds.height/4
    }
    
    func downloadFileList()
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
            else if error != nil
            {
                DispatchQueue.main.async { [weak self] in
                    //Altrimenti display errore e ritorno alla scena precedente
                    self?.activityIndicator.stopAnimating()
                    
                    let alert = UIAlertController(title: "Error", message: "An error occured during the data fetching from dropbox", preferredStyle: .alert)

                    
                    alert.addAction(UIAlertAction(title: "Ok", style: .destructive, handler: { (action) in
                        self?.dismiss(animated: true, completion: nil)
                    }))
                    
                    self?.present(alert, animated: true, completion: nil)
                }
            }
        })
    }

}
