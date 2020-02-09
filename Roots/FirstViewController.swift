//
//  FirstViewController.swift
//  Roots
//
//  Created by Jill Polsin on 2/8/20.
//  Copyright © 2020 Roots. All rights reserved.
//

import UIKit
import MapKit
import CoreLocation
import AVFoundation

class FirstViewController: UIViewController {

    @IBOutlet weak var directionsLabel: UILabel!
    @IBOutlet weak var emmisionsLabel: UILabel!
    @IBOutlet weak var searchBar: UISearchBar!
    @IBOutlet weak var mapView: MKMapView!
    
    let locationManager = CLLocationManager()
    var currentCoordinate: CLLocationCoordinate2D!
    var transport_type = 0
    var gasUsed = 0.0
    var emissions = 0.0
    var gasCost = 0.0
    
    @IBAction func walking_route(_ sender: Any) {
        transport_type = 1
    }
    
    @IBAction func car_route(_ sender: Any) {
        transport_type = 2
    }
    
    func calculate_costs(fuel_economy: Double, mileage: Double) {
        gasUsed = mileage / fuel_economy
        emissions = ((gasUsed * 19.4 * (100/95))*10).rounded()/10
        gasCost = ((gasUsed * 3.5)*10).rounded()/10
        
    }
    
    var steps = [MKRoute.Step]()
    let speechSynthesizer = AVSpeechSynthesizer()
    
    var stepCounter = 0
    
    override func viewDidLoad() {
        super.viewDidLoad()
        searchBar.placeholder = "Look for a place to go"
        locationManager.requestAlwaysAuthorization()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBestForNavigation
        locationManager.startUpdatingLocation()
    }
    
    func getDirections(to destination: MKMapItem){
        let sourcePlacemark = MKPlacemark(coordinate: currentCoordinate)
        let sourceMapItem = MKMapItem(placemark: sourcePlacemark)
        let directionsRequest = MKDirections.Request()
        directionsRequest.source = sourceMapItem
        directionsRequest.destination = destination
        if transport_type == 1 {
            directionsRequest.transportType = .walking
        } else {
            directionsRequest.transportType = .automobile
        }
        
        let directions = MKDirections(request: directionsRequest)
        directions.calculate { (response, _) in
            guard let response = response else {return}
            guard let primaryRoute = response.routes.first else { return }
            
            self.emmisionsLabel.text = ""
            
            if self.transport_type != 1{
                let distance = primaryRoute.distance / 1609.344
                self.calculate_costs(fuel_economy: 25, mileage: distance)
                let time = Int(round(primaryRoute.expectedTravelTime / 60))
                self.emmisionsLabel.text = "Emissions: \(self.emissions) lbs of C02 \nCost of Gas: $\(self.gasCost) \nExpected Time: \(time) min"
            }
            
            self.mapView.removeOverlays(self.mapView.overlays)
            self.mapView.addOverlay(primaryRoute.polyline)
            
            self.locationManager.monitoredRegions.forEach({self.locationManager.stopMonitoring(for: $0)})
            
            self.steps = primaryRoute.steps
            for i in 0 ..< primaryRoute.steps.count {
                let step = primaryRoute.steps[i]
                print(step.instructions)
                print(step.distance)
                let region = CLCircularRegion(center: step.polyline.coordinate, radius: 20, identifier: "\(i)")
                self.locationManager.startMonitoring(for: region)
                let circle = MKCircle(center: region.center, radius: region.radius)
                self.mapView.addOverlay(circle)
            }
            
            let initialMessage = "In \(self.steps[1].distance) meters, \(self.steps[1].instructions)."
            self.directionsLabel.text = initialMessage
            let speechUtterance = AVSpeechUtterance(string: initialMessage)
            self.speechSynthesizer.speak(speechUtterance)
            self.stepCounter += 1
        }
    }

}

extension FirstViewController: CLLocationManagerDelegate {
    public func locationManager(_ manager: CLLocationManager,didUpdateLocations locations: [CLLocation]) {
        manager.stopUpdatingLocation()
        guard let currentLocation = locations.first else { return }
        currentCoordinate = currentLocation.coordinate
        mapView.userTrackingMode = .followWithHeading
    }
    
    func locationManager(_ manager: CLLocationManager, didEnterRegion region: CLRegion) {
        print("Entered")
        stepCounter += 1
        if stepCounter < steps.count{
            let currentStep = steps[stepCounter]
            let message = "In \(currentStep.distance) meters, \(currentStep.instructions)"
            directionsLabel.text = message
            let speechUtterance = AVSpeechUtterance(string: message)
            speechSynthesizer.speak(speechUtterance)
        } else{
            let message = "Arrived at destination"
            directionsLabel.text = message
            let speechUtterance = AVSpeechUtterance(string: message)
            speechSynthesizer.speak(speechUtterance)
            stepCounter = 0
            locationManager.monitoredRegions.forEach({self.locationManager.stopMonitoring(for: $0)})
        }
    }
}

extension FirstViewController: UISearchBarDelegate {
    public func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        searchBar.endEditing(true)
        let localSearchRequest = MKLocalSearch.Request()
        localSearchRequest.naturalLanguageQuery = searchBar.text
        let region = MKCoordinateRegion(center: currentCoordinate, span: MKCoordinateSpan(latitudeDelta: 0.1, longitudeDelta: 0.1))
        localSearchRequest.region = region
        let localSearch = MKLocalSearch(request: localSearchRequest)
        localSearch.start { (response, _) in
            guard let response = response else {return}
            //print(response.mapItems)
            guard let firstMapItem = response.mapItems.first else {return}
            self.getDirections(to: firstMapItem)
        }
    }
}

extension FirstViewController: MKMapViewDelegate {
    public func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        if overlay is MKPolyline{
            let renderer = MKPolylineRenderer(overlay: overlay)
            renderer.strokeColor = .green
            renderer.lineWidth = 10
            return renderer
        }
        if overlay is MKCircle{
            let renderer = MKCircleRenderer(overlay: overlay)
            renderer.strokeColor = .blue
            renderer.fillColor = .blue
            renderer.alpha = 0.5
            return renderer
        }
        return MKOverlayRenderer()
    }
}

