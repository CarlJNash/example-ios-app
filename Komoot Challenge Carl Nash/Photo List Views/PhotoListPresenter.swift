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
protocol PhotoListViewing: AnyObject, AlertDisplayable {
    func reloadUI()
}

/// This is the MVP Presenter for the `PhotoListView`.
/// This presenter handles the Flickr API calls and location updates.
@MainActor class PhotoListPresenter: NSObject {
    
    // MARK: - Properties
    
    // Reference to the MVP View (`unowned` as it should never be `nil` but we don't want to increase the reference counter for the view)
    unowned let view: PhotoListViewing
    
    let photosAPIClient: PhotosAPIClient
    
    // The next step would be to cache these locations on disk or on a server so they are persisted.
    /// An array of locations that the user has visited and downloaded a photo for.
    var visitedLocations = [VisitedLocation]()
    
    let locationManager: LocationManaging
    
    var startButtonTitle: String { locationManager.isUpdatingLocation ? "Stop" : "Start" }
    
    // MARK: - Lifecycle
    
    init(view: PhotoListViewing, locationManager: LocationManaging, apiClient: PhotosAPIClient) {
        self.view = view
        self.locationManager = locationManager
        self.photosAPIClient = apiClient
    }
    
    // MARK: - Public Methods
    
    func startButtonTapped() {
        // If we're already tracking a trip, then stop
        if locationManager.isUpdatingLocation {
            locationManager.stopUpdatingLocation()
            return
        }

        // If we have no locations then check if we can start a new trip
        if visitedLocations.count == 0 {
            checkAuthorisationStatus(locationManager: locationManager)
            return
        }

        // If we have locations, then check if the user wants to start a new trip
        view.showAlert(
            with: .init(
                title: "Current Trip",
                message: "Do you want to start a new trip or continue the current one? (Warning! starting a new trip will delete the current one!)",
                buttons: [
                    .init(title: "Continue Trip", style: .default, handler: { _ in
                        self.checkAuthorisationStatus(locationManager: self.locationManager)
                    }),
                    .init(title: "Start New Trip", style: .destructive, handler: { _ in
                        self.visitedLocations = []
                        self.locationManager.reset()
                        self.view.reloadUI()
                        self.checkAuthorisationStatus(locationManager: self.locationManager)
                    })
                ]
            )
        )
    }
    
    func image(for indexPath: IndexPath) -> UIImage {
        visitedLocations[indexPath.item].image.image
    }
    
    func numberOfItems() -> Int {
        visitedLocations.count
    }
    
}

private extension PhotoListPresenter {
    
    func checkAuthorisationStatus(locationManager: LocationManaging) async {
        guard await locationManager.locationServicesEnabled else {
            self.view.showAlert(
                with: .init(
                    title: "Location Error",
                    message: "Location services are not enabled, please enable in iOS Settings and try again.",
                    buttons: [.openSettingsButton(), .cancelButton()]
                )
            )
            return
        }
        
        switch locationManager.authorizationStatus {
        case .notDetermined:
            locationManager.requestWhenInUseAuthorization(completion: { [weak self] in
                self?.checkAuthorisationStatus(locationManager: locationManager)
            })
        case .denied:
            view.showAlert(with: .init(title: "Location Error",
                                       message: "Location permission denied, please enable in iOS Settings.",
                                       buttons: [.openSettingsButton(), .cancelButton()]))
        case .restricted:
            view.showAlert(with: .init(title: "Location Error",
                                       message: "Location permission restricted.",
                                       buttons: [.defaultButton()]))
        case .authorizedAlways, .authorizedWhenInUse:
            startUpdatingLocation()
            view.reloadUI()
        @unknown default:
            assertionFailure()
        }
        
    }
    
    func startUpdatingLocation() {
        locationManager.startUpdatingLocation(callback: { [weak self] result in
            guard let self else { return }
            switch result {
            case .failure(let error):
                self.view.showAlert(with: .init(title: "Location Error", message: error.localizedDescription, buttons: [.defaultButton()]))
            case .success(let location):
                Task {
                    do {
                        let response = try await self.photosAPIClient.searchForPhotosForLocation(.init(location))
                        await self.handle(response, for: location)
                    } catch {
                        DispatchQueue.main.async {
                            self.view.showAlert(with: .init(title: "Error Fetching Photos", message: error.localizedDescription, buttons: [.defaultButton()]))
                        }
                    }
                }
            }
        })
    }
                                              
    func handle(_ response: APIPhotosSearchResponse, for location: CLLocation) async {
        // Find the first photo that isn't in the list of `visitedLocations` already - this may be for a location already in the list if the user has travelled back to the same location
        guard let firstPhoto = response.photos.photo.first(where: { photo in
            self.visitedLocations.contains(where: { photo.id == $0.image.imageId }) == false
        }) else {
            print("Could not find photos for this location that aren't in the list already")
            return
        }
        
        do {
            // Download the photo
            let image = try await photosAPIClient.downloadImage(for: firstPhoto, size: .medium_640)
            // Add the visitedLocation to the beginning of the array and reload the collection view to display it
            let visitedLocation = VisitedLocation(
                location: location,
                image: .init(
                    imageId: firstPhoto.id,
                    image: image
                )
            )
            visitedLocations.insert(visitedLocation, at: 0)
            DispatchQueue.main.async {
                self.view.reloadUI()
            }
        } catch {
            view.showAlert(with: .init(title: "Error Downloading Photo", message: error.localizedDescription, buttons: [.defaultButton()]))
        }
    }
}
