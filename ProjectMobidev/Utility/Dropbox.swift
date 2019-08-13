//
//  Dropbox.swift
//  ProjectMobidev
//
//  Created by Pietro Prebianca on 18/07/2019.
//  Copyright © 2019 Pietro Prebianca. All rights reserved.
//

import Foundation
import SwiftyDropbox

class Dropbox
{
    private init()
    {
        DropboxClientsManager.setupWithAppKey("rkbj364everh4f4")
    }
    
    class func initialize()
    {
        let _ = Dropbox()
    }
    
    class func getDropboxClient() -> DropboxClient?
    {
        return DropboxClientsManager.authorizedClient
    }
    
    class func deleteAccessToken()
    {
        DropboxClientsManager.unlinkClients()
    }
}
