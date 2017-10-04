//
//  FlickrClient.swift
//  On The Map
//
//  Created by Pete Barnes on 10/3/17.
//  Copyright © 2017 Pete Barnes. All rights reserved.
//

import Foundation

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

        
        /* 2/3. Build the URL, Configure the request */
        let request = buildTheURL(method, parameters: modParameters, headers: [:])
        
        
        /* 4. Make the request */
        return makeTheTask(request: request as URLRequest, errorDomain: "FlickrClient.taskForGETMethod", completionHandler: completionHandlerForGET)
        
    }
    
    // MARK: - Search by Latitude/Longitude
    
    func searchByLatLon(latitude: Double, longitude: Double, _ completionHandlerForLatLonSearch: @escaping (_ result: [Data]?, _ error: APIError?) -> Void) {
        
        guard coordinatesAreValid (latitude: latitude, longitude: longitude) else {
            
            completionHandlerForLatLonSearch(nil, APIError.missingParametersError("Invalid value for longitude/latitude."))
            return
        }

        let parameters = [ParameterKeys.Method: ParameterValues.SearchMethod,
                          ParameterKeys.BoundingBox: bboxString(latitude: latitude, longitude: longitude),
                          ParameterKeys.SafeSearch: ParameterValues.UseSafeSearch,
                          ParameterKeys.Extras: ParameterValues.MediumURL,
                          ParameterKeys.Format: ParameterValues.ResponseFormat,
                          ParameterKeys.NoJSONCallback: ParameterValues.DisableJSONCallback]
        
        _ = taskForGETMethod("", parameters: parameters){ (result, error) in
            
            guard (error == nil) else {
                
                print("There was an error in the request: \(String(describing: error))")
                
                completionHandlerForLatLonSearch(nil, error)
                
                return
            }
            
            /* GUARD: Did Flickr return an error (stat != ok)? */
            guard let stat = result?[JSONResponseKeys.Status] as? String, stat == ResponseValues.OKStatus else {
                
                print("Flickr API returned an error. See error code and message in \(String(describing: result))")
                completionHandlerForLatLonSearch(nil, APIError.jsonMappingError(converstionError: DecodeError.custom("Flickr API returned an error.")))
                return
            }
            
            /* GUARD: Is "photos" key in our result? */
            guard let photosDictionary = result?[JSONResponseKeys.Photos] as? [String:AnyObject] else {
                
                print("Cannot find key '\(JSONResponseKeys.Photos)' in \(String(describing: result))")
                completionHandlerForLatLonSearch(nil, APIError.jsonMappingError(converstionError: DecodeError.missingKey(JSONResponseKeys.Photos)))
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
        
        
        _ = taskForGETMethod("", parameters: parametersWithPageNumber){ (result, error) in
            
            guard (error == nil) else {
                
                print("There was an error in the request: \(String(describing: error))")
                
                completionHandlerForGetImagesBySearch(nil, error)
                
                return
            }
            
            /* GUARD: Did Flickr return an error (stat != ok)? */
            guard let stat = result?[JSONResponseKeys.Status] as? String, stat == ResponseValues.OKStatus else {
                
                print("Flickr API returned an error. See error code and message in \(String(describing: result))")
                completionHandlerForGetImagesBySearch(nil, APIError.jsonMappingError(converstionError: DecodeError.custom("Flickr API returned an error.")))
                return
            }
            
            /* GUARD: Is "photos" key in our result? */
            guard let photosDictionary = result?[JSONResponseKeys.Photos] as? [String:AnyObject] else {
                
                print("Cannot find key '\(JSONResponseKeys.Photos)' in \(String(describing: result))")
                completionHandlerForGetImagesBySearch(nil, APIError.jsonMappingError(converstionError: DecodeError.missingKey(JSONResponseKeys.Photos)))
                return
            }
            
            /* GUARD: Is "photo" key in the photosDictionary? */
            guard let photosArray = photosDictionary[JSONResponseKeys.Photo] as? [[String: AnyObject]] else {
                print("Cannot find key '\(JSONResponseKeys.Photo)' in \(photosDictionary)")
                completionHandlerForGetImagesBySearch(nil, APIError.jsonMappingError(converstionError: DecodeError.missingKey(JSONResponseKeys.Photo)))
                return
            }
            
            if photosArray.count == 0 {
                print("No Photos Found. Search Again.")
                completionHandlerForGetImagesBySearch(nil, APIError.jsonMappingError(converstionError: DecodeError.custom("No photos found. Search Again")))
                return
            } else {
                
                var photos: [Data] = []
                
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
                        
                        // self.photoImageView.image = UIImage(data: imageData)
                        photos.append(imageData)
                    } else {
                        print("Image does not exist at \(imageURL as Optional)")
                    }
                }
                
                completionHandlerForGetImagesBySearch(photos, nil)
            }
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

/*
 
 Reusable Guards from: https://swiftexample.info/code/reusable-views-ios/
 
 func foo(url: NSURL) {
 guard let (components, path) = urlGuard(url) as? (NSURLComponents, String) else {
 return
 }
 print("Components \(components) and path \(path)")
 }
 
 func urlGuard(url: NSURL) -> (NSURLComponents?, String?) {
 guard let components = NSURLComponents(URL: url, resolvingAgainstBaseURL: false), path = components.path else {
 return (nil, nil)
 }
 return (components, path)
 }
 
 */


