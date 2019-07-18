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

    var activityIndicator = UIActivityIndicatorView()
    
    @IBOutlet weak var filesTable: UITableView!
    
    var client:DropboxClient?
    
    override func viewDidLoad() {
        
        super.viewDidLoad()
        
        activityIndicator.center = self.view.center
        
        activityIndicator.hidesWhenStopped = true
        
        activityIndicator.style = UIActivityIndicatorView.Style.gray
        
        view.addSubview(activityIndicator)
        
        activityIndicator.startAnimating()
        
        
        client?.files.listFolder(path: "", recursive: true).response(queue: DispatchQueue(label: "downloadFiles"), completionHandler: { (response, error) in
            
            if let result = response
            {
                let filter = FileFilter(root: "", extention: ".csv", arrayFiles: result.entries)
                var extractedFiles = filter.extractFiles()
                
                DispatchQueue.main.async {
                    self.activityIndicator.stopAnimating()
                }
            }
            else if let error = error
            {
                print("An error occurred during the fetch of files from dropbox:"+error.description)
            }
        })
        
        filesTable.delegate = self
        filesTable.dataSource = self
        
        /*let task = URLSession.shared.dataTask(with: url!, completionHandler: {(data, response, error) in
            guard let data = data, error == nil else { return }
                
            do {
                /*var users: Users!
                let decoder: JSONDecoder = JSONDecoder.init()
                users = try decoder.decode(Users.self, from: data)
                    
                DispatchQueue.global().async { [weak self] in
                    for x in users.users
                    {
                        self?.coreDataController.addUser(utente: x)
                    }
                    self?.activityIndicator.stopAnimating()
                    self?.userList.reloadData()
                        
                }*/
            } catch let error as NSError {
                print(error)
            }
        })
            
        task.resume()*/
    }
    
    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 0
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        return 0
    }

    /*
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "reuseIdentifier", for: indexPath)

        // Configure the cell...

        return cell
    }
    */

    /*
    // Override to support conditional editing of the table view.
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        return true
    }
    */

    /*
    // Override to support editing the table view.
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            // Delete the row from the data source
            tableView.deleteRows(at: [indexPath], with: .fade)
        } else if editingStyle == .insert {
            // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
        }    
    }
    */

    /*
    // Override to support rearranging the table view.
    override func tableView(_ tableView: UITableView, moveRowAt fromIndexPath: IndexPath, to: IndexPath) {

    }
    */

    /*
    // Override to support conditional rearranging of the table view.
    override func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the item to be re-orderable.
        return true
    }
    */

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
