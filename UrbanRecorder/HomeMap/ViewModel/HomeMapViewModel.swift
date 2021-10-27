//
//  HomeMapViewModel.swift
//  UrbanRecorder
//
//  Created by ting hui wu on 2021/10/21.
//

import Foundation
import MapKit
import CoreLocation

class HomeMapViewModel: NSObject, ObservableObject, CLLocationManagerDelegate {
    
    var buttonScale: CGFloat {
        return DeviceInfo.isCurrentDeviceIsPad ? 3 : 2
    }
    
    @Published var cardPosition = CardPosition.bottom
    
    var isUpdatedUserRegion: Bool = false
    
    var isMapDisplayFullScreen: Bool = true
    
    @Published var isShowingRecorderView: Bool = false
    
    @Published var isSelectedItemPlayAble: Bool = false
    
    let locationManager = CLLocationManager()
    
    var annotationItems: [HomeMapAnnotationItem] = [HomeMapAnnotationItem.taipei101]
    
    @Published var userCurrentRegion: MKCoordinateRegion = MKCoordinateRegion(center: CLLocationCoordinate2D(latitude: 40.75773, longitude: -73.985708), span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05))
    
    func updateUserCurrentRegion() {
        
    }
    override init() {
        super.init()
        locationManager.delegate = self
        
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        
        locationManager.requestWhenInUseAuthorization()
        
        locationManager.startUpdatingLocation()
    }
    
    func menuButtonDidClisked() {
        print("menuButtonDidClisked")
    }
    
    func recordButtonDidClicked() {
        print("recordButtonDidClicked")
        isShowingRecorderView.toggle()
    }
    
    func playButtonDidClicked() {
        print("playButtonDidClicked")
    }
}
// location Manager
extension HomeMapViewModel {
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.first else { return }
        let latitude = location.coordinate.latitude
        let longitude = location.coordinate.longitude
        
        let locationCoordinate = CLLocationCoordinate2D(latitude: latitude,
                                                        longitude: longitude)
        if !isUpdatedUserRegion {
            userCurrentRegion.center = locationCoordinate
            isUpdatedUserRegion.toggle()
        }
    }
    
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Location Manager Did Fail With Error: \(error.localizedDescription)")
    }
}
