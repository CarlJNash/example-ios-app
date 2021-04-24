//
//  FlickrPhotoSize.swift
//  Komoot Challenge Carl Nash
//
//  Created by Carl on 24/04/2021.
//

import Foundation

/// The suffix to add to the Flickr photo URL to tell request a specific size
/// https://www.flickr.com/services/api/misc.urls.html
enum FlickrPhotoSize: String {
    case thumbnail_75 = "_s"
    case thumbnail_150 = "_q"
    case thumbnail_100 = "_t"
    case small_240 = "_m"
    case small_320 = "_n"
    case small_400 = "_w"
    case medium_500 = "" // default
    case medium_640 = "_z"
    case medium_800 = "_c"
    case large_1024 = "_b"
    case large_1600 = "_h"
    case large_2048 = "_k"
    case extraLarge_3k = "_3k"
    case extraLarge_4k = "_4k"
    case extraLarge_4k_2to1 = "_f"
    case extraLarge_5k = "_5k"
    case extraLarge_6k = "_6k"
    case original = "_o"
}
