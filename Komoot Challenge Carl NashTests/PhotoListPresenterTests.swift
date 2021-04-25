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
    
    override func setUpWithError() throws {
        view = MockPhotoListView()
        locationManager = MockLocationManager()
        presenter = PhotoListPresenter(view: view, locationManager: locationManager)
    }
    
    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }
    
    func testPresenterStartButtonChecksAuthorizationStatus() throws {
        locationManager.isUpdatingLocation = false
        locationManager.authorizationStatus = .notDetermined
        presenter.startButtonTapped()
        wait(for: [locationManager.requestAuthorizationExpectation], timeout: 0)
    }
    
    func testPresenterStartButtonUpdatesLocation() throws {
        locationManager.isUpdatingLocation = false
        locationManager.authorizationStatus = .authorizedWhenInUse
        presenter.startButtonTapped()
        wait(for: [locationManager.startUpdatingLocationExpectation], timeout: 0)
    }
    
    func testPresenterStartButtonStopsUpdatingLocation() {
        locationManager.isUpdatingLocation = true
        presenter.startButtonTapped()
        wait(for: [locationManager.stopUpdatingLocationExpectation], timeout: 0)
    }
    
    func testPresenterShowsAlertForStartingTripWhenExistingTrip() {
        locationManager.isUpdatingLocation = false
        presenter.visitedLocations = [.mock()]
        presenter.startButtonTapped()
        wait(for: [view.showAlertExpectation], timeout: 0)
        XCTAssertEqual(view.showAlertConfig?.title, "Current Trip")
        XCTAssertEqual(view.showAlertConfig?.buttons.count, 2)
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
    var isUpdatingLocation: Bool = false
    var authorizationStatus: CLAuthorizationStatus = .notDetermined
    
    let requestAuthorizationExpectation = XCTestExpectation()
    func requestWhenInUseAuthorization(completion: @escaping RequestAuthorizationCompletion) {
        requestAuthorizationExpectation.fulfill()
    }
    
    let startUpdatingLocationExpectation = XCTestExpectation()
    func startUpdatingLocation(callback: @escaping LocationUpdatedCallback) {
        startUpdatingLocationExpectation.fulfill()
    }
    
    let stopUpdatingLocationExpectation = XCTestExpectation()
    func stopUpdatingLocation() {
        stopUpdatingLocationExpectation.fulfill()
    }
    
    let resetExpectation = XCTestExpectation()
    func reset() {
        resetExpectation.fulfill()
    }
}

extension VisitedLocation {
    static func mock() -> VisitedLocation {
        return .init(location: .init(), image: .init(imageId: "imageId", image: UIImage()))
    }
}
