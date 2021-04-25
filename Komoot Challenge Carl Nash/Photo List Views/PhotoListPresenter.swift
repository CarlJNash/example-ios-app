//
//  PhotoListPresenter.swift
//  Komoot Challenge Carl Nash
//
//  Created by Carl on 22/04/2021.
//

import Foundation
import CoreLocation
import UIKit

/// Protocol that the MVP View should conform to for the `PhotoListPresenter`
protocol PhotoListView: AnyObject, AlertDisplayable {
    func reloadImageList()
}

/// This is the MVP Presenter for the `PhotoListView`.
/// This presenter handles the Flickr API calls and location updates.
class PhotoListPresenter: NSObject {
    
    // MARK: - Properties
    
    // Reference to the MVP View (`unowned` as it should never be `nil` but we don't want to increase the reference counter for the view)
    unowned let view: PhotoListView
    
    let apiClient = FlickrAPIClient()
    /// An array of locations that are received from the CLLocationManager. These are stored so that we know if a location has been processed already and we can ignore it.
    var didUpdateLocations = [CLLocation]()
    /// An array of locations that the user has visited and downloaded a photo for.
    var visitedLocations = [VisitedLocation]()
    
    lazy var locationManager: CLLocationManager = {
        let locationManager = CLLocationManager()
        locationManager.delegate = self
        locationManager.distanceFilter = 100 // We only want location updates every 100 meters
        locationManager.activityType = .fitness // Apple recommend this for activities such as walking. This will also pause updates if the user doesn't move for some time, saving the device battery.
        locationManager.allowsBackgroundLocationUpdates = true
        return locationManager
    }()
    
    // MARK: - Lifecycle
    
    init(view: PhotoListView) {
        self.view = view
    }
    
    // MARK: - Public Methods
    
    func startButtonTapped() {
        checkAuthorisationStatus(locationManager: locationManager)
    }
    
    func image(for indexPath: IndexPath) -> UIImage {
        visitedLocations[indexPath.item].image.image
    }
    
    func numberOfItems() -> Int {
        visitedLocations.count
    }
    
}

private extension PhotoListPresenter {

    func checkAuthorisationStatus(locationManager: CLLocationManager) {
        guard CLLocationManager.locationServicesEnabled() else {
            let alertConfig = AlertConfig(title: "Location Error",
                                          message: "Location services are not enabled, please enable in iOS Settings and try again.",
                                          buttons: [.defaultButton()])
            view.showAlert(with: alertConfig)
            return
        }
        
        switch locationManager.authorizationStatus {
        case .notDetermined:
            locationManager.requestWhenInUseAuthorization()
        case .denied:
            view.showAlert(with: .init(title: "Location Error",
                                       message: "Location permission denied, please enable in iOS Settings.",
                                       buttons: [.defaultButton()]))
        case .restricted:
            view.showAlert(with: .init(title: "Location Error",
                                       message: "Location permission restricted.",
                                       buttons: [.defaultButton()]))
        case .authorizedAlways, .authorizedWhenInUse:
            locationManager.startUpdatingLocation()
        @unknown default:
            assertionFailure()
        }
        
    }
    
}

extension PhotoListPresenter: CLLocationManagerDelegate {
    
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        checkAuthorisationStatus(locationManager: manager)
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        let latestLocation = locations.last! // Apple say this array will never be empty
        
        // Ignore multiple callbacks for the same location
        guard didUpdateLocations.contains(where: { $0.coordinate == latestLocation.coordinate }) == false,
              visitedLocations.contains(where: { $0.location.coordinate == latestLocation.coordinate }) == false else {
            print("Ignoring duplicate location: \(latestLocation)")
            return
        }
        
        // Save the latest location so we know to ignore it if we see it again
        didUpdateLocations.append(latestLocation)
        
        apiClient.searchForPhotosForLocation(lat: latestLocation.coordinate.latitude, lon: latestLocation.coordinate.longitude) { result in
            switch result {
            case .failure(let error):
                print(error)
                // TODO: Display error
            case .success(let response):
                // Find the first photo that isn't in the list of visitedLocations already - this may be for a location already in the list if the user has travelled back to the same location
                guard let firstPhoto = response.photos.photo.first(where: { photo in
                    self.visitedLocations.contains(where: { visitedLocation in
                        photo.id == visitedLocation.image.imageId
                    }) == false
                }) else {
                    print("Could not find photos for this location that aren't in the list already")
                    return
                }
                // Download the photo
                self.apiClient.downloadPhoto(serverId: firstPhoto.server, id: firstPhoto.id, secret: firstPhoto.secret, photoSize: .medium_640) { result in
                    switch result {
                    case .failure(let error):
                        print(error)
                        // TODO: Display error
                    case .success(let image):
                        // Add the visitedLocation to the beginning of the array and reload the collection view to display it
                        let visitedLocation = VisitedLocation(location: latestLocation, image: .init(imageId: firstPhoto.id, image: image))
                        self.visitedLocations.insert(visitedLocation, at: 0)
                        DispatchQueue.main.async {
                            self.view.reloadImageList()
                        }
                    }
                }
            }
        }
    }
}
