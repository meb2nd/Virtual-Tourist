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

class TravelLocationsMapViewController: UIViewController, PhotoStoreClient {
    
    // MARK: - Properties
    
    var store: PhotoStore!
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
    
    // MARK: Map Persistence Keys
    let mapPersistanceKey = "location"
    let latitudeKey = "lat"
    let longitudeKey = "long"
    let latDeltaKey = "latDelta"
    let longDeltaKey = "longDelta"
    
    // MARK: - Outlets
    
    @IBOutlet weak var travelLocationsMapView: MKMapView!
    @IBOutlet var longPressGestureRecognizer: UILongPressGestureRecognizer!
    @IBOutlet weak var tapPinsToDeleteLabel: UILabel!
    @IBOutlet weak var tapPinsToDeleteLabelHeight: NSLayoutConstraint!
    
    // MARK: - Life Cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        navigationItem.rightBarButtonItem = editButtonItem
        tapPinsToDeleteLabelHeight.constant = 0
        
        // Get the stack
        let delegate = UIApplication.shared.delegate as! AppDelegate
        let stack = delegate.stack
        
        longPressGestureRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(addTravelLocationPin))
        travelLocationsMapView.gestureRecognizers = [longPressGestureRecognizer]
        
        
        // Create a fetchrequest
        let fr = NSFetchRequest<NSFetchRequestResult>(entityName: "Pin")
        fr.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
        
        // Create the FetchedResultsController
        fetchedResultsController = NSFetchedResultsController(fetchRequest: fr, managedObjectContext: stack.context, sectionNameKeyPath: nil, cacheName: nil)
        
        travelLocationsMapView.delegate = self
        
        // Restore the mapview
        let defaults = UserDefaults.standard
        if let locationData = defaults.dictionary(forKey: mapPersistanceKey) {
            
            let center = CLLocationCoordinate2DMake(locationData[latitudeKey] as! CLLocationDegrees, locationData[longitudeKey] as! CLLocationDegrees)
            let span = MKCoordinateSpanMake(locationData[latDeltaKey] as! CLLocationDegrees, locationData[longDeltaKey] as! CLLocationDegrees)
            let region = MKCoordinateRegion(center: center, span: span)
            
            travelLocationsMapView.setRegion(travelLocationsMapView.regionThatFits(region), animated: true)
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        navigationController?.isToolbarHidden = true
    }
    
    // Code below is from information at the following site: https://stackoverflow.com/questions/39214923/using-nsuserdefaults-to-save-region-of-an-mkmapview
    
    override func viewWillDisappear(_ animated: Bool) {
        let defaults = UserDefaults.standard
        let locationData = [latitudeKey: travelLocationsMapView.centerCoordinate.latitude,
            longitudeKey: travelLocationsMapView.centerCoordinate.longitude,
            latDeltaKey: travelLocationsMapView.region.span.latitudeDelta,
            longDeltaKey: travelLocationsMapView.region.span.longitudeDelta]
        defaults.set(locationData, forKey: mapPersistanceKey)
    }
    
    // MARK: - View Editing
    
    // Information for this method based on information found at:  https://stackoverflow.com/questions/36937285/editbuttonitem-does-not-work
    override func setEditing(_ editing: Bool, animated: Bool) {
        
        super.setEditing(editing, animated: animated)
        
        if editing {

            self.tapPinsToDeleteLabelHeight.constant = 50

        } else {
            
            self.tapPinsToDeleteLabelHeight.constant = 0
        }
    }

    // MARK: - Actions
    // Code for this method based on information found at:  https://stackoverflow.com/questions/30858360/adding-a-pin-annotation-to-a-map-view-on-a-long-press-in-swift
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
            
        } else if sender.state == .changed, pin != nil {
            let touchPoint = sender.location(in: travelLocationsMapView)
            let newCoordinates = travelLocationsMapView.convert(touchPoint, toCoordinateFrom: travelLocationsMapView)
            let latitude = Float(newCoordinates.latitude)
            let longitude = Float(newCoordinates.longitude)
            
            pin?.latitude = latitude
            pin?.longitude = longitude
            
        } else {
            pin = nil
        }
    }
    
    // MARK: - Handle Segue
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
        
        if segue.identifier! == "showPhotos" {
            
            if let photoAlbumVC = segue.destination as? PhotoAlbumViewController,
                let pin = pin {
                
                // Create Fetch Request
                let fr = createFetchRequest(for: pin)
                
                // Create FetchedResultsController
                let fc = NSFetchedResultsController(fetchRequest: fr, managedObjectContext:fetchedResultsController!.managedObjectContext, sectionNameKeyPath: nil, cacheName: nil)
                
                // Pass data to the Photo Album View Controller
                photoAlbumVC.fetchedResultsController = fc
                photoAlbumVC.pin = pin
                photoAlbumVC.store = store
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
    }
}

// MARK: - MKMapView

private extension MKMapView {
    func reloadData(from fecthedResultsController: NSFetchedResultsController<NSFetchRequestResult>?) {
        removeAnnotations(annotations)
        addAnnotations(fecthedResultsController?.fetchedObjects as! [MKAnnotation])
    }
}


