//
//  FilesViewControllerTableViewController.swift
//  ProjectMobidev
//
//  Created by Pietro Prebianca on 18/07/2019.
//  Copyright © 2019 Pietro Prebianca. All rights reserved.
//

import UIKit
import Foundation
import Alamofire
import SwiftyDropbox

class FilesTableViewController: UITableViewController {

    @IBOutlet weak var filesTable: UITableView!
    
    var activityIndicator = UIActivityIndicatorView()
    
    var client:DropboxClient?
    
    var files:[Files.Metadata]=[]
    
    var filesSelectedContent:[String]=[]
    
    var rpc:RpcRequest<Files.ListFolderResultSerializer, Files.ListFolderErrorSerializer>?
    
    var cellSelected = 0
    
    override func viewDidLoad() {
        
        super.viewDidLoad()
        
        setUp()
        
        downloadFileList()
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        if rpc != nil
        {
            rpc?.cancel()
        }
    }
    
    // MARK: - Table view data source
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return files.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
            if(indexPath.row<files.count)
            {
                if let cell = tableView.dequeueReusableCell(withIdentifier: "fileCell", for: indexPath) as? FileTableCellView
                {
                    let file = files[indexPath.row]
                    cell.fileName.text = file.name
                    cell.filePath.text = file.pathDisplay
                    return cell
                }
            }
            return UITableViewCell()
    }

    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath)
    {
        tableView.cellForRow(at: indexPath)?.accessoryType = UITableViewCell.AccessoryType.checkmark
        cellSelected = cellSelected + 1
        self.navigationItem.rightBarButtonItem?.isEnabled = true
    }
    
    override func tableView(_ tableView: UITableView, didDeselectRowAt indexPath: IndexPath)
    {
        tableView.cellForRow(at: indexPath)?.accessoryType = UITableViewCell.AccessoryType.none
        cellSelected = cellSelected - 1
        
        if cellSelected == 0
        {
            self.navigationItem.rightBarButtonItem?.isEnabled = false
        }
    }
    
    func setUp()
    {
        cellSelected=0
        filesSelectedContent = []
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(checkFiles))
        self.navigationItem.rightBarButtonItem?.isEnabled = false
        tableView.allowsMultipleSelection = true
        activityIndicator.center = self.view.center
        activityIndicator.hidesWhenStopped = true
        activityIndicator.style = UIActivityIndicatorView.Style.gray
        view.addSubview(activityIndicator)
        activityIndicator.startAnimating()
        filesTable.delegate = self
        filesTable.dataSource = self
    }
    
    func downloadFileList()
    {
        rpc = client?.files.listFolder(path: "", recursive: true).response(queue: DispatchQueue(label: "downloadFiles"), completionHandler: { (response, error) in
            
            if let result = response
            {
                let filter = FileFilter(root: "", extention: ".csv", arrayFiles: result.entries)
                let extractedFiles = filter.extractFiles()
                
                DispatchQueue.main.async {
                    self.files.removeAll()
                    
                    for file in extractedFiles
                    {
                        self.files.append(file)
                    }
                    
                    self.filesTable.reloadData()
                    self.activityIndicator.stopAnimating()
                }
            }
            else if let error = error
            {
                print("An error occurred during the fetch of files from dropbox:"+error.description)
            }
        })
    }
    
    
    func downloadSelectedFile(path: String)
    {
        client?.files.download(path: path)
            .response { response, error in
                if let response = response
                {
                    let stringContent = String(data: response.1, encoding: .utf8)
                    if(CsvChecker.checkContent(fileContent: stringContent))
                    {
                        //su thread a parte syncrono, aggiorna l'array dei file
                        DispatchQueue.main.async {
                            self.filesSelectedContent.append(stringContent!)
                            
                            if self.filesSelectedContent.count == self.cellSelected
                            {
                                //ho finito e tutti i file sono validi
                            }
                            else
                            {
                                //gestire errore
                            }
                        }
                    }
                    
                }
                else if let error = error
                {
                    print(error)
                    //gestire errore
                }
        }
    }
    
    @objc func checkFiles()
    {
        self.navigationItem.rightBarButtonItem?.isEnabled = false
        for i in 0...cellSelected-1
        {
            if let path = files[i].pathLower
            {
                downloadSelectedFile(path: path)
            }
        }
    }
    
}
