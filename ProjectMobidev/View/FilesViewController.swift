//
//  ViewTest.swift
//  ProjectMobidev
//
//  Created by Pietro Prebianca on 29/07/2019.
//  Copyright © 2019 Pietro Prebianca. All rights reserved.
//

import UIKit
import SwiftyDropbox

class FilesViewController: UIViewController, UITableViewDelegate, UITableViewDataSource{
    
    @IBOutlet weak var table: UITableView!

    @IBOutlet weak var btnDone: UIBarButtonItem!
    
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
                
                print(filesPath)
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
        btnDone.isEnabled = true
    }
    
    func tableView(_ tableView: UITableView, didDeselectRowAt indexPath: IndexPath)
    {
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    //Utility functions
    
    func setUp()
    {
        btnDone.isEnabled=false
        table.allowsMultipleSelection = true
        table.reloadData()
    }
    
    //Event functions
    
    @IBAction func btnBackTouchDown(_ sender: Any)
    {
        performSegue(withIdentifier: "toMainViewController", sender: nil)
    }
    
    @IBAction func btnDoneTouchDown(_ sender: Any)
    {
        performSegue(withIdentifier: "toDownloadFilesViewController", sender: nil)
    }

}
