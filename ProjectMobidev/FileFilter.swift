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
                && checkContent(file: file)
            {
                result.append(file)
            }
        }
        return result
    }
    
    private func checkContent(file: Files.Metadata) -> Bool
    {
        let content = Dropbox.download(file: file)
        var data = content.components(separatedBy: .newlines)
        data.remove(at: 0)
        
        for line in data
        {
            let values = content.components(separatedBy: ";")
            if !checkLine(line: values)
            {
                return false
            }
        }
        
        return true
    }
    
    private func checkLine(line: [String]) -> Bool
    {
        if line.count != 6
        {
            return false
        }
        
        if Float(line[0]) == nil || Float(line[1]) == nil || Float(line[2]) == nil || Int(line[3]) == nil || Int(line[4]) == nil || Int(line[5]) == nil
        {
            return false
        }
        
        return true
    }
    
}
