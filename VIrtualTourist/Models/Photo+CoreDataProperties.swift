//
//  Photo+CoreDataProperties.swift
//  VIrtualTourist
//
//  Created by Pete Barnes on 10/6/17.
//  Copyright © 2017 Pete Barnes. All rights reserved.
//
//

import Foundation
import CoreData


extension Photo {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Photo> {
        return NSFetchRequest<Photo>(entityName: "Photo")
    }

    @NSManaged public var creationDate: Date?
    @NSManaged public var imageData: NSData?
    @NSManaged public var url: URL?
    @NSManaged public var photoID: String?
    @NSManaged public var pin: Pin?

}
