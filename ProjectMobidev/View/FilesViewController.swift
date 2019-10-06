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
 in the user dropbox; it also converts the content of
 all downloaded files to graph objects.
*/

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
            
            if let files = sender as? [String]
            {
                var graphToCreate : [Graph] = []
                
                for file in files
                {
                    var data = file.components(separatedBy: .newlines)
                    
                    let title = data.first ?? ""
                    
                    var points : [Point] = []
                    
                    data.removeFirst()
                    
                    data.removeAll(where: {$0 == ""})
                    
                    for line in data
                    {
                        let values = line.components(separatedBy: ";")
                        
                        let x = Float(values[0]) as Float?
                        let y = Float(values[1]) as Float?
                        let z = Float(values[2]) as Float?
                        
                        var position = SCNVector3(x: x!, y: y!, z: z!)
                        
                        if(position.x<0)
                        {
                            position.x*=(-1)
                        }
                        
                        if(position.y<0)
                        {
                            position.y*=(-1)
                        }
                        
                        if(position.z<0)
                        {
                            position.z*=(-1)
                        }
                        
                        let r = Float(values[3])!/255.0
                        let g = Float(values[4])!/255.0
                        let b = Float(values[5])!/255.0
                        
                        let color = UIColor(red: CGFloat(r), green: CGFloat(g), blue: CGFloat(b), alpha: CGFloat(1))
                        
                        let point = Point(position: position, color: color)
                        
                        points.append(point)
                    }
                    
                    graphToCreate.append(Graph(title: title, points: points))
                }
                destination.graphToCreate = graphToCreate
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
    
    func ReturnToRootViewController(filesContent : [String]) {
        performSegue(withIdentifier: "returnToRoot", sender: filesContent)
    }

}
