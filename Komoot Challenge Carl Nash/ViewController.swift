//
//  ViewController.swift
//  Komoot Challenge Carl Nash
//
//  Created by Carl on 21/04/2021.
//

import UIKit
import CoreLocation

class ViewController: UIViewController {

    lazy var locationManager: CLLocationManager = {
        let locationManager = CLLocationManager()
        locationManager.delegate = self
        locationManager.distanceFilter = 100 // meters
        locationManager.activityType = .fitness
        locationManager.allowsBackgroundLocationUpdates = true
        return locationManager
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Start", style: .plain, target: self, action: #selector(startButtonTapped))
    }
    
    @objc private func startButtonTapped() {
        let currentTitle = navigationItem.rightBarButtonItem!.title
        navigationItem.rightBarButtonItem?.title = currentTitle == "Stop" ? "Start" : "Stop"
        
        switch locationManager.authorizationStatus {
        case .notDetermined:
            locationManager.requestWhenInUseAuthorization()
        case .denied, .restricted:
            // TODO: present alert to user
            break
        case .authorizedAlways, .authorizedWhenInUse:
            locationManager.startUpdatingLocation()
        @unknown default:
            assertionFailure()
        }
    }
    
}

extension ViewController: CLLocationManagerDelegate {
    
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        switch manager.authorizationStatus {
        case .notDetermined:
            break // ignore
        case .denied, .restricted:
            // TODO: present alert to user
            break
        case .authorizedAlways, .authorizedWhenInUse:
            locationManager.startUpdatingLocation()
        @unknown default:
            break
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        // TODO: search for images based on location
        print(locations)
    }
}
