//
//  Komoot_Challenge_Carl_NashTests.swift
//  Komoot Challenge Carl NashTests
//
//  Created by Carl on 21/04/2021.
//

import XCTest
import CoreLocation
@testable import Komoot_Challenge_Carl_Nash

class PhotoListPresenterTests: XCTestCase {
    
    var view: MockPhotoListView!
    var presenter: PhotoListPresenter!
    var locationManager: MockLocationManager!
    var apiClient: MockAPIClient!
    
    override func setUpWithError() throws {
        view = MockPhotoListView()
        locationManager = MockLocationManager()
        apiClient = MockAPIClient()
        presenter = PhotoListPresenter(view: view, locationManager: locationManager, apiClient: apiClient)
    }
    
    func testStartButtonChecksAuthorizationStatus() throws {
        locationManager.isUpdatingLocation = false
        locationManager.authorizationStatus = .notDetermined
        presenter.startButtonTapped()
        wait(for: [locationManager.requestAuthorizationExpectation], timeout: 0)
    }
    
    func testStartButtonUpdatesLocationAndReloadsUI() throws {
        locationManager.isUpdatingLocation = false
        locationManager.authorizationStatus = .authorizedWhenInUse
        presenter.startButtonTapped()
        wait(for: [locationManager.startUpdatingLocationExpectation,
                   view.reloadUIExpectation], timeout: 0)
    }
    
    func testStartButtonStopsUpdatingLocation() {
        locationManager.isUpdatingLocation = true
        presenter.startButtonTapped()
        wait(for: [locationManager.stopUpdatingLocationExpectation], timeout: 0)
    }
    
    func testShowsAlertForStartingTripWhenExistingTrip() {
        locationManager.isUpdatingLocation = false
        presenter.visitedLocations = [.mock()]
        presenter.startButtonTapped()
        wait(for: [view.showAlertExpectation], timeout: 0)
        XCTAssertEqual(view.showAlertConfig?.title, "Current Trip")
        XCTAssertEqual(view.showAlertConfig?.buttons.count, 2)
    }
    
    func testNumberOfItems() {
        presenter.visitedLocations = [.mock()]
        XCTAssertEqual(presenter.numberOfItems(), 1)
        
        presenter.visitedLocations = [.mock(), .mock()]
        XCTAssertEqual(presenter.numberOfItems(), 2)
    }
    
    func testStartButtonTitle() {
        locationManager.isUpdatingLocation = false
        XCTAssertEqual(presenter.startButtonTitle, "Start")
        
        locationManager.isUpdatingLocation = true
        XCTAssertEqual(presenter.startButtonTitle, "Stop")
    }
    
    func testStartButtonSearchesForPhotoAndDownloadsPhoto() {
        let testLocation = CLLocation(latitude: 12345, longitude: 678910)
        let locationManager = MockLocationManager(locationUpdatedResult: .success(testLocation))
        locationManager.isUpdatingLocation = false
        locationManager.authorizationStatus = .authorizedWhenInUse
        
        let searchResponse = APIPhotosSearchResponse(photos: .init(photo: [.init(id: "imageId", server: "serverId", secret: "secret")]))
        let testImage = #imageLiteral(resourceName: "image-not-found")
        let apiClient = MockAPIClient(searchPhotosCompletionResult: .success(searchResponse),
                                      downloadPhotosCompletionResult: .success(testImage))
        
        let presenter = PhotoListPresenter(view: view, locationManager: locationManager, apiClient: apiClient)
        
        presenter.startButtonTapped()
        
        wait(for: [locationManager.startUpdatingLocationExpectation,
                   apiClient.searchPhotosExpectation,
                   apiClient.downloadPhotoExpectation], timeout: 0)
        
        guard let visitedLocation = presenter.visitedLocations.first else {
            XCTFail()
            return
        }
        let expectedLocation = VisitedLocation(location: testLocation,
                                               image: .init(imageId: "imageId", image: testImage))
        XCTAssertEqual(visitedLocation, expectedLocation)
    }
    
}

extension VisitedLocation: Equatable {
    public static func == (lhs: VisitedLocation, rhs: VisitedLocation) -> Bool {
        return lhs.image.imageId == rhs.image.imageId &&
            lhs.image.image == rhs.image.image &&
            lhs.location == rhs.location
    }
}

// MARK: - Mocks

class MockPhotoListView: PhotoListViewing {
    let reloadUIExpectation = XCTestExpectation()
    func reloadUI() {
        reloadUIExpectation.fulfill()
    }
    
    let showAlertExpectation = XCTestExpectation()
    var showAlertConfig: AlertConfig?
    func showAlert(with config: AlertConfig) {
        showAlertExpectation.fulfill()
        showAlertConfig = config
    }
    
    let presentVCExpectation = XCTestExpectation()
    func present(_ viewControllerToPresent: UIViewController, animated flag: Bool, completion: (() -> Void)?) {
        presentVCExpectation.fulfill()
    }
}

class MockLocationManager: LocationManaging {
    
    init(locationUpdatedResult: Result<CLLocation, Error>? = nil) {
        self.locationUpdatedResult = locationUpdatedResult
    }
    var locationUpdatedResult: Result<CLLocation, Error>?
    var isUpdatingLocation: Bool = false
    var authorizationStatus: CLAuthorizationStatus = .authorizedWhenInUse
    
    let requestAuthorizationExpectation = XCTestExpectation(description: "requestAuthorizationExpectation")
    func requestWhenInUseAuthorization(completion: @escaping RequestAuthorizationCompletion) {
        requestAuthorizationExpectation.fulfill()
    }
    
    let startUpdatingLocationExpectation = XCTestExpectation(description: "startUpdatingLocationExpectation")
    func startUpdatingLocation(callback: @escaping LocationUpdatedCallback) {
        startUpdatingLocationExpectation.fulfill()
        if let locationUpdatedResult = locationUpdatedResult {
            callback(locationUpdatedResult)
        }
    }
    
    let stopUpdatingLocationExpectation = XCTestExpectation(description: "stopUpdatingLocationExpectation")
    func stopUpdatingLocation() {
        stopUpdatingLocationExpectation.fulfill()
    }
    
    let resetExpectation = XCTestExpectation(description: "resetExpectation")
    func reset() {
        resetExpectation.fulfill()
    }
}

class MockAPIClient: APIClient {
    init(searchPhotosCompletionResult: Result<APIPhotosSearchResponse, Error>? = nil,
         downloadPhotosCompletionResult: Result<UIImage, Error>? = nil) {
        self.searchPhotosCompletionResult = searchPhotosCompletionResult
        self.downloadPhotosCompletionResult = downloadPhotosCompletionResult
    }
    
    var searchPhotosCompletionResult: Result<APIPhotosSearchResponse, Error>?
    let searchPhotosExpectation = XCTestExpectation()
    func searchForPhotosForLocation(lat: Double, lon: Double, completion: @escaping (Result<APIPhotosSearchResponse, Error>) -> Void) {
        searchPhotosExpectation.fulfill()
        if let searchPhotosCompletionResult = searchPhotosCompletionResult {
            completion(searchPhotosCompletionResult)
        }
    }
    
    var downloadPhotosCompletionResult: Result<UIImage, Error>?
    let downloadPhotoExpectation = XCTestExpectation()
    func downloadPhoto(serverId: String, id: String, secret: String, photoSize: FlickrPhotoSize, completion: @escaping (Result<UIImage, Error>) -> Void) {
        downloadPhotoExpectation.fulfill()
        if let downloadPhotosCompletionResult = downloadPhotosCompletionResult {
            completion(downloadPhotosCompletionResult)
        }
    }
}

extension VisitedLocation {
    static func mock() -> VisitedLocation {
        return .init(location: .init(), image: .init(imageId: "imageId", image: UIImage()))
    }
}
