# Komoot Challenge - Carl Nash

## Overview

This app is my code challenge for the komoot Senior iOS Developer role.

The spec located [here](https://docs.google.com/presentation/d/1UDns1lDy3ToIYLClI53x81aJSiHXmXbE9jDDiWDRTGE/edit#slide=id.g3d4d66cb27_0_0) is to make an app that tracks a user's walk with images.

## Implementation

The app has a single screen that provides a 'Start' button on the nav bar right side.

### Location

Tapping this button will check if the user has allowed location permission to the app, if not it will prompt the user to allow location permission (while the app is in use).

If the user denies permission then it will not begin tracking their walk.

If the user allows permission then it will begin tracking their walk.

The location tracking uses the iOS `CLLocationManager` library, and is configured to only provide location updates every 100 meters, as this is the accuracy needed to meet requirements.

### Flickr Photo Search

API Docs: https://www.flickr.com/services/api/flickr.photos.search.html

When a new location is provided by the location manager then the app will use this location (latitude and longitude coordinates) to call the Flickr Photo Search API to search for images taken within a specified radius of this location.

Other search filters used for this API call are things like:

* `safe_search` = safe
* `content_type` = photos
* `privacy_filter` = public
* `tags` = landscape, komoot (to try and get more relevant photos)
* `geo_context` = outdoors

### Flickr Photo Download

API Docs: https://www.flickr.com/services/api/misc.urls.html

When a successful search reponse is received then the app will download the photo for the first result (as long as it hasn't been downloaded already).

If the user returns to the same location on their walk then the app will download the next photo in the search response so that it doesn't end up with duplicate photos.

When the download is complete it's added to a custom `VisitedLocation` model that contains the location and the image, and this model is appended to an array of visited locations.

The collection view in the main view displays these images with the most recent image at the top. This list is reloaded whenever a new image is downloaded.

The app is configured to allow background location updates so that the user can lock the phone and continue with their walk and they will see this list whe the app is next opened.

## Possible Improvements

Here are a list of improvements that could be made to improve the app:

* Cache the visited locations and images locally
* Display information about the photo in a new view when the photo is tapped
* Display information about the route, e.g. distance, map, etc.
* Add more unit tests for the location and API client code (at the moment it's mainly the Presenter that is tested
