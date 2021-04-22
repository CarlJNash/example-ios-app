//
//  APIClient.swift
//  Komoot Challenge Carl Nash
//
//  Created by Carl on 22/04/2021.
//

import Foundation
import UIKit

struct APIClient {
    
    enum ResponseError: Error {
        case invalidSearchData
        case invalidImageData
    }
    
    let urlSession: URLSession
    
    init() {
        urlSession = URLSession(configuration: .default)
    }
    
    func searchForPhotosForLocation(lat: Double, lng: Double, completion: @escaping (Result<APIPhotosSearchResponse, Error>) -> Void) {
        let urlString = "https://www.flickr.com/services/rest/?method=flickr.photos.search&api_key=a0881b1f9a81ce55eaa3257454f4a486&lat=\(String(lat))&lon=\(String(lng))&radius=5&per_page=50&content_type=1&tags=landscape,countryside&radius=10&format=json&nojsoncallback=1"
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
                let decoded = try JSONDecoder().decode(APIPhotosSearchResponse.self, from: data)
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
