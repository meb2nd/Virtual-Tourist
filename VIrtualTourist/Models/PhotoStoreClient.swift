//
//  PhotoStoreClient.swift
//  VIrtualTourist
//
//  Created by Pete Barnes on 10/7/17.
//  Copyright © 2017 Pete Barnes. All rights reserved.
//

import Foundation
import UIKit
import CoreData

protocol PhotoStoreClient {
    var store: PhotoStore! { get set }
}

// MARK: - PhotoStoreClient

extension PhotoStoreClient {
    func injectViewController (_ viewController: UIViewController, withPhotoStore photoStore: PhotoStore) {
        
        // Following code is based upon information found at: http://cleanswifter.com/dependency-injection-with-storyboards/
        if let tabVC = viewController as? UITabBarController {
            for controller in tabVC.viewControllers ?? [] {
                injectViewController(controller, withPhotoStore: photoStore)
            }
        } else if let navVC = viewController as? UINavigationController{
            for controller in navVC.viewControllers {
                injectViewController(controller, withPhotoStore: photoStore)
            }
        } else if var firstViewController = viewController as? PhotoStoreClient {
            firstViewController.store = photoStore
        }
    }
    
    func createFetchRequest(for pin: Pin) -> NSFetchRequest<NSFetchRequestResult> {
        let fr = NSFetchRequest<NSFetchRequestResult>(entityName: "Photo")
        fr.sortDescriptors = [NSSortDescriptor(key: "pin", ascending: true),
                              NSSortDescriptor(key: "creationDate", ascending: false)]
        
        let pred = NSPredicate(format: "pin = %@", argumentArray: [pin])
        
        fr.predicate = pred
        
        return fr
    }
}

