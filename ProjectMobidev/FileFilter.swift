//
//  FileFilter.swift
//  ProjectMobidev
//
//  Created by Pietro Prebianca on 18/07/2019.
//  Copyright © 2019 Pietro Prebianca. All rights reserved.
//

import Foundation
import SwiftyDropbox

struct FileFilter
{
    var root: String
    var extention: String
    var arrayFiles: [Files.Metadata]
    
    init(root: String, extention: String, arrayFiles: [Files.Metadata])
    {
        self.root = root
        self.extention=extention
        self.arrayFiles=arrayFiles
    }
    
    func extractFiles() -> [Files.Metadata]
    {
        let regex = try! NSRegularExpression(pattern: extention)
        var result: [Files.Metadata]
        result = []
        
        for file in arrayFiles
        {
            if regex.firstMatch(in: file.name, options: [], range: NSRange(location: 0, length: file.name.count)) != nil
            {
                result.append(file)
            }
        }
        return result
    }
}
