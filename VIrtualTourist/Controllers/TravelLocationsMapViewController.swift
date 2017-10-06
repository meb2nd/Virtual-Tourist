//
//  TravelLocationsMapViewController.swift
//  VIrtualTourist
//
//  Created by Pete Barnes on 10/3/17.
//  Copyright © 2017 Pete Barnes. All rights reserved.
//

import UIKit
import MapKit

class TravelLocationsMapViewController: UIViewController {

    @IBOutlet var longPressGestureRecognizer: UILongPressGestureRecognizer!
    @IBOutlet weak var travelLocationsMapView: MKMapView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
    }

    // Code for this method basedon infomration found at:  https://stackoverflow.com/questions/30858360/adding-a-pin-annotation-to-a-map-view-on-a-long-press-in-swift
    @IBAction func addTravelLocationPin(_ sender: Any) {
        
        let touchPoint = longPressGestureRecognizer.location(in: travelLocationsMapView)
        let newCoordinates = travelLocationsMapView.convert(touchPoint, toCoordinateFrom: travelLocationsMapView)
        let annotation = MKPointAnnotation()
        annotation.coordinate = newCoordinates
        travelLocationsMapView.addAnnotation(annotation)
    }
}

