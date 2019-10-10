//
//  ViewTest.swift
//  ProjectMobidev
//
//  Created by Pietro Prebianca on 29/07/2019.
//  Copyright © 2019 Pietro Prebianca. All rights reserved.
//

import UIKit
import ARKit
import SwiftyDropbox

/*
 This view controller displays all .csv files available
 in the user dropbox.
*/

class FilesViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, ReturnToRoot{
    
    var maxNumberOfPoints: Int = 1000
    
    var currentNumberOfPoints: Int!
    
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
            if let graphs = sender as? [Graph]
            {
                let destination = segue.destination as! MainViewController
                
                for graph in graphs
                {
                    destination.graphs.append(graph)
                }
                
                destination.graphToCreate = graphs.count
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
        let list = tableView.indexPathsForSelectedRows
        
        if list == nil
        {
            navigationItem.rightBarButtonItem?.isEnabled = false
        }
    }
    
    //Utility functions
    
    func setUp()
    {
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(btnDoneTouchDown))
        navigationItem.rightBarButtonItem?.isEnabled = false
        
        navigationItem.title = "Choose graphs to plot"
        
        table.allowsMultipleSelection = true
        table.reloadData()
    }
    
    //Event functions
    
    @objc func btnDoneTouchDown()
    {
        AudioServicesPlaySystemSound(1103)
        performSegue(withIdentifier: "toDownloadFilesViewController", sender: nil)
    }
    
    //Protocol stub
    
    func ReturnToRootViewController(graphs : [Graph]) {
        performSegue(withIdentifier: "returnToRoot", sender: graphs)
    }

}
