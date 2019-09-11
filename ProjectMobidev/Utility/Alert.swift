//
//  Alert.swift
//  ProjectMobidev
//
//  Created by Pietro Prebianca on 11/08/2019.
//  Copyright © 2019 Pietro Prebianca. All rights reserved.
//

import Foundation
import UIKit

class Alert
{
    class func DisplayPopUpAndDismiss(viewController: UIViewController?, title: String,message: String, style: UIAlertAction.Style)
    {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        
        alert.addAction(UIAlertAction(title: "Ok", style: style, handler: { (action) in
            viewController?.dismiss(animated: true, completion: nil)
        }))
                
        viewController?.present(alert, animated: true, completion: nil)
    }
    
    class func DisplayPopUp(viewController: UIViewController?, title: String,message: String, style: UIAlertAction.Style)
    {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        
        alert.addAction(UIAlertAction(title: "Ok", style: style, handler: { (action) in }))
        
        viewController?.present(alert, animated: true, completion: nil)
    }
}
