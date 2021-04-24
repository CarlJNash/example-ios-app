//
//  PhotoListPresenter.swift
//  Komoot Challenge Carl Nash
//
//  Created by Carl on 22/04/2021.
//

import Foundation
import CoreLocation
import UIKit

class PhotoListPresenter: NSObject {
    
    unowned let view: PhotoListView
    
    let apiClient = APIClient()
    var didUpdateLocations = [CLLocation]()
    var visitedLocations = [VisitedLocation]()
    
    init(view: PhotoListView) {
        self.view = view
    }
    
    lazy var locationManager: CLLocationManager = {
        let locationManager = CLLocationManager()
        locationManager.delegate = self
        locationManager.distanceFilter = 100 // We only want location updates every 100 meters
        locationManager.activityType = .fitness // Apple recommend this for things like walking. This will also pause updates if the user doesn't move for some time.
        locationManager.allowsBackgroundLocationUpdates = true
        return locationManager
    }()
    
    func startButtonTapped() {
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
    
    func image(for indexPath: IndexPath) -> UIImage {
        visitedLocations[indexPath.item].image.image
    }
    
    func numberOfItems() -> Int {
        visitedLocations.count
    }
    
}

extension PhotoListPresenter: CLLocationManagerDelegate {
    
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
        let latestLocation = locations.last! // This array will never be empty
        
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
