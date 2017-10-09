//
//  TravelLocationsMapViewController.swift
//  VIrtualTourist
//
//  Created by Pete Barnes on 10/3/17.
//  Copyright © 2017 Pete Barnes. All rights reserved.
//

import UIKit
import MapKit
import CoreData

class TravelLocationsMapViewController: UIViewController {

    // MARK: Properties
    
    var pin: Pin?
    
    var fetchedResultsController : NSFetchedResultsController<NSFetchRequestResult>? {
        didSet {
            // Whenever the frc changes, we execute the search and
            // reload the collection
            fetchedResultsController?.delegate = self
            executeSearch()
            travelLocationsMapView.reloadData(from: fetchedResultsController)
        }
    }
    
    @IBOutlet var longPressGestureRecognizer: UILongPressGestureRecognizer!
    @IBOutlet weak var travelLocationsMapView: MKMapView!
    @IBOutlet var panGestureRecognizer: UIPanGestureRecognizer!
    
    // MARK: - Life cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        // Get the stack
        let delegate = UIApplication.shared.delegate as! AppDelegate
        let stack = delegate.stack
        
        // Create a fetchrequest
        let fr = NSFetchRequest<NSFetchRequestResult>(entityName: "Pin")
        fr.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
        
        // Create the FetchedResultsController
        fetchedResultsController = NSFetchedResultsController(fetchRequest: fr, managedObjectContext: stack.context, sectionNameKeyPath: nil, cacheName: nil)
        
        travelLocationsMapView.delegate = self
        
        // Restore the mapview
        let defaults = UserDefaults.standard
        if let locationData = defaults.dictionary(forKey: "location") {
            
            let center = CLLocationCoordinate2DMake(locationData["lat"] as! CLLocationDegrees, locationData["long"] as! CLLocationDegrees)
            let span = MKCoordinateSpanMake(locationData["latDelta"] as! CLLocationDegrees, locationData["longDelta"] as! CLLocationDegrees)
            let region = MKCoordinateRegion(center: center, span: span)
            
            travelLocationsMapView.setRegion(travelLocationsMapView.regionThatFits(region), animated: true)

        }
        
        
    }
    
    // Code below is from information at the following site: https://stackoverflow.com/questions/39214923/using-nsuserdefaults-to-save-region-of-an-mkmapview
    
    override func viewWillDisappear(_ animated: Bool) {
        let defaults = UserDefaults.standard
        let locationData = ["lat": travelLocationsMapView.centerCoordinate.latitude,
            "long": travelLocationsMapView.centerCoordinate.longitude,
            "latDelta": travelLocationsMapView.region.span.latitudeDelta,
            "longDelta": travelLocationsMapView.region.span.longitudeDelta]
        defaults.set(locationData, forKey: "location")
    }

    // Code for this method based on infomration found at:  https://stackoverflow.com/questions/30858360/adding-a-pin-annotation-to-a-map-view-on-a-long-press-in-swift
    // https://stackoverflow.com/questions/3319591/uilongpressgesturerecognizer-gets-called-twice-when-pressing-down
    @IBAction func addTravelLocationPin(_ sender: UILongPressGestureRecognizer) {
        
        if sender.state == .began {
            let touchPoint = sender.location(in: travelLocationsMapView)
            let newCoordinates = travelLocationsMapView.convert(touchPoint, toCoordinateFrom: travelLocationsMapView)
            let latitude = Float(newCoordinates.latitude)
            let longitude = Float(newCoordinates.longitude)
            pin = Pin(latitude: latitude, longitude: longitude, context: fetchedResultsController!.managedObjectContext)
            
            // Set isDraggable so pin is dropped onto screen and allowed to drag.
            pin!.isDraggable = true
            print("We've created a pin!: \(pin as Optional)")
        } else if sender.state == .changed, pin != nil {
            let touchPoint = sender.location(in: travelLocationsMapView)
            let newCoordinates = travelLocationsMapView.convert(touchPoint, toCoordinateFrom: travelLocationsMapView)
            let latitude = Float(newCoordinates.latitude)
            let longitude = Float(newCoordinates.longitude)
            
            pin?.latitude = latitude
            pin?.longitude = longitude
            print("Pin has moved!")
        } else {
            pin = nil
            print("Pin has been placed!")
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
        
        if segue.identifier! == "showPhotos" {
            
            if let photoAlbumVC = segue.destination as? PhotoAlbumViewController,
                let pin = pin {
                
                // Create Fetch Request
                let fr = NSFetchRequest<NSFetchRequestResult>(entityName: "Photo")
                fr.sortDescriptors = [NSSortDescriptor(key: "pin", ascending: true),
                                      NSSortDescriptor(key: "creationDate", ascending: false)]
                
                let pred = NSPredicate(format: "pin = %@", argumentArray: [pin])
                
                fr.predicate = pred
                
                // Create FetchedResultsController
                let fc = NSFetchedResultsController(fetchRequest: fr, managedObjectContext:fetchedResultsController!.managedObjectContext, sectionNameKeyPath: nil, cacheName: nil)
                
                // Inject it into the photoAlbumVC
                photoAlbumVC.fetchedResultsController = fc
                photoAlbumVC.pin = pin
            }
        }
    }
}

// MARK: - TravelLocationsMapViewController (Fetches)

extension TravelLocationsMapViewController {
    
    func executeSearch() {
        if let fc = fetchedResultsController {
            do {
                try fc.performFetch()
            } catch let e as NSError {
                print("Error while trying to perform a search: \n\(e)\n\(fetchedResultsController as Optional)")
            }
        }
    }
}

// MARK: - PhotoAlbumViewController: NSFetchedResultsControllerDelegate
// Code for this extension based on information found at: http://bjmiller.me/post/58431532849/nsfetchedresultscontroller-with-mkmapview

extension TravelLocationsMapViewController: NSFetchedResultsControllerDelegate {

    func controllerWillChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        UIApplication.shared.isNetworkActivityIndicatorVisible = true
        longPressGestureRecognizer.isEnabled = false
    }
    
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange anObject: Any, at indexPath: IndexPath?, for type: NSFetchedResultsChangeType, newIndexPath: IndexPath?) {
        
        switch(type) {
        case .insert:
            fetchedResultsChangeInsert(anObject as! Pin)
        case .delete:
            fetchedResultsChangeDelete(anObject as! Pin)
        case .update:
            fetchedResultsChangeUpdate(anObject as! Pin)
        case .move:
            // do nothing
            break
        }
    }
    
    func fetchedResultsChangeInsert(_ pin: Pin) {
        travelLocationsMapView.addAnnotation(pin)
    }
    
    func fetchedResultsChangeDelete(_ pin: Pin) {
        travelLocationsMapView.removeAnnotation(pin)
    }
    
    func fetchedResultsChangeUpdate(_ pin: Pin) {
        fetchedResultsChangeDelete(pin)
        fetchedResultsChangeInsert(pin)
    }
    
    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        
        UIApplication.shared.isNetworkActivityIndicatorVisible = false
        longPressGestureRecognizer.isEnabled = true
    }
}

// MARK: - MKMapView

private extension MKMapView {
    func reloadData(from fecthedResultsController: NSFetchedResultsController<NSFetchRequestResult>?) {
        removeAnnotations(annotations)
        let count = fecthedResultsController?.fetchedObjects?.count
        addAnnotations(fecthedResultsController?.fetchedObjects as! [MKAnnotation])
    }
}


