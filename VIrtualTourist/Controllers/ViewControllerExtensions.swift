//
//  ViewControllerExtensions.swift
//  VIrtualTourist
//
//  Created by Pete Barnes on 10/4/17.
//  Copyright © 2017 Pete Barnes. All rights reserved.
//

import MapKit
import CoreData

// MARK: - MKMapViewDelegate

extension UIViewController: MKMapViewDelegate {
    
    public func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        
        let reuseId = "pin"
        
        var pinView = mapView.dequeueReusableAnnotationView(withIdentifier: reuseId) as? MKPinAnnotationView
        
        if pinView == nil {
            pinView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: reuseId)
        }
        else {
            pinView!.annotation = annotation
        }
        
        setupPinView(annotation, pinView)
        
        return pinView
    }
    
    fileprivate func setupPinView(_ annotation: MKAnnotation, _ pinView: MKPinAnnotationView?) {
        
        pinView!.pinTintColor = .red
        pinView?.canShowCallout = true
        
        if let pin = annotation as? Pin, pin.isDraggable {
            pinView!.isDraggable = true
            pinView!.animatesDrop = true
            pin.isDraggable = false
        } else {
            pinView!.isDraggable = false
            pinView!.animatesDrop = false
        }
    }
 /*
    public func mapView(_ mapView: MKMapView, annotationView view: MKAnnotationView, calloutAccessoryControlTapped control: UIControl) {
        if control == view.rightCalloutAccessoryView {
            let app = UIApplication.shared
            if view.annotation?.subtitle != nil, let toOpen = view.annotation?.subtitle!,
                toOpen.lowercased().starts(with: "http://") || toOpen.lowercased().starts(with: "https://") {
                
                app.open(URL(string: toOpen)!, completionHandler: nil)
                
            } else {
                //AlertViewHelper.presentAlert(self, title: "Cannot Display Student Link", message: "Student has entered an invalid URL")
            }
        }
    }
 
 */
    
    public func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
        
        guard let pin = view.annotation as? Pin,
            let travelLocationsMapVC = mapView.delegate as? TravelLocationsMapViewController else {
                // Nothing to do
                return
        }
        
        mapView.deselectAnnotation(view.annotation, animated: false)
        
        // Inject selected pin into the travelLocationsMapVC and show photos
        travelLocationsMapVC.pin = pin
        travelLocationsMapVC.performSegue(withIdentifier: "showPhotos", sender: nil)
        
    }
    
    // Code for this method based on informatino found at:  https://stackoverflow.com/questions/29776853/ios-swift-mapkit-making-an-annotation-draggable-by-the-user
    // https://discussions.udacity.com/t/virtual-tourist-dragging-a-pin/28906
    
    public func mapView(_ mapView: MKMapView, annotationView view: MKAnnotationView, didChange newState: MKAnnotationViewDragState, fromOldState oldState: MKAnnotationViewDragState) {
        switch newState {
        case .starting:
            view.dragState = .dragging
        case .ending, .canceling:
            let newCoordinates = mapView.convert(view.center, toCoordinateFrom: mapView)
            let pin = view.annotation as! Pin
            pin.latitude = Float(newCoordinates.latitude)
            pin.longitude = Float(newCoordinates.longitude)
            view.isDraggable = false
            view.dragState = .none
        default: break
        }
    }
}
