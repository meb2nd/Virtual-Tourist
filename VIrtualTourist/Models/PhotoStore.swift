//
//  PhotoStore.swift
//  VIrtualTourist
//
//  Created by Pete Barnes on 10/5/17.
//  Copyright © 2017 Pete Barnes. All rights reserved.
//
// Code for this class based on information in: iOS Programming: The Big Nerd Ranch Guide (Big Nerd Ranch Guides) 6th Edition, Kindle Edition

import UIKit

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
    
    func fetchPhotos(completion: @escaping (PhotosResult) -> Void) {
        
    }
    
    func fetchImage(for photo: Photo, completionForFetchImage: ((ImageResult) -> Void)?) {
        
        // If we already have the image just return it
        if let imageData = photo.imageData {
            let result = processImageRequest(data: imageData as Data, error: nil)
            if let completion = completionForFetchImage {completion(result)}
            return
        }
        
        // Otherwise if we have a valid URL try to download it
        guard let photoURL = photo.url else {
            if let completion = completionForFetchImage {completion(.failure(PhotoError.invalidPhotoURL))}
            return
        }
        let request = URLRequest(url: photoURL)
        let task = session.dataTask(with: request) {
            (data, response, error) -> Void in
            
            photo.imageData = data as NSData?
            let result = self.processImageRequest(data: data, error: error)
            performUIUpdatesOnMain {
                if let completion = completionForFetchImage {completion(result)}
            }
        }
        task.resume()
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
