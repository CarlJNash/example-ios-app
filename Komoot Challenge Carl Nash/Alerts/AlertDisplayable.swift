//
//  AlertDisplayable.swift
//  Komoot Challenge Carl Nash
//
//  Created by Carl on 25/04/2021.
//

import UIKit

protocol AlertDisplayable {
    func showAlert(with config: AlertConfig)
    // This matches the default `present` method on UIViewController so that any UIViewController conforms to it.
    func present(_ viewControllerToPresent: UIViewController, animated flag: Bool, completion: (() -> Void)?)
}

extension AlertDisplayable {
    // Default implementation so that views don't need to implement unless they need want to do something different
    func showAlert(with config: AlertConfig) {
        let alert = UIAlertController(title: config.title,
                                      message: config.message,
                                      preferredStyle: .alert)
        for button in config.buttons {
            alert.addAction(button)
        }
        present(alert, animated: true, completion: nil)
    }
}
