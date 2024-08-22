//
//  LocationManager.swift
//  Weatherapp
//
//  Created by Manasa Parchuri  on 8/14/24.
//

import Foundation
import CoreLocation

class LocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    
    // Creating an instance of CLLocationManager, the framework we use to get the coordinates
    var locatioManager = CLLocationManager()
    
    @Published var location: CLLocationCoordinate2D?
    @Published var isLoading = false
    
    override init() {
        super.init()
        
        // Assigning a delegate to our CLLocationManager instance
        locatioManager.delegate = self
    }
    
    // Requests the one-time delivery of the user’s current location, see
    func requestLocation() {
        isLoading = true
        // Set the desired accuracy (kCLLocationAccuracyBest provides the highest possible accuracy.)
        locatioManager.desiredAccuracy = kCLLocationAccuracyBest
       // Request permission to use location services
        locatioManager.requestWhenInUseAuthorization()
        locatioManager.startUpdatingLocation()
    }
    
    // Set the location coordinates to the location variable
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        location = locations.first?.coordinate
        isLoading = false
    }
    
    
    // This function will be called if we run into an error
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Error getting location", error)
        isLoading = false
    }
}

