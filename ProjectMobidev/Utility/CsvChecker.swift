//
//  CsvChecker.swift
//  ProjectMobidev
//
//  Created by Pietro Prebianca on 20/07/2019.
//  Copyright © 2019 Pietro Prebianca. All rights reserved.
//

import Foundation

struct CsvChecker
{
    public static func checkContent(fileContent: String?) -> Bool
    {
        if let content = fileContent
        {
            var data = content.components(separatedBy: .newlines)
            
            data.removeFirst()
            
            data.removeAll(where: {$0 == ""})
            
            for line in data
            {
                let values = line.components(separatedBy: ";")
                if !checkLine(line: values)
                {
                    return false
                }
            }
            
            return true
        }
        
        return false
    }
    
    private static func checkLine(line: [String]) -> Bool
    {
        if line.count != 6
        {
            return false
        }
        
        if Float(line[0]) == nil || Float(line[1]) == nil || Float(line[2]) == nil || Int(line[3]) == nil || Int(line[4]) == nil || Int(line[5]) == nil
        {
            return false
        }
        
        if Int(line[3])!>255 || Int(line[4])!>255 || Int(line[5])!>255
        {
            return false
        }
        
        return true
    }
}
