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
    
    static let desiredAccuracy:CLLocationAccuracy = kCLLocationAccuracyBest
    
    var buttonScale: CGFloat {
        return DeviceInfo.isCurrentDeviceIsPad ? 3 : 2
    }
    @Published var subscribeID: String = ""
    
    var currentSubscribeID: String = ""
    
    @Published var broadcastID: String = ""
    
    var currentBroadcastID: String = ""
    
    @Published var cardPosition = CardPosition.middle
    
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
    
    @Published var removeAnnotationItem: HomeMapAnnotation?
    
    @Published var receiverAnnotationItem: HomeMapAnnotation = HomeMapAnnotation(coordinate: CLLocationCoordinate2D(), type: .user, color: .clear)
    
    @Published var userCurrentRegion: MKCoordinateRegion?
    
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
    // FileList
    @Published var setNeedReload: Bool = false
    
    @Published var fileListCount: Int = 0
    
    @Published var expandedData: RecordedData? = nil
    
    @Published var playingData: RecordedData? = nil
    
    @Published var pauseData: RecordedData? = nil
    // Map
    @Published var displayRoutes: [MKRoute] = []
    
    @Published var removeRoutes: [MKRoute] = []
    
    override init() {
        super.init()
        generateFeatureData()
        
        // Delegate/DataSource
        urAudioEngineInstance.dataSource = self
        urAudioEngineInstance.delegate = self
        // Location
        locationManager.delegate = self
        
        locationManager.desiredAccuracy = HomeMapViewModel.desiredAccuracy
        
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
    
    func fileListOnDelete(_ recordedData: RecordedData) {
        PersistenceController.shared.deleteRecordedData(recordedData)
    }
    
    func fileListOnSelected(_ expandedData: RecordedData?) {
        
        self.expandedData = expandedData
        
        if let displayData = expandedData{
            displayRecordedDataOnMap(displayData)
        }
    }
    
    func fileListOnPlaying(_ playingData: RecordedData?) {
        
        if let pauseData = pauseData,  (pauseData == playingData) {
            print("Playing pause data")
            // TODO: get Puase Duration and setup Player
            self.playingData = pauseData
        } else {
            print("Play")
            self.pauseData = nil
            self.playingData = playingData
        }
        // 2 Parse and schechule in audioengine
        guard let playingData = playingData,
              let file = playingData.file else { return }
        
        let playingDuration = playingData.playingDuration
        
        let urAudioData = URRecordingDataHelper.parseURAudioData(file)
        
        urAudioEngineInstance.setupPlayerDataAndStartPlayingAtSeconds(urAudioData, startOffset: playingDuration, updateInterval: 1) { updatedDuration in
            // TODO: Record playing duration
            DispatchQueue.main.async {
                withAnimation {
                    self.playingData?.playingDuration = updatedDuration
                }
            }
        } endOfFilePlayingCallback: { endSecond in
            print("The File Is End Of Playing At: \(endSecond)")
            // TODO: Stop the engine
            DispatchQueue.main.async {
                self.playingData?.playingDuration = 0
                self.playingData = nil
            }
            self.urAudioEngineInstance.removePlayerData()
        }

        // 3. SetUp engine environment
        urAudioEngineInstance.setupAudioEngineEnvironmentForScheduleAudioData()
        
        
    }
    
    func fileListOnPause() {
        print("Pause")
        // TODO: record pause duration
        self.pauseData = self.playingData
        self.playingData = nil
        self.urAudioEngineInstance.removePlayerData()
    }
    
    private func displayRecordedDataOnMap(_ displayData: RecordedData) {
        // 1. Parse URAudioBuffers in locatinos
        guard let data = displayData.file else { return }
        
        let urAudioData = URRecordingDataHelper.parseURAudioData(data)
        
        let buffersLocation: [CLLocationCoordinate2D] = urAudioData.audioBuffers.filter { buffer->Bool in
            buffer.metadata != nil
        }.map { buffer in
            return CLLocationCoordinate2D(latitude: buffer.metadata!.locationCoordinate.latitude,
                                          longitude: buffer.metadata!.locationCoordinate.longitude)
        }
        
        let routeBuilder = RouteBuilder(locationCollection: buffersLocation)
        // 2. Generate MKPlaceMark with location => The distance bigger than 1 M as a one MKPlaceMark
        let oneMeterPlaceMark = routeBuilder.generatePlaceMarkDistanceOver(meters: 1)
        
        // 3. Connect Location -> MKPlaceMark -> MapItem, each MapItem into a GroupedRoute
        let mapItems = RouteBuilder.converToMapItems(placeMarks: oneMeterPlaceMark)
        
        
        // 4. Generate MKRout And call the map method addOverlay for add the line on the map => MKDirections.Request(source, destination),
        RouteBuilder.generateRouteWith(mapItems: mapItems) {[weak self] result in
            guard let self = self else { return }
            switch result {
            case .success(let routes):
                DispatchQueue.main.async {
                    //Remove the last routes
                    self.removeRoutes = self.displayRoutes
                    self.displayRoutes = routes
                    print(routes)
                    guard let startLocation = buffersLocation.first else { return }
                    self.isUpdatedUserRegion = false
                    self.userCurrentRegion = MKCoordinateRegion(center: startLocation, span: MKCoordinateSpan(latitudeDelta: 0.005, longitudeDelta: 0.005))
                }
            case .failure(let error):
                print(error)
            }
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
        if userLocation != nil {
            userLocation!.latitude = latitude
            userLocation!.longitude = longitude
            userLocation!.altitude = altitude
        } else {
            userLocation = URLocationCoordinate3D(latitude: latitude, longitude: longitude, altitude: altitude)
            print("latitude: \(latitude), longitude: \(longitude)")
        }
        
        if !self.isUpdatedUserRegion {
            self.userCurrentRegion = MKCoordinateRegion(center: locationCoordinate,
                                                        span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05))
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
        return userLocation
    }
    
    func urAudioEngine(currentTrueNorthAnchorsMotionForEngine: URAudioEngine) -> URMotionAttitude? {
        return userTrueNorthURMotionAttitude
    }
}
// URAudioEngineDelegate
extension HomeMapViewModel: URAudioEngineDelegate {
    func didUpdateReceiversBufferMetaData(_ engine: URAudioEngine, metaData: URAudioBufferMetadata) {
        receiverLatitude = metaData.locationCoordinate.latitude
        receiverLongitude = metaData.locationCoordinate.longitude
        receiverAltitude = metaData.locationCoordinate.altitude
        
        // Update Receiver Location
        DispatchQueue.main.async {[weak self, receiverLatitude, receiverLongitude] in
            guard let self = self else { return }
            self.removeAnnotationItem = self.receiverAnnotationItem
            
            self.receiverAnnotationItem = HomeMapAnnotation(coordinate: CLLocationCoordinate2D(latitude: receiverLatitude, longitude: receiverLongitude), type: .user, color: .orange)
        }
        
        guard let userLocation = userLocation else {print("Fail in getting userlocation"); return }
        
        let directionAndDistance = userLocation.distanceAndDistance(from: metaData.locationCoordinate)
        DispatchQueue.main.async {[weak self, directionAndDistance] in
            guard let self = self else { return }
            self.receiverLastDirectionDegrees = directionAndDistance.direction
            self.receiverLastDistanceMeters = directionAndDistance.distance
        }
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
