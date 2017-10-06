//
//  ViewControllerExtensions.swift
//  VIrtualTourist
//
//  Created by Pete Barnes on 10/4/17.
//  Copyright © 2017 Pete Barnes. All rights reserved.
//

import MapKit

// MARK: - MKMapViewDelegate

extension UIViewController: MKMapViewDelegate {
    
    public func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        
        let reuseId = "pin"
        
        var pinView = mapView.dequeueReusableAnnotationView(withIdentifier: reuseId) as? MKPinAnnotationView
        
        if pinView == nil {
            pinView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: reuseId)
            pinView!.canShowCallout = annotation.subtitle != nil ? true : false
            pinView!.pinTintColor = .red
            pinView!.animatesDrop = true
            pinView!.rightCalloutAccessoryView = UIButton(type: .detailDisclosure)
        }
        else {
            pinView!.annotation = annotation
        }
        
        return pinView
    }
    
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
    
}
