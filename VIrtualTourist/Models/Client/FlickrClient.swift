//
//  FlickrClient.swift
//  On The Map
//
//  Created by Pete Barnes on 10/3/17.
//  Copyright © 2017 Pete Barnes. All rights reserved.
//

import CoreData

final class FlickrClient : NSObject {
    
    // MARK: - Properties
    
    // shared session
    var session = URLSession.shared
    
    // NetworkClient
    let scheme = FlickrClient.Constants.ApiScheme
    let host = FlickrClient.Constants.ApiHost
    let path = FlickrClient.Constants.ApiPath
    
    // MARK: - Initializers
    
    override init() {
        super.init()
    }
    
    // MARK: - HTTP Tasks
    
    func taskForGETMethod(_ method: String, parameters: [String: String?], completionHandlerForGET: @escaping (_ result: AnyObject?, _ error: APIError?) -> Void) -> URLSessionDataTask {
        
        /* 1. Set the common parameters */
        var modParameters = parameters
        modParameters[ParameterKeys.APIKey] = ParameterValues.APIKey
        modParameters[ParameterKeys.Format] = ParameterValues.ResponseFormat
        modParameters[ParameterKeys.NoJSONCallback] = ParameterValues.DisableJSONCallback

        
        /* 2/3. Build the URL, Configure the request */
        let request = buildTheURL(method, parameters: modParameters, headers: [:])
        
        
        /* 4. Make the request */
        return makeTheTask(request: request as URLRequest, errorDomain: "FlickrClient.taskForGETMethod", completionHandler: completionHandlerForGET)
        
    }
    
    // MARK: - Search by Latitude/Longitude
    
    func searchByLatLon(latitude: Double, longitude: Double, maxResults: Int = 100, _ completionHandlerForLatLonSearch: @escaping (_ result: [Data]?, _ error: APIError?) -> Void) {
        
        guard coordinatesAreValid (latitude: latitude, longitude: longitude) else {
            
            completionHandlerForLatLonSearch(nil, APIError.missingParametersError("Invalid value for longitude/latitude."))
            return
        }

        let parameters = [ParameterKeys.Method: ParameterValues.SearchMethod,
                          ParameterKeys.BoundingBox: bboxString(latitude: latitude, longitude: longitude),
                          ParameterKeys.SafeSearch: ParameterValues.UseSafeSearch,
                          ParameterKeys.Extras: ParameterValues.MediumURL,
                          ParameterKeys.PerPage: String(maxResults)]
        
        getPhotosDictionary(parameters){ (result, error) in
            
            guard (error == nil), let photosDictionary = result else {
                
                print("There was an error in getting the Photos Dictionary: \(String(describing: error))")
                
                completionHandlerForLatLonSearch(nil, error)
                
                return
            }
            
            /* GUARD: Is "pages" key in the photosDictionary? */
            guard let totalPages = photosDictionary[JSONResponseKeys.Pages] as? Int else {
                print("Cannot find key '\(JSONResponseKeys.Pages)' in \(photosDictionary)")
                completionHandlerForLatLonSearch(nil, APIError.jsonMappingError(converstionError: DecodeError.missingKey(JSONResponseKeys.Pages)))
                return
            }
            
            // Pick a random page!
            let pageLimit = min(totalPages, 40)
            let randomPage = Int(arc4random_uniform(UInt32(pageLimit))) + 1
            self.getImagesBySearch(parameters, withPageNumber: randomPage, completionHandlerForLatLonSearch)
            
        }
    }
    
    private func bboxString(latitude: Double, longitude: Double) -> String {
        // ensure bbox is bounded by minimum and maximums
        let latitude = Double(latitude)
        let longitude = Double(longitude)
        if coordinatesAreValid (latitude: latitude, longitude: longitude) {
            let minimumLon = max(longitude - Constants.SearchBBoxHalfWidth, Constants.SearchLonRange.0)
            let minimumLat = max(latitude - Constants.SearchBBoxHalfHeight, Constants.SearchLatRange.0)
            let maximumLon = min(longitude + Constants.SearchBBoxHalfWidth, Constants.SearchLonRange.1)
            let maximumLat = min(latitude + Constants.SearchBBoxHalfHeight, Constants.SearchLatRange.1)
            return "\(minimumLon),\(minimumLat),\(maximumLon),\(maximumLat)"
        } else {
            return "0,0,0,0"
        }
    }
    
    func coordinatesAreValid (latitude: Double, longitude: Double) -> Bool {
        
        return isValueInRange(latitude, min: Constants.SearchLatRange.0, max: Constants.SearchLatRange.1) &&
        isValueInRange(longitude, min: Constants.SearchLonRange.0, max: Constants.SearchLonRange.1)
    }
    
    private func isValueInRange(_ value: Double, min: Double, max: Double) -> Bool {
        return !(value < min || value > max)
    }
    
    // MARK: - Get Images
    
    private func getImagesBySearch(_ parameters: [String:String?], withPageNumber: Int, _ completionHandlerForGetImagesBySearch: @escaping (_ result: [Data]?, _ error: APIError?) -> Void) {
        
        // add the page to the method's parameters
        var parametersWithPageNumber = parameters
        parametersWithPageNumber[ParameterKeys.Page] = String(withPageNumber)
        
        getPhotosArray(parametersWithPageNumber){ (result, error) in
            
            guard (error == nil), let photosArray = result else {
                
                print("There was an error in getting the Photos Dictionary: \(String(describing: error))")
                completionHandlerForGetImagesBySearch(nil, error)
                return
            }
            
            if photosArray.count == 0 {
                print("No Photos Found. Search Again.")
                completionHandlerForGetImagesBySearch(nil, APIError.jsonMappingError(converstionError: DecodeError.custom("No photos found. Search Again")))
                return
            } else {
                
                var photos: [Data] = []
                
                self.loadImages(photosArray, &photos)
                
                completionHandlerForGetImagesBySearch(photos, nil)
            }
        }
    }
    
    fileprivate func loadImages(_ photosArray: [[String : AnyObject]], _ photos: inout [Data]) {
        for photoIndex in 0 ... photosArray.count-1  {
            let photoDictionary = photosArray[photoIndex] as [String: AnyObject]
            
            /* GUARD: Does our photo have a key for 'url_m'? */
            guard let imageUrlString = photoDictionary[JSONResponseKeys.MediumURL] as? String else {
                print("Cannot find key '\(JSONResponseKeys.MediumURL)' in \(photoDictionary)")
                continue
            }
            
            // if an image exists at the url add it to the array
            let imageURL = URL(string: imageUrlString)
            if let imageData = try? Data(contentsOf: imageURL!) {
                photos.append(imageData)
            } else {
                print("Image does not exist at \(imageURL as Optional)")
            }
        }
    }
    
    // MARK: - JSON Photos Retrieval Functions
    
    private func getPhotosArray(_ parameters: [String: String?], _ CompletionHandlerForGetPhotosArray: @escaping (_ result: [[String: AnyObject]]?, _ error: APIError?) -> Void) {
        
        getPhotosDictionary(parameters){ (result, error) in
            
            guard (error == nil), let photosDictionary = result else {
                
                print("There was an error in getting the Photos Dictionary: \(String(describing: error))")
                
                CompletionHandlerForGetPhotosArray(nil, error)
                
                return
            }
            
            /* GUARD: Is "photo" key in the photosDictionary? */
            guard let photosArray = photosDictionary[JSONResponseKeys.Photo] as? [[String: AnyObject]] else {
                print("Cannot find key '\(JSONResponseKeys.Photo)' in \(photosDictionary)")
                CompletionHandlerForGetPhotosArray(nil, APIError.jsonMappingError(converstionError: DecodeError.missingKey(JSONResponseKeys.Photo)))
                return
            }
            
            CompletionHandlerForGetPhotosArray(photosArray, nil)
        }
    }
    
    private func getPhotosDictionary(_ parameters: [String:String?], _ completionHandlerForGetPhotosDictionary: @escaping (_ result: [String:AnyObject]?, _ error: APIError?) -> Void) {
        
        // add the page to the method's parameters
        
        _ = taskForGETMethod("", parameters: parameters){ (result, error) in
            
            guard (error == nil) else {
                
                print("There was an error in the request: \(String(describing: error))")
                completionHandlerForGetPhotosDictionary(nil, error)
                return
            }
            
            /* GUARD: Did Flickr return an error (stat != ok)? */
            guard let stat = result?[JSONResponseKeys.Status] as? String, stat == ResponseValues.OKStatus else {
                
                print("Flickr API returned an error. See error code and message in \(String(describing: result))")
                completionHandlerForGetPhotosDictionary(nil, APIError.jsonMappingError(converstionError: DecodeError.custom("Flickr API returned an error.")))
                return
            }
            
            /* GUARD: Is "photos" key in our result? */
            guard let photosDictionary = result?[JSONResponseKeys.Photos] as? [String:AnyObject] else {
                
                print("Cannot find key '\(JSONResponseKeys.Photos)' in \(String(describing: result))")
                completionHandlerForGetPhotosDictionary(nil, APIError.jsonMappingError(converstionError: DecodeError.missingKey(JSONResponseKeys.Photos)))
                return
            }
            
            completionHandlerForGetPhotosDictionary(photosDictionary, nil)
        }
    }
    
    // MARK: - Shared Instance
    
    class func sharedInstance() -> FlickrClient {
        struct Singleton {
            static var sharedInstance = FlickrClient()
        }
        return Singleton.sharedInstance
    }
}

// MARK: - FlickrClient: NetworkClient

extension FlickrClient: NetworkClient {
    
    func preprocessData (data: Data) -> Data {
        return data
    }
}

// MARK: - Core data functions

extension FlickrClient {
    
    
    // MARK: - Search by Latitude/Longitude from Pin
    
    func searchForPhotos(near pin: Pin, context: NSManagedObjectContext, maxResults: Int = 100, _ completionHandlerForFetchPhotos: @escaping (_ result: PhotosResult) -> Void) {
        
        let latitude = Double(pin.latitude)
        let longitude = Double(pin.longitude)
        
        guard coordinatesAreValid (latitude: latitude, longitude: longitude) else {
            completionHandlerForFetchPhotos(.failure(APIError.missingParametersError("Invalid value for longitude/latitude.")))
            return
        }
        
        let parameters = [ParameterKeys.Method: ParameterValues.SearchMethod,
                          ParameterKeys.BoundingBox: bboxString(latitude: latitude, longitude: longitude),
                          ParameterKeys.SafeSearch: ParameterValues.UseSafeSearch,
                          ParameterKeys.Extras: ParameterValues.MediumURL,
                          ParameterKeys.PerPage: String(maxResults)]
        
        getPhotosDictionary(parameters){ (result, error) in
            
            guard (error == nil), let photosDictionary = result else {
                
                print("There was an error in getting the Photos Dictionary: \(String(describing: error))")
                
                completionHandlerForFetchPhotos(.failure(error!))
                
                return
            }
            
            /* GUARD: Is "pages" key in the photosDictionary? */
            guard let totalPages = photosDictionary[JSONResponseKeys.Pages] as? Int else {
                print("Cannot find key '\(JSONResponseKeys.Pages)' in \(photosDictionary)")
                completionHandlerForFetchPhotos(.failure(APIError.jsonMappingError(converstionError: DecodeError.missingKey(JSONResponseKeys.Pages))))
                return
            }
            
            // Pick a random page!
            let pageLimit = min(totalPages, 40)
            let randomPage = Int(arc4random_uniform(UInt32(pageLimit))) + 1
            self.getPhotosBySearch(parameters, withPageNumber: randomPage, pin: pin, context: context, completionHandlerForFetchPhotos)
            
        }
    }
    
    private func getPhotosBySearch(_ parameters: [String:String?], withPageNumber: Int, pin: Pin, context: NSManagedObjectContext, _ completionHandlerForGetPhotosBySearch: @escaping (_ result: PhotosResult) -> Void) {
        
        // add the page to the method's parameters
        var parametersWithPageNumber = parameters
        parametersWithPageNumber[ParameterKeys.Page] = String(withPageNumber)
        
        getPhotosArray(parametersWithPageNumber){ (result, error) in
            
            guard (error == nil), let photosArray = result else {
                
                print("There was an error in getting the Photos Dictionary: \(String(describing: error))")
                completionHandlerForGetPhotosBySearch(.failure(error!))
                return
            }
            
            if photosArray.count == 0 {
                print("No Photos Found. Search Again.")
                completionHandlerForGetPhotosBySearch(.failure(APIError.jsonMappingError(converstionError: DecodeError.custom("No photos found. Search Again"))))
                return
            } else {
                
                let result = self.photos(fromJSONPhotosArray: photosArray, for: pin, into: context)
                
                completionHandlerForGetPhotosBySearch(result)
            }
        }
    }
    
    private func photos(fromJSONPhotosArray photosArray: [[String:Any]], for pin: Pin, into context: NSManagedObjectContext) -> PhotosResult {
        
        var finalPhotos = [Photo]()
        
        for photoJSON in photosArray {
            if let photo = photo(fromJSON: photoJSON, into: context, for: pin) {
                finalPhotos.append(photo)
            }
        }
        
        if finalPhotos.isEmpty && !photosArray.isEmpty {
            // We weren't able to parse any of the photos
            // Maybe the JSON format for photos has changed
            return .failure(APIError.jsonMappingError(converstionError: .custom("Could not parse any of the photos.")))
        }
        
        return .success(finalPhotos)
    }
    
    private func photo(fromJSON json: [String : Any],
                              into context: NSManagedObjectContext, for pin: Pin) -> Photo? {
        guard
            let photoID = json[JSONResponseKeys.PhotoID] as? String,
            let photoURLString = json[JSONResponseKeys.MediumURL] as? String,
            let url = URL(string: photoURLString) else {
                // Don't have enough information to construct a Photo
                return nil }
        let fetchRequest: NSFetchRequest<Photo> = Photo.fetchRequest()
        let predicate = NSPredicate(format: "\(#keyPath(Photo.photoID)) == \(photoID) AND pin = %@", argumentArray: [pin])
        fetchRequest.predicate = predicate
        var fetchedPhotos: [Photo]?
        context.performAndWait {
            fetchedPhotos = try? fetchRequest.execute()
        }
        if let existingPhoto = fetchedPhotos?.first {
            return existingPhoto
        }
        var photo: Photo!
        context.performAndWait {
            photo = Photo(context: context)
            photo.photoID = photoID
            photo.url = url
            photo.pin = pin
        }
        return photo
    }
}
