//
//  VisitedLocation.swift
//  Komoot Challenge Carl Nash
//
//  Created by Carl on 22/04/2021.
//

import Foundation
import CoreLocation
import UIKit

/// Model used to represent the locations the user has visited along with the image for that location
struct VisitedLocation {
    let location: CLLocation
    let photo: APIPhotosSearchResponse.Photo
    let image: UIImage
}
