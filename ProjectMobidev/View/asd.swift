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

class asd: UIViewController, UITableViewDataSource, UITableViewDelegate {
    
    @IBOutlet weak var filesTable: UITableView!
    
    var files:[Files.Metadata]=[]
    
    var filesSelectedContent:[String]=[]
    
    var cellSelected = 0
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setUp()
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return files.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
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
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 0
    }
    
    
    // MARK: - Table view data source
    /*override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
     
     }*/
    
    /*override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
     
     
     }*/
    
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath)
    {
        tableView.cellForRow(at: indexPath)?.accessoryType = UITableViewCell.AccessoryType.checkmark
        cellSelected = cellSelected + 1
        self.navigationItem.rightBarButtonItem?.isEnabled = true
    }
    
    func tableView(_ tableView: UITableView, didDeselectRowAt indexPath: IndexPath)
    {
        tableView.cellForRow(at: indexPath)?.accessoryType = UITableViewCell.AccessoryType.none
        cellSelected = cellSelected - 1
        
        if cellSelected == 0
        {
            self.navigationItem.rightBarButtonItem?.isEnabled = false
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier=="toDownloadFilesViewController"
        {
        }
        else if segue.identifier=="toMainViewController"
        {
            let destination = segue.destination as! MainViewController
        }
    }
    
    func setUp()
    {
        cellSelected=0
        filesTable.delegate = self
        filesTable.dataSource = self
        filesTable.reloadData()
    }
    
    /*func downloadSelectedFile(path: String)
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
     }*/
    
    @objc func goToDownloadFilesViewController()
    {
        performSegue(withIdentifier: "toDownloadFilesViewController", sender: nil)
        /*
         self.navigationItem.rightBarButtonItem?.isEnabled = false
         for i in 0...cellSelected-1
         {
         if let path = files[i].pathLower
         {
         downloadSelectedFile(path: path)
         }
         }*/
    }
    
    @objc func returnToMainViewController()
    {
        performSegue(withIdentifier: "toMainViewController", sender: nil)
    }
    
}

