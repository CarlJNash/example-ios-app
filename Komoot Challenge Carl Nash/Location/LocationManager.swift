//
//  LocationManager.swift
//  Komoot Challenge Carl Nash
//
//  Created by Carl on 25/04/2021.
//

import Foundation
import CoreLocation

struct Location {
    let latitude: Double
    let longitude: Double
    
    init(_ location: CLLocation) {
        latitude = location.coordinate.latitude
        longitude = location.coordinate.longitude
    }
}

protocol LocationManaging {
    typealias RequestAuthorizationCompletion = (() -> Void)
    typealias LocationUpdatedCallback = ((Result<CLLocation, Error>) -> Void)
    
    var locationServicesEnabled: Bool { get async }
    var isUpdatingLocation: Bool { get }
    var authorizationStatus: CLAuthorizationStatus { get }
    func requestWhenInUseAuthorization(completion: @escaping RequestAuthorizationCompletion)
    func startUpdatingLocation(callback: @escaping LocationUpdatedCallback)
    func stopUpdatingLocation()
    func reset()
}

/// A wrapper around `CLLocationManager` to provide blocks instead of delegate methods
class LocationManager: NSObject, LocationManaging {
    
    private var requestAuthorizationCompletion: RequestAuthorizationCompletion?
    private var locationUpdatedCallback: LocationUpdatedCallback?
    
    var locationServicesEnabled: Bool {
        get async {
            return await withCheckedContinuation { continuation in
                DispatchQueue.global(qos: .background).async {
                    continuation.resume(returning: CLLocationManager.locationServicesEnabled())
                }
            }
        }
    }
    
    /// An array of locations that are received from the CLLocationManager. These are stored so that we know if a location has been processed already and we can ignore it.
    private var allLocations = [CLLocation]()
    
    private lazy var clLocationManager: CLLocationManager = {
        let locationManager = CLLocationManager()
        locationManager.delegate = self
        locationManager.distanceFilter = 100 // We only want location updates every 100 meters
        locationManager.activityType = .fitness // Apple recommend this for activities such as walking. This will also pause updates if the user doesn't move for some time, saving the device battery.
        locationManager.allowsBackgroundLocationUpdates = true
        return locationManager
    }()
    
    var isUpdatingLocation: Bool = false
    
    var authorizationStatus: CLAuthorizationStatus {
        clLocationManager.authorizationStatus
    }
    
    func requestWhenInUseAuthorization(completion: @escaping RequestAuthorizationCompletion) {
        requestAuthorizationCompletion = completion
        clLocationManager.requestWhenInUseAuthorization()
    }
    
    func startUpdatingLocation(callback: @escaping LocationUpdatedCallback) {
        isUpdatingLocation = true
        locationUpdatedCallback = callback
        clLocationManager.startUpdatingLocation()
    }
    
    func stopUpdatingLocation() {
        clLocationManager.stopUpdatingLocation()
        isUpdatingLocation = false
    }
    
    func reset() {
        locationUpdatedCallback = nil
        requestAuthorizationCompletion = nil
        allLocations = []
    }
    
}

extension LocationManager: CLLocationManagerDelegate {
    
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        requestAuthorizationCompletion?()
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        // Apple say this array will never be empty. We only care about returning the last location in this case as it's the most recent.
        let latestLocation = locations.last!
        
        // Ignore multiple callbacks for the same location within x seconds
        guard allLocations.contains(where: { $0.coordinate == latestLocation.coordinate && $0.timestamp.distance(to: latestLocation.timestamp) < 10 }) == false else {
            print("Ignoring duplicate location: \(latestLocation)")
            return
        }
        
        // Save the latest location so we know to ignore it if we see it again
        allLocations.append(latestLocation)
        
        locationUpdatedCallback?(.success(latestLocation))
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print(error)
        if case CLError.denied = error {
            stopUpdatingLocation()
            locationUpdatedCallback?(.failure(error))
        }
    }
    
}
