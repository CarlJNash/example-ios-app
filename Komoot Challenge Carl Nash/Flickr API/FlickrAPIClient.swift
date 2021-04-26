//
//  FlickrAPIClient.swift
//  Komoot Challenge Carl Nash
//
//  Created by Carl on 22/04/2021.
//

import Foundation
import UIKit

protocol APIClient {
    func searchForPhotosForLocation(lat: Double, lon: Double, completion: @escaping (Result<APIPhotosSearchResponse, Error>) -> Void)
    func downloadPhoto(serverId: String, id: String, secret: String, photoSize: FlickrPhotoSize, completion: @escaping (Result<UIImage, Error>) -> Void)
}

struct FlickrAPIClient: APIClient {
    
    enum ResponseError: Error {
        case invalidPhotosSearchResponseData
        case invalidImageData
    }
    
    let urlSession: URLSession
    
    init() {
        urlSession = URLSession(configuration: .default)
    }
    
    /// Use this for searching for photos from the Flickr API based on GRP location
    /// - Parameters:
    ///   - lat: The GPS latitude value
    ///   - lon: The GPS longitude value
    ///   - completion: `Result` object containing a `APIPhotosSearchResponse` if successful, otherwise an `Error` on failure
    func searchForPhotosForLocation(lat: Double, lon: Double, completion: @escaping (Result<APIPhotosSearchResponse, Error>) -> Void) {
        let queryItems: [URLQueryItem] = [
            .init(name: "method", value: "flickr.photos.search"),
            .init(name: "api_key", value: "a0881b1f9a81ce55eaa3257454f4a486"),
            .init(name: "lat", value: String(lat)),
            .init(name: "lon", value: String(lon)),
            .init(name: "radius", value: "10"),
            .init(name: "format", value: "json"),
            .init(name: "nojsoncallback", value: "1")
        ]
        var urlComponents = URLComponents()
        urlComponents.scheme = "https"
        urlComponents.host = "www.flickr.com"
        urlComponents.path = "/services/rest"
        urlComponents.queryItems = queryItems
        
        urlSession.dataTask(with: urlComponents.url!) { (data, urlResponse, error) in
            if let error = error {
                completion(.failure(error))
                return
            }
            guard let data = data, data.count > 0 else {
                completion(.failure(ResponseError.invalidPhotosSearchResponseData))
                return
            }
            do {
                let decoded = try JSONDecoder().decode(APIPhotosSearchResponse.self, from: data)
                completion(.success(decoded))
            } catch {
                completion(.failure(error))
            }
        }.resume()
    }
    
    /// For downloading an image from Flickr based on the  values from the photos search response `APIPhotosSearchResponse`
    /// - Parameters:
    ///   - serverId: The Flickr server ID
    ///   - id: The ID of the photo
    ///   - secret: The secret of the photo
    ///   - photoSize: The photo size required, see `FlickrPhotoSize`
    ///   - completion: `Result` object containing a `UIImage` if successful, otherwise an `Error` on failure
    func downloadPhoto(serverId: String, id: String, secret: String, photoSize: FlickrPhotoSize, completion: @escaping (Result<UIImage, Error>) -> Void) {
        var urlComponents = URLComponents()
        urlComponents.scheme = "https"
        urlComponents.host = "live.staticflickr.com"
        urlComponents.path = "/\(serverId)/\(id)_\(secret)\(photoSize.rawValue).jpg"
        
        urlSession.dataTask(with: urlComponents.url!) { (data, urlResponse, error) in
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
