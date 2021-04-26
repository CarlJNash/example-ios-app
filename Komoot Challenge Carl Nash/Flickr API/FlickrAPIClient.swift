//
//  FlickrAPIClient.swift
//  Komoot Challenge Carl Nash
//
//  Created by Carl on 22/04/2021.
//

import Foundation
import UIKit

protocol APIClient {
    /// Method for for searching for photos from the Flickr Photo Search API based on GPS coordinates.
    /// This response contains information such as the `imageId`, `server` and `secret` that are used for downloading the image.
    ///
    /// - Parameters:
    ///   - lat: The GPS latitude value.
    ///   - lon: The GPS longitude value.
    ///   - completion: `Result` object containing a `APIPhotosSearchResponse` if successful, otherwise an `Error` on failure.
    ///
    /// - SeeAlso: https://www.flickr.com/services/api/flickr.photos.search.html
    func searchForPhotosForLocation(lat: Double, lon: Double, completion: @escaping (Result<APIPhotosSearchResponse, Error>) -> Void)
    
    /// Method for downloading an image from Flickr based on the  values from the photos search response. `APIPhotosSearchResponse`.
    ///
    /// - Parameters:
    ///   - serverId: The Flickr server ID
    ///   - id: The ID of the photo
    ///   - secret: The secret of the photo
    ///   - photoSize: The photo size required, see `FlickrPhotoSize`
    ///   - completion: `Result` object containing a `UIImage` if successful, otherwise an `Error` on failure
    ///
    /// - SeeAlso: https://www.flickr.com/services/api/misc.urls.html
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
    
    func searchForPhotosForLocation(lat: Double, lon: Double, completion: @escaping (Result<APIPhotosSearchResponse, Error>) -> Void) {
        let queryItems: [URLQueryItem] = [
            .init(name: "method", value: "flickr.photos.search"),
            .init(name: "api_key", value: "a0881b1f9a81ce55eaa3257454f4a486"),
            .init(name: "lat", value: String(lat)),
            .init(name: "lon", value: String(lon)),
            .init(name: "radius", value: "10"),
            .init(name: "safe_search", value: "1"), // safe
            .init(name: "content_type", value: "1"), // photos only
            .init(name: "privacy_filter", value: "1"), // public photos
            .init(name: "tags", value: "landscape, komoot"), // Try and get more relevant photos
            .init(name: "geo_context", value: "2"), // outdoors
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
