//
//  APIPhotosSearchResponse.swift
//  Komoot Challenge Carl Nash
//
//  Created by Carl on 22/04/2021.
//

import Foundation

// Model that matched the flickr photos seatch response JSON
struct APIPhotosSearchResponse: Decodable {
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
