//
//  ViewTest.swift
//  ProjectMobidev
//
//  Created by Pietro Prebianca on 29/07/2019.
//  Copyright © 2019 Pietro Prebianca. All rights reserved.
//

import UIKit
import SwiftyDropbox

class FilesViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, ReturnToRoot{
    
    @IBOutlet weak var table: UITableView!

    override var prefersStatusBarHidden: Bool
    {
        return true
    }
    
    var files:[Files.Metadata]=[]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setUp()
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        if segue.identifier == "toDownloadFilesViewController"
        {
            if let indexPaths = table.indexPathsForSelectedRows
                {
                var filesPath : [String] = []
                
                for i in indexPaths
                {
                    filesPath.append(files[i.row].pathLower!)
                }
                
                let destination = segue.destination as! DownloadFilesViewController
                destination.filesToDownload = filesPath
                    destination.implementer = self
            }
        }
        else if segue.identifier == "returnToRoot"
        {
            let destination = segue.destination as! MainViewController
            
            if ((sender as? [String]) != nil)
            {
                destination.graphToCreate = sender as! [String]
            }
        }
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
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath)
    {
        tableView.selectRow(at: indexPath, animated: true, scrollPosition: .none)
        navigationItem.rightBarButtonItem?.isEnabled = true
    }
    
    func tableView(_ tableView: UITableView, didDeselectRowAt indexPath: IndexPath)
    {
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    //Utility functions
    
    func setUp()
    {
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(btnDoneTouchDown))
        navigationItem.rightBarButtonItem?.isEnabled = false
        table.allowsMultipleSelection = true
        table.reloadData()
    }
    
    //Event functions
    
    @objc func btnDoneTouchDown()
    {
        performSegue(withIdentifier: "toDownloadFilesViewController", sender: nil)
    }
    
    //Protocol stub
    
    func ReturnToRootViewController(filesContent : [String]) {
        performSegue(withIdentifier: "returnToRoot", sender: filesContent)
    }

}
