//
//  Pin+CoreDataClass.swift
//  VIrtualTourist
//
//  Created by Pete Barnes on 10/4/17.
//  Copyright © 2017 Pete Barnes. All rights reserved.
//
//

import Foundation
import CoreData
import MapKit

@objc(Pin)
public class Pin: NSManagedObject {

    var isDraggable = false
    
    // MARK: Initializer
    
    convenience init(latitude: Float, longitude: Float, context: NSManagedObjectContext) {
        
        // An EntityDescription is an object that has access to all
        // the information you provided in the Entity part of the model
        // you need it to create an instance of this class.
        if let ent = NSEntityDescription.entity(forEntityName: "Pin", in: context) {
            self.init(entity: ent, insertInto: context)
            self.latitude = latitude
            self.longitude = longitude
            self.creationDate = Date()
        } else {
            fatalError("Unable to find Entity name!")
        }
    }
}
extension Pin: MKAnnotation {
    
    public var coordinate: CLLocationCoordinate2D {
        let coord = CLLocationCoordinate2D(latitude: Double(latitude), longitude: Double(longitude))
        return coord
    }
}


