//
//  AlertConfig.swift
//  Komoot Challenge Carl Nash
//
//  Created by Carl on 25/04/2021.
//

import UIKit

struct AlertConfig {
    let title: String
    let message: String
    let buttons: [UIAlertAction]
}

extension UIAlertAction {
    
    static func defaultButton(title: String = "OK") -> UIAlertAction {
        .init(title: title, style: .default, handler: nil)
    }
    
    static func cancelButton(title: String = "Cancel") -> UIAlertAction {
        .init(title: title, style: .cancel, handler: nil)
    }
    
    static func openSettingsButton(title: String = "Open Settings") -> UIAlertAction {
        .init(title: title, style: .default, handler: { _ in
            UIApplication.shared.open(URL(string: UIApplication.openSettingsURLString)!, options: [:], completionHandler: nil)
        })
    }
    
}
