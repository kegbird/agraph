//
//  Dropbox.swift
//  ProjectMobidev
//
//  Created by Pietro Prebianca on 18/07/2019.
//  Copyright © 2019 Pietro Prebianca. All rights reserved.
//

import Foundation
import SwiftyDropbox
import Alamofire

class Dropbox
{
    private init()
    {
        DropboxClientsManager.setupWithAppKey("rkbj364everh4f4")
    }
    
    private static var share: Dropbox = {
        return Dropbox()
    }()
    
    class func initialize() -> Dropbox
    {
        return share
    }
    
    class func getDropboxClient() -> DropboxClient?
    {
        return DropboxClientsManager.authorizedClient
    }
    
    class func download(file: Files.Metadata) -> String
    {
        return ""
    }
}
