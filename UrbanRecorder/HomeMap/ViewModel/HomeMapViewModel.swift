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
    
    func getAvailableUsersList() {
        #warning("Test Api work for temporarily")
        HTTPClient.shared.request(UserAPI.getAvailableUsersList(userID: "")) { result in
            switch result {
            case .success(let data):
                guard let data = data, let list = try? JSONDecoder().decode(AvailableUserListRP.self, from: data) else {
                    print("Data is empty")
                    return
                }
                
                print(list)
            case .failure(let error):
                print(error)
            }
        }
    }
    
    func subscribeAllEvent() {
        SubscribeManager.shared.delegate = self
        
        SubscribeManager.shared.setupWith("test1234")
        
    }
}

extension HomeMapViewModel: SocketManagerDelegate {
    
    func callRequest(from user: UserInfo) {
        print("callRequest from: \(user)")
    }
    
    func callRequestAccept(from user: UserInfo) {
        print("callRequestAccept from: \(user)")
    }
    
    func callRequestDecline(from user: UserInfo) {
        print("callRequestDecline from: \(user)")
    }
    
    func calledSessionClosed(by user: UserInfo) {
        print("calledSessionClosed from: \(user)")
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
