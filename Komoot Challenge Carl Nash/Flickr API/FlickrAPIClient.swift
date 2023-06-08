//
//  FlickrAPIClient.swift
//  Komoot Challenge Carl Nash
//
//  Created by Carl on 22/04/2021.
//

import Foundation
import UIKit

protocol PhotosAPIClient {
    /// Method for for searching for photos from the Flickr Photo Search API based on GPS coordinates.
    /// This response contains information such as the `imageId`, `server` and `secret` that are used for downloading the image.
    ///
    /// - SeeAlso: https://www.flickr.com/services/api/flickr.photos.search.html
    func searchForPhotosForLocation(_ location: Location) async throws -> APIPhotosSearchResponse

    /// Method for downloading an image from Flickr based on the  values from the photos search response. `APIPhotosSearchResponse`.
    ///
    /// - SeeAlso: https://www.flickr.com/services/api/misc.urls.html    
    func downloadImage(for photo: APIPhotosSearchResponse.Photo, size: FlickrPhotoSize) async throws -> UIImage
}

struct FlickrAPIClient: PhotosAPIClient {
    
    enum ResponseError: Error {
        case invalidImageData
    }
    
    let urlSession: URLSession = .init(configuration: .default)
    
    func searchForPhotosForLocation(_ location: Location) async throws -> APIPhotosSearchResponse {
        let queryItems: [URLQueryItem] = [
            .init(name: "method", value: "flickr.photos.search"),
            // TODO: Move API key out of code
            .init(name: "api_key", value: "a0881b1f9a81ce55eaa3257454f4a486"),
            .init(name: "lat", value: String(location.latitude)),
            .init(name: "lon", value: String(location.longitude)),
            .init(name: "radius", value: "10"),
            .init(name: "safe_search", value: "1"), // safe
            .init(name: "content_type", value: "1"), // photos only
            .init(name: "privacy_filter", value: "1"), // public photos
            .init(name: "tags", value: "landscape, komoot"), // Try and get more relevant photos
            // TODO: Commented out as it seems to be returning no images now
//            .init(name: "geo_context", value: "2"), // outdoors
            .init(name: "format", value: "json"),
            .init(name: "nojsoncallback", value: "1")
        ]
        var urlComponents = URLComponents()
        urlComponents.scheme = "https"
        urlComponents.host = "www.flickr.com"
        urlComponents.path = "/services/rest"
        urlComponents.queryItems = queryItems
        
        guard let url = urlComponents.url else { fatalError() }
        
        let (data, _) = try await urlSession.data(from: url)
        
        #if DEBUG
        print(String(describing: String(data: data, encoding: .utf8)))
        #endif
        
        let decoded = try JSONDecoder().decode(APIPhotosSearchResponse.self, from: data)
        return decoded
    }
    
    func downloadImage(for photo: APIPhotosSearchResponse.Photo, size: FlickrPhotoSize) async throws -> UIImage {
        var urlComponents = URLComponents()
        urlComponents.scheme = "https"
        urlComponents.host = "live.staticflickr.com"
        urlComponents.path = "/\(photo.server)/\(photo.id)_\(photo.secret)\(size.rawValue).jpg"
        guard let url = urlComponents.url else {
            fatalError()
        }
        let (data, _) = try await urlSession.data(from: url)
        if let image = UIImage(data: data) {
            return image
        } else {
            throw ResponseError.invalidImageData
        }
    }
    
}
