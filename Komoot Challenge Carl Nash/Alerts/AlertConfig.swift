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
        .init(title: "OK", style: .default, handler: nil)
    }
}
