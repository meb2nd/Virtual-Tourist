//
//  PhotoStore.swift
//  VIrtualTourist
//
//  Created by Pete Barnes on 10/5/17.
//  Copyright © 2017 Pete Barnes. All rights reserved.
//
// Code for this class based on information in: iOS Programming: The Big Nerd Ranch Guide (Big Nerd Ranch Guides) 6th Edition, Kindle Edition

import UIKit
import CoreData

enum ImageResult {
    case success(UIImage)
    case downloading
    case failure(Error)
}

enum PhotoError: Error {
    case imageCreationError
    case invalidPhotoURL
}
enum PhotosResult {
    case success([Photo])
    case failure(Error)
}

class PhotoStore {
    
    private let session: URLSession = {
        let config = URLSessionConfiguration.default
        return URLSession(configuration: config)
    }()
    
    func fetchPhotos(for pin: Pin, into context: NSManagedObjectContext, completionForFetchPhotos: @escaping (PhotosResult) -> Void) {
        
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        let stack = appDelegate.stack
        
        stack.performBackgroundBatchOperation() { (workerContext) in
            
            let backgroundPin = workerContext.object(with: pin.objectID) as! Pin
            FlickrClient.sharedInstance().searchForPhotos(near: backgroundPin, context: workerContext, maxResults: 21) { (photosResult) in
                
                workerContext.perform {
                    
                    do {
                        if workerContext.hasChanges {
                            try workerContext.save()
                        }
                        
                        switch photosResult {
                        case let .success(photos):
                            let photoIDs = photos.map { return $0.objectID }
                            let mainContextPhotos =
                                photoIDs.map { return context.object(with: $0) } as! [Photo]
                            completionForFetchPhotos(.success(mainContextPhotos))
                        case .failure:
                            completionForFetchPhotos(photosResult)
                        }
                        
                    } catch {
                        print("Error saving to worker context: \(error).")
                        completionForFetchPhotos(.failure(error))
                        return
                    }
                }
            }
        }
    }
    
    func fetchImage(for photo: Photo, context: NSManagedObjectContext) -> ImageResult {
        
        // If we already have the image just return it
        if let imageData = photo.imageData {
            let result = processImageRequest(data: imageData as Data, error: nil)
            return result
        }
        
        // Otherwise if we have a valid URL try to download it
        guard let photoURL = photo.url else {
            return .failure(PhotoError.invalidPhotoURL)
        }

        if let imageData = try? Data(contentsOf: photoURL) {
            context.perform {
                photo.imageData = imageData as NSData
            }
        }
        return .downloading
    }
    
    private func processImageRequest(data: Data?, error: Error?) -> ImageResult {
        guard
            let imageData = data,
            let image = UIImage(data: imageData) else {
                // Couldn't create an image
                if data == nil {
                    return .failure(error!)
                } else {
                    return .failure(PhotoError.imageCreationError)
                }
        }
        return .success(image)
    }
}
