//
//  CLLocationCoordinate2D+extensions.swift
//  Komoot Challenge Carl Nash
//
//  Created by Carl on 22/04/2021.
//

import CoreLocation

extension CLLocationCoordinate2D {
    static func == (lhs: CLLocationCoordinate2D, rhs: CLLocationCoordinate2D) -> Bool {
        return
            (lhs.latitude == rhs.latitude) &&
            (lhs.longitude == rhs.longitude)
    }
}
