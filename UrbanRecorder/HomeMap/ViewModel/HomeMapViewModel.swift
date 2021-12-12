//
//  HomeMapViewModel.swift
//  UrbanRecorder
//
//  Created by ting hui wu on 2021/10/21.
//

import Foundation
import MapKit
import CoreLocation
import CoreMotion
import SwiftUI

class HomeMapViewModel: NSObject, ObservableObject {
    
    var buttonScale: CGFloat {
        return DeviceInfo.isCurrentDeviceIsPad ? 3 : 2
    }
    @Published var subscribeID: String = ""
    
    var currentSubscribeID: String = ""
    
    @Published var broadcastID: String = ""
    
    var currentBroadcastID: String = ""
    
    @Published var cardPosition = CardPosition.bottom
    
    var isUpdatedUserRegion: Bool = false
    
    var isMapDisplayFullScreen: Bool = true
    
    var urAudioEngineInstance = URAudioEngine.instance
    
    var userLocation: URLocationCoordinate3D?
    
    private var firstAnchorMotion: CMDeviceMotion?
    
    private var firstAnchorMotionCompassDegrees: Double?
    
    var userTrueNorthURMotionAttitude: URMotionAttitude?
    
    var receiverDirection: Double {
        return compassDegrees + receiverLastDirectionDegrees
    }
    // TrueNorthOrientationAnchor(Assume the first motion is faceing the phone)
    var trueNorthMotionAnchor: CMDeviceMotion?
    
    @Published var compassDegrees: Double = 0
    
    var receiverLatitude: Double = 0
    
    var receiverLongitude: Double = 0
    
    var receiverAltitude: Double = 0
    
    @Published var receiverLastDirectionDegrees: Double = 0
    
    @Published var receiverLastDistanceMeters: Double = 0
    
    @Published var isSelectedItemPlayAble: Bool = false
    
    var udpsocketLatenctMs: UInt64 = 0
    
    let locationManager = CLLocationManager()
    
    let headphoneMotionManager = CMHeadphoneMotionManager()
    
    var annotationItems: [HomeMapAnnotationItem] {
        var tmp: [HomeMapAnnotationItem] = []
        
        tmp.append(receiverAnnotationItem)
        
        return tmp
    }
    
    var receiverAnnotationItem: HomeMapAnnotationItem = HomeMapAnnotationItem(coordinate: CLLocationCoordinate2D(), type: .user, color: .clear)
    
    @Published var userCurrentRegion: MKCoordinateRegion = MKCoordinateRegion(center: CLLocationCoordinate2D(latitude: 40.75773, longitude: -73.985708), span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05))
    
    var udpSocketManager: UDPSocketManager = UDPSocketManager.shared
    
    @Published var showWave: Bool = false
    
    var volumeMaxPeakPercentage: Double = 0.01
    
    var featureColumns: [GridItem] = [GridItem(.fixed(100)),
                                      GridItem(.fixed(100)),
                                      GridItem(.fixed(100)),
                                      GridItem(.fixed(100))]
    
    @Published var featureData: [GridData] = []
    
    private var broadcastMicrophoneCaptureCallback: ((NSMutableData)->Void)?
    
    private var recordingMicrophoneCaptureCallback: ((Data)->Void)?
    
    @Published var isRecording: Bool = false
    
    var recordingHelper = URRecordingDataHelper()
    
    @Published var recordDuration: UInt = 0
    
    @Published var recordMovingDistance: Double = 0
    
    @Published var recordName: String = ""
    
    override init() {
        super.init()
        generateFeatureData()
        
        // Delegate/DataSource
        urAudioEngineInstance.dataSource = self
        urAudioEngineInstance.delegate = self
        // Location
        locationManager.delegate = self
        
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        
        locationManager.requestWhenInUseAuthorization()
        
        locationManager.startUpdatingLocation()
        
        if CLLocationManager.headingAvailable() {
            self.locationManager.startUpdatingHeading()
        }
        // Headphone Motion
        if headphoneMotionManager.isDeviceMotionAvailable {
            headphoneMotionManager.delegate = self
            
            headphoneMotionManager.startDeviceMotionUpdates(to: OperationQueue.current!, withHandler: {[weak self] motion, error  in
                guard let self = self, let motion = motion, error == nil else { return }
                self.headphoneMotionDidChange(motion)
            })
        }
        
        udpSocketManager.delegate = self
        // RecordHelper
        recordingHelper.delagete = self
        // add UDPSocket latency
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(handleUDPSocketConnectionLatency),
                                               name: Notification.Name.UDPSocketConnectionLatency,
                                               object: nil)
        
    }
    
    private func generateFeatureData() {
        let broadcastFeature = GridData(id: 0, title: "Broadcast", isShowing: false) {
            print("Broadcast")
        }
        
        let subscribeFeature = GridData(id: 1, title: "Subscribe", isShowing: false) {
            print("Subscribe")
        }
        
        let motionRecord = GridData(id: 2, title: "Record", isShowing: false) {
            print("Record")
        }
        
        let fileList = GridData(id: 3, title: "FileList", isShowing: false) {
            print("FileList")
        }
        
        featureData = [broadcastFeature, subscribeFeature, motionRecord, fileList]
    }
    
    func menuButtonDidClisked() {
        print("menuButtonDidClisked")
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
    
    func subscribeChannel() {
        currentSubscribeID = subscribeID
        
        // 1. setupSubscribeEnviriment
        self.urAudioEngineInstance.setupAudioEngineEnvironmentForScheduleAudioData()
        
        self.udpSocketManager.setupSubscribeConnection {
            self.udpSocketManager.subscribeChannel(from: "", with: self.currentSubscribeID)
        }
    }
    
    private func setupBroadcastMicrophoneCaptureCallback(){
        broadcastMicrophoneCaptureCallback = {[weak self] audioData in
            guard let self = self else { return }
            // TODO: Send data through UDPSocket
            self.udpSocketManager.broadcastBufferData(audioData, from: "", to: self.currentBroadcastID)
        }
    }
    
    private func setupRecordingMicrophoneCaptureCallback(){
        recordingMicrophoneCaptureCallback = {[weak self] audioData in
            guard let self = self else { return }
            // TODO: Send data through UDPSocket
            self.recordingHelper.schechuleURAudioBuffer(audioData)
        }
    }
    
    func broadcastChannel() {
        currentBroadcastID = broadcastID
        
        // 1. Request Microphone
        urAudioEngineInstance.requestRecordPermissionAndStartTappingMicrophone {[weak self] isGranted in
            guard let self = self else { return }
            if isGranted {
                // 2. setupBroadcastEnviriment
                self.urAudioEngineInstance.setupAudioEngineEnvironmentForCaptureAudioData()
                // 3. Connect and send audio buffer
                self.udpSocketManager.setupBroadcastConnection {
                    self.setupBroadcastMicrophoneCaptureCallback()
                }
            } else {
                print("Show Alert View")
                // TODO: Show Alert View
            }
        }
        
    }
    
    func recordButtonDidClicked() {
        isRecording.toggle()
        
        if isRecording {
            // 1. Request Microphone
            urAudioEngineInstance.requestRecordPermissionAndStartTappingMicrophone {[weak self] isGranted in
                guard let self = self else { return }
                if isGranted {
                    // 2. setupBroadcastEnviriment
                    self.urAudioEngineInstance.setupAudioEngineEnvironmentForCaptureAudioData()
                    // 3. generateEmpty URAudioData
                    let inputFormat = self.urAudioEngineInstance.convertFormat
                    
                    let _ = self.recordingHelper.generateEmptyURRecordingData(audioFormat: inputFormat)
                    // 4.setupRecordingEnviriment
                    self.setupRecordingMicrophoneCaptureCallback()
                    
                    print("Start Recording With File: \(self.recordName)")
                } else {
                    print("Show Alert View")
                    // TODO: Show Alert View
                }
            }
        } else {
            guard let currentRecordingData = recordingHelper.getCurrentRecordingURAudioData() else { return }
            
            let data = URRecordingDataHelper.encodeURAudioData(urAudioData: currentRecordingData)
            
            let bytes = data.count
            
            let bytesFornatter = ByteCountFormatter.string(fromByteCount: Int64(bytes), countStyle: .file)
            
            print("Create File(\(recordName)) Size: \(bytesFornatter)")
            // Create a Core Data Object
            PersistenceController.shared.creatRecordedData {[recordName, recordDuration, recordMovingDistance] newRecordedData in
                newRecordedData.id = UUID()
                newRecordedData.timestamp = Date()
                newRecordedData.fileName = recordName
                newRecordedData.file = data
                newRecordedData.recordDuration = Int64(recordDuration)
                newRecordedData.movingDistance = recordMovingDistance
            }
            
            // RESET THE RECORD STATUS
            recordName = ""
            
            recordDuration = 0
            
            recordMovingDistance = 0
            
            recordingMicrophoneCaptureCallback = nil
       
        }
    }
    
    func didReceiveVolumePeakPercentage(_ percentage: Double) {
        // Vivration is not working
        UIDevice.vibrate()
        withAnimation(.linear(duration: 0.4)) {
            showWave = true
            
            volumeMaxPeakPercentage = percentage
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
            self.resetVolumePeakPercentage()
        }
    }
    
    func resetVolumePeakPercentage() {
        showWave = false
        
        volumeMaxPeakPercentage = 0.01
    }
    
    func resetAnchorDegrees() {
        firstAnchorMotionCompassDegrees = nil
        firstAnchorMotion = nil
    }
    
    @objc func handleUDPSocketConnectionLatency(notification: Notification) {
        guard let msSecond = notification.userInfo?["millisecond"] as? UInt64 else { return }
        udpsocketLatenctMs = msSecond
    }
}

extension HomeMapViewModel: UDPSocketManagerDelegate {
    func didReceiveAudioBuffersData(_ manager: UDPSocketManager, data: Data, from sendID: String) {
        let urAudioBuffer = URAudioEngine.parseURAudioBufferData(data)
        urAudioEngineInstance.schechuleRendererAudioBuffer(urAudioBuffer)
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

// Core Data Manager
extension HomeMapViewModel: CLLocationManagerDelegate, CMHeadphoneMotionManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.first else { return }
        let latitude = location.coordinate.latitude
        let longitude = location.coordinate.longitude
        let altitude = location.altitude
        let locationCoordinate = CLLocationCoordinate2D(latitude: latitude,
                                                        longitude: longitude)
        DispatchQueue.main.async {
            self.userLocation = URLocationCoordinate3D(latitude: latitude, longitude: longitude, altitude: altitude)
            if !self.isUpdatedUserRegion {
                self.userCurrentRegion.center = locationCoordinate
                self.isUpdatedUserRegion.toggle()
            }
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateHeading newHeading: CLHeading) {
        var newDegrees =  -newHeading.magneticHeading + 360
        
        if (newDegrees - compassDegrees) > 0 {
            if abs(newDegrees - compassDegrees) > 180 {
                newDegrees -= 360
            }
        } else {
            if abs(newDegrees - compassDegrees) > 180 {
                newDegrees += 360
            }
        }
        
        compassDegrees = newDegrees
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Location Manager Did Fail With Error: \(error.localizedDescription)")
    }
    
    func headphoneMotionDidChange(_ motion: CMDeviceMotion) {
        guard let anchorMotion = firstAnchorMotion,
              let firstAnchorMotionCompassDegrees = firstAnchorMotionCompassDegrees else {
            firstAnchorMotionCompassDegrees = compassDegrees
            firstAnchorMotion = motion
            return}
        
        let trueNorthYawDegrees = (anchorMotion.attitude.yaw - motion.attitude.yaw) / Double.pi * 180 - firstAnchorMotionCompassDegrees
        let trueNorthPitchDegrees = (anchorMotion.attitude.pitch - motion.attitude.pitch) / Double.pi * 180
        let trueNorthRollDegrees = (anchorMotion.attitude.roll - motion.attitude.roll) / Double.pi * 180
        
        userTrueNorthURMotionAttitude = URMotionAttitude(rollDegrees: trueNorthRollDegrees, pitchDegrees: trueNorthPitchDegrees, yawDegrees: trueNorthYawDegrees)
    }
}
// URAudioEngineDataSource
extension HomeMapViewModel: URAudioEngineDataSource {
    func urAudioEngine(currentLocationForEngine: URAudioEngine) -> URLocationCoordinate3D? {
        guard let userLocation = userLocation else { return nil }
        return userLocation
    }
    
    func urAudioEngine(currentTrueNorthAnchorsMotionForEngine: URAudioEngine) -> URMotionAttitude? {
        guard let attitude = userTrueNorthURMotionAttitude else { return nil}
        return attitude
    }
}
// URAudioEngineDelegate
extension HomeMapViewModel: URAudioEngineDelegate {
    func didUpdateReceiversBufferMetaData(_ engine: URAudioEngine, metaData: URAudioBufferMetadata) {
        receiverLatitude = metaData.locationCoordinate.latitude
        receiverLongitude = metaData.locationCoordinate.longitude
        receiverAltitude = metaData.locationCoordinate.altitude
        
        // Update Receiver Location
        if receiverAnnotationItem.color == .clear {
            receiverAnnotationItem = HomeMapAnnotationItem(coordinate: CLLocationCoordinate2D(latitude: receiverLatitude, longitude: receiverLongitude),
                                                           type: .user, color: .orange)
        } else {
            receiverAnnotationItem.coordinate.latitude = receiverLatitude
            receiverAnnotationItem.coordinate.longitude = receiverLongitude
        }
        
        guard let userLocation = userLocation else {print("Fail in getting userlocation"); return }
        
        let directionAndDistance = userLocation.distanceAndDistance(from: metaData.locationCoordinate)
        
        receiverLastDirectionDegrees = directionAndDistance.direction
        receiverLastDistanceMeters = directionAndDistance.distance
    }
    
    func captureAudioBufferDataCallBack(_ engine: URAudioEngine, urAudioData: Data) {
        broadcastMicrophoneCaptureCallback?(NSMutableData(data: urAudioData))
        recordingMicrophoneCaptureCallback?(urAudioData)
    }
}
// URRecordingDataHelperDelegate
extension HomeMapViewModel: URRecordingDataHelperDelegate {
    func didUpdateAudioRecordingDuration(_ seconds: UInt) {
        if featureData[2].isShowing {
            DispatchQueue.main.async {[weak self] in
                self?.recordDuration = seconds
            }
        }
    }
    
    func didUpdateAudioRecordingMovingDistance(_ meters: Double) {
        if featureData[2].isShowing {
            DispatchQueue.main.async {[weak self] in
                self?.recordMovingDistance = meters
            }
        }
    }
}
