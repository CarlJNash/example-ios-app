//
//  ViewController.swift
//  Komoot Challenge Carl Nash
//
//  Created by Carl on 21/04/2021.
//

import UIKit
import CoreLocation

extension CLLocationCoordinate2D {
    static func == (lhs: CLLocationCoordinate2D, rhs: CLLocationCoordinate2D) -> Bool {
        return
            (lhs.latitude == rhs.latitude) &&
            (lhs.longitude == rhs.longitude)
    }
}
class ViewController: UIViewController {
    
    struct VisitedLocation {
        let location: CLLocation
        let image: Image
        struct Image {
            let imageId: String
            let image: UIImage
        }
    }
    
    let apiClient = APIClient()
    var visitedLocations = [VisitedLocation]()
    
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
        #warning("ignore duplicate locations")
        print(locations)
        if let location = locations.last {
            if visitedLocations.contains(where: { $0.location.coordinate == location.coordinate }) {
                return
            }
            apiClient.searchForPhotosForLocation(lat: location.coordinate.latitude, lng: location.coordinate.longitude) { result in
                switch result {
                case .failure(let error):
                    print(error)
                case .success(let response):
                    let firstPhoto = response.photos.photo.first!
                    self.apiClient.downloadPhoto(serverId: firstPhoto.server, id: firstPhoto.id, secret: firstPhoto.secret) { result in
                        switch result {
                        case .failure(let error):
                            print(error)
                        case .success(let image):
                            if self.visitedLocations.contains(where: { $0.location.coordinate == location.coordinate }) {
                                print("Location already exists in visited locations")
                                return
                            }
                            let visitedLocation = VisitedLocation(location: location, image: .init(imageId: firstPhoto.id, image: image))
                            self.visitedLocations.insert(visitedLocation, at: 0)
                            // TODO: reload image list
                        }
                    }
                }
            }
        }
    }
}

struct APIClient {
    
    enum ResponseError: Error {
        case invalidSearchData
        case invalidImageData
    }
    
    let urlSession: URLSession
    
    init() {
        urlSession = URLSession(configuration: .default)
    }
    
    func searchForPhotosForLocation(lat: Double, lng: Double, completion: @escaping (Result<APISearchPhotosResponse, Error>) -> Void) {
        let urlString = "https://www.flickr.com/services/rest/?method=flickr.photos.search&api_key=a0881b1f9a81ce55eaa3257454f4a486&lat=\(String(lat))&lon=\(String(lng))&radius=5&per_page=1&format=json&nojsoncallback=1"
        let url = URL(string: urlString)!
        urlSession.dataTask(with: url) { (data, urlResponse, error) in
            if let error = error {
                completion(.failure(error))
                return
            }
            guard let data = data, data.count > 0 else {
                completion(.failure(ResponseError.invalidSearchData))
                return
            }
            do {
                let decoded = try JSONDecoder().decode(APISearchPhotosResponse.self, from: data)
                completion(.success(decoded))
            } catch {
                completion(.failure(error))
            }
        }.resume()
    }
    
    func downloadPhoto(serverId: String, id: String, secret: String, completion: @escaping (Result<UIImage, Error>) -> Void) {
        let urlString = "https://live.staticflickr.com/\(serverId)/\(id)_\(secret)_z.jpg"
        let url = URL(string: urlString)!
        urlSession.dataTask(with: url) { (data, urlResponse, error) in
            if let error = error {
                completion(.failure(error))
                return
            }
            guard let data = data, data.count > 0 else {
                completion(.failure(ResponseError.invalidImageData))
                return
            }
            if let image = UIImage(data: data) {
                completion(.success(image))
            } else {
                completion(.failure(ResponseError.invalidImageData))
            }
        }.resume()
    }
    
}

struct APISearchPhotosResponse: Decodable {
    struct Photo: Decodable {
        let id: String
        let server: String
        let secret: String
    }
    struct Photos: Decodable {
        let photo: [Photo]
    }
    let photos: Photos
}

// Search response
/*
 {
   "photos": {
     "page": 1,
     "pages": "5214",
     "perpage": 1,
     "total": "52134",
     "photo": [
       {
         "id": "51127321893",
         "owner": "25235699@N02",
         "secret": "3654a14f1c",
         "server": "65535",
         "farm": 66,
         "title": "Spitfire Mk Vc AR501  in flight Old Warden May 2019 - 2021 edit",
         "ispublic": 1,
         "isfriend": 0,
         "isfamily": 0
       }
     ]
   },
   "stat": "ok"
 }
 */
