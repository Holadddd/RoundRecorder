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
    
    // MARK: - Module parameters
    static let desiredAccuracy:CLLocationAccuracy = kCLLocationAccuracyBest
    
    // MARK: - Broadcast
    @Published var isBroadcasting: Bool = false
    
    @Published var showBroadcastPermissionAlert: Bool = false
    
    @Published var broadcastID: String = ""
    
    private var broadcastMicrophoneCaptureCallback: ((NSMutableData)->Void)?
    // MARK: - Subscribe
    @Published var isSubscribing: Bool = false
    
    @Published var showSubscribePermissionAlert: Bool = false
    
    @Published var subscribeID: String = ""
    // MARK: - Record
    @Published var isRecording: Bool = false
    
    @Published var recordDuration: UInt = 0
    
    @Published var recordMovingDistance: Double = 0
    
    @Published var recordName: String = ""
    
    @Published var showRecordingPermissionAlert: Bool = false
    
    var recordingHelper = URRecordingDataHelper()
    
    private var recordingMicrophoneCaptureCallback: ((Data)->Void)?
    // MARK: - Filelist
    @Published var showPlayingPermissionAlert: Bool = false
    
    @Published var setNeedReload: Bool = false
    
    @Published var fileListCount: Int = 0
    
    @Published var expandedData: RecordedData? = nil
    
    @Published var playingData: RecordedData? = nil
    
    @Published var pauseData: RecordedData? = nil
    // MARK: - Map & Compass
    @Published var isSetupCurrentLocation: Bool = false
    
    @Published var isLocationLocked: Bool = false
    
    var headingDirection: CLLocationDirection {
        CLLocationDirection(-self.compassDegrees)
    }
    
    var cacheRoutes: [RecordedData] = []
    
    @Published var displayRoutes: [MKRoute] = []
    
    @Published var removeRoutes: [MKRoute] = []
    
    @Published var userLocation: CLLocationCoordinate2D?
    
    @Published var userHeadingDegrees: Double?
    
    var userURLocation: URLocationCoordinate3D?
    
    private var firstAnchorMotion: CMDeviceMotion?
    
    private var firstAnchorMotionCompassDegrees: Double?
    
    var userTrueNorthURMotionAttitude: URMotionAttitude?
    
    var receiverDirection: Double {
        return compassDegrees + receiverLastDirectionDegrees
    }
    
    @Published var isSelectedItemPlayAble: Bool = false
    
    @Published var userAnootion: HomeMapAnnotation = HomeMapAnnotation(coordinate: CLLocationCoordinate2D(), type: .user, color: .clear) {
        willSet {
            // Remove the last receiver annotion
            removeAnnotationItems.append(userAnootion)
        }
    }
    
    @Published var removeAnnotationItems: [HomeMapAnnotation] = []
    
    @Published var receiverAnnotationItem: HomeMapAnnotation = HomeMapAnnotation(coordinate: CLLocationCoordinate2D(), type: .receiver, color: .clear) {
        willSet {
            // Remove the last receiver annotion
            removeAnnotationItems.append(receiverAnnotationItem)
        }
    }
    
    @Published var userCurrentMapCamera: MKMapCamera?
    
    var udpsocketLatenctMs: UInt64 = 0
    
    let locationManager = CLLocationManager()
    
    var updateByMapItem: Bool = true
    
    @Published var showWave: Bool = false
    
    
    // MARK: - DirectionAndDistanceMetersView
    @Published var isShowingDirectionAndDistanceView: Bool = false
    
    var trueNorthMotionAnchor: CMDeviceMotion? // TrueNorthOrientationAnchor(Assume the first motion is faceing the phone)
    
    @Published var compassDegrees: Double = 0
    
    var receiverLatitude: Double = 0
    
    var receiverLongitude: Double = 0
    
    var receiverAltitude: Double = 0
    
    @Published var receiverLastDirectionDegrees: Double = 0
    
    @Published var receiverLastDistanceMeters: Double = 0
    
    @Published var isSetStaticDistanceMeters: Bool = false
    
    @Published var isShowingWave: Bool = false
    
    var volumeMaxPeakPercentage: Double = 0.01
    // MARK: - Menubar control
    
    
    // MARK: - SegmentSlideOverCard
    @Published var cardViewUseCase: CardViewUseCase? {
        didSet{
            // Reset card position
            if let cardViewUseCase = cardViewUseCase {
                cardPosition = cardViewUseCase.firstPosition
            }
        }
    }
    
    @Published var cardPosition: CardPosition = .bottom
    
    // MARK: - URAudioEngine
    var urAudioEngineInstance = URAudioEngine.instance
    
    let headphoneMotionManager = CMHeadphoneMotionManager()
    
    let headphoneMotionManagerOperationQueue: OperationQueue = OperationQueue()
    // MARK: - Network
    var udpSocketManager: UDPSocketManager = UDPSocketManager.shared
    
    // MARK: - Backgroud Task
    var broadcastingBackgroundTaskID: UIBackgroundTaskIdentifier?
    
    var subscribingBackgroundTaskID: UIBackgroundTaskIdentifier?
    
    var recordingBackgroundTaskID: UIBackgroundTaskIdentifier?
    
    var playingBackgroundTaskID: UIBackgroundTaskIdentifier?
    // MARK: - Generate
    override init() {
        super.init()
        // Delegate/DataSource
        urAudioEngineInstance.dataSource = self
        urAudioEngineInstance.delegate = self
        // Location
        locationManager.delegate = self
        
        locationManager.desiredAccuracy = HomeMapViewModel.desiredAccuracy
        
        locationManager.requestWhenInUseAuthorization()
        
        locationManager.startUpdatingLocation()
        
        startDeviceMotionDetection()
        
        udpSocketManager.delegate = self
        // RecordHelper
        recordingHelper.delagete = self
        // add UDPSocket latency
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(handleUDPSocketConnectionLatency),
                                               name: Notification.Name.UDPSocketConnectionLatency,
                                               object: nil)
        
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
    //
    func startDeviceMotionDetection() {
        // Headphone Motion
        if headphoneMotionManager.isDeviceMotionAvailable {
            resetAnchorDegrees()
            
            headphoneMotionManager.delegate = self
            
            headphoneMotionManager.startDeviceMotionUpdates()
        }
        
        if CLLocationManager.headingAvailable() {
            self.locationManager.startUpdatingHeading()
        }
    }
    // MARK: - Radio
    func radioButtonDidClicked() {
        cardViewUseCase = .radio
    }
    // MARK: - Broadcast
    private func setupBroadcastMicrophoneCaptureCallback(channelID: String) {
        broadcastMicrophoneCaptureCallback = {[weak self, channelID] audioData in
            guard let self = self else { return }
            // TODO: Send data through UDPSocket
            self.udpSocketManager.broadcastBufferData(audioData, from: "", to: channelID)
        }
    }
    
    private func removeBroadcastMicrophoneCaptureCallback() {
        broadcastMicrophoneCaptureCallback = nil
    }
    
    func requestForBroadcastChannelWith(_ channelID: String) {
        showBroadcastPermissionAlert = isRecording
        guard !showBroadcastPermissionAlert else { return }
        broadcastChannelWith(channelID)
    }
    
    func keepRecordingWithBroadcastWithId(_ channelID: String) {
        // Keep Recording
        // Broadcast
        broadcastChannelWith(channelID)
    }
    
    private func broadcastChannelWith(_ channelID: String) {
        isBroadcasting = true
        
        DispatchQueue.global().async {
            // Request the task assertion and save the ID.
            if self.broadcastingBackgroundTaskID == nil {
                self.broadcastingBackgroundTaskID = UIApplication.shared.beginBackgroundTask (withName: "BroadcastingBackgroundTask") {
                    // End the task if time expires.
                    UIApplication.shared.endBackgroundTask(self.broadcastingBackgroundTaskID!)
                    self.broadcastingBackgroundTaskID = UIBackgroundTaskIdentifier.invalid
                }
            }
            // 1. Request Microphone
            self.urAudioEngineInstance.requestRecordPermissionAndStartTappingMicrophone {[weak self, channelID] isGranted in
                guard let self = self else { return }
                if isGranted {
                    // 2. setupBroadcastEnviriment
                    self.urAudioEngineInstance.setupAudioEngineEnvironmentForCaptureAudioData()
                    // 3. Connect and send audio buffer
                    self.udpSocketManager.setupBroadcastConnection {
                        self.setupBroadcastMicrophoneCaptureCallback(channelID: channelID)
                    }
                } else {
                    print("Show Alert View")
                    // TODO: Show Alert View
                    // Broadcast state
                    DispatchQueue.main.async {[weak self] in
                        guard let self = self else { return }
                        self.isBroadcasting = false
                    }
                    guard self.broadcastingBackgroundTaskID != nil else { return }
                    // End the task assertion.
                    UIApplication.shared.endBackgroundTask(self.broadcastingBackgroundTaskID!)
                    self.broadcastingBackgroundTaskID = UIBackgroundTaskIdentifier.invalid
                    
                }
            }
        }
    }
    
    func stopBroadcastChannelWith(_ channelID: String) {
        // Broadcast state
        isBroadcasting = false
        
        if isRecording {
            // Keep AudioEngine Alive
        } else {
            // Stop AudioEngine
            urAudioEngineInstance.stopCaptureAudioData()
        }
        removeBroadcastMicrophoneCaptureCallback()
        // Stop Socket
        udpSocketManager.stopBroadcastConnection()
        
        // Map
        
        DispatchQueue.global().async {
            guard self.broadcastingBackgroundTaskID != nil else { return }
            // End the task assertion.
            UIApplication.shared.endBackgroundTask(self.broadcastingBackgroundTaskID!)
            self.broadcastingBackgroundTaskID = UIBackgroundTaskIdentifier.invalid
        }
    }
    
    // MARK: - Subscription
    func subscribeAllEvent() {
        SubscribeManager.shared.delegate = self
        
        SubscribeManager.shared.setupWith("test1234")
        
    }
    
    func requestForSubscribeChannel() {
        showSubscribePermissionAlert = playingData != nil
        guard !showSubscribePermissionAlert else { return }
        subscribeChannel()
    }
    
    func stopPlayingOnFileThenSubscribeChannel() {
        // Stop file on playing and display
        fileListOnStop()
        // Subscribe Channel
        subscribeChannel()
    }
    
    private func subscribeChannel() {
        self.isSubscribing = true
        // 1. setupSubscribeEnviriment
        DispatchQueue.global().async {
            // Request the task assertion and save the ID.
            if self.subscribingBackgroundTaskID == nil {
                self.subscribingBackgroundTaskID = UIApplication.shared.beginBackgroundTask (withName: "SubscribingingBackgroundTask") {
                    // End the task if time expires.
                    UIApplication.shared.endBackgroundTask(self.subscribingBackgroundTaskID!)
                    self.subscribingBackgroundTaskID = UIBackgroundTaskIdentifier.invalid
                }
            }
            self.urAudioEngineInstance.setupAudioEngineEnvironmentForScheduleAudioData()
            
            self.udpSocketManager.setupSubscribeConnection {[weak self] result in
                guard let self = self else { return }
                switch result {
                case .success(_):
                    self.udpSocketManager.subscribeChannel(from: "", with: self.subscribeID)
                    
                case .failure(let error):
                    DispatchQueue.main.async {
                        self.isSubscribing = false
                    }
                    print("Setup Subscribe Connection with error: \(error)")
                    // End the task assertion.
                    guard self.subscribingBackgroundTaskID != nil else { return }
                    UIApplication.shared.endBackgroundTask(self.subscribingBackgroundTaskID!)
                    self.subscribingBackgroundTaskID = UIBackgroundTaskIdentifier.invalid
                }
            }
        }
    }
    
    func stopSubscribeChannel() {
        self.isSubscribing = false
        print("Stop Subscribing")
        // Socket
        self.udpSocketManager.unsubscribeChannel(from: "", with: self.subscribeID)
        // AudioEngine
        urAudioEngineInstance.stopScheduleAudioData()
        // Clear DistanceAndDirectionView
        clearDirectionAndDistanceMetersView()
        // Map
        removeAnnotionOnMap()
        // Background Task
        DispatchQueue.global().async {
            guard self.subscribingBackgroundTaskID != nil else { return }
            // End the task assertion.
            UIApplication.shared.endBackgroundTask(self.subscribingBackgroundTaskID!)
            self.subscribingBackgroundTaskID = UIBackgroundTaskIdentifier.invalid
            
        }
    }
    // MARK: - Record
    func recordButtonDidClicked() {
        cardViewUseCase = .record
    }
    private func setupRecordingMicrophoneCaptureCallback(){
        recordingMicrophoneCaptureCallback = {[weak self] audioData in
            guard let self = self else { return }
            // TODO: Send data through UDPSocket
            self.recordingHelper.schechuleURAudioBuffer(audioData)
        }
    }
    
    func requestForRecording() {
        showRecordingPermissionAlert = isBroadcasting
        guard !showRecordingPermissionAlert else { return }
        startURRecordingSession()
    }
    
    func keepBroadcastWhileRecording() {
        // TODO: Make sure the engine will not crash
        startURRecordingSession()
    }
    
    private func startURRecordingSession() {
        isRecording = true
        
        DispatchQueue.global().async {
            // Request the task assertion and save the ID.
            if self.recordingBackgroundTaskID == nil {
                self.recordingBackgroundTaskID = UIApplication.shared.beginBackgroundTask (withName: "RecordingBackgroundTask") {
                    // End the task if time expires.
                    UIApplication.shared.endBackgroundTask(self.recordingBackgroundTaskID!)
                    self.recordingBackgroundTaskID = UIBackgroundTaskIdentifier.invalid
                }
            }
            // 1. Request Microphone
            self.urAudioEngineInstance.requestRecordPermissionAndStartTappingMicrophone {[weak self] isGranted in
                guard let self = self else { return }
                if isGranted {
                    // 2. setupRecordingEnviriment
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
                    self.isRecording = false
                }
            }
        }
    }
    
    func stopURRecordingSession() {
        urAudioEngineInstance.stopCaptureAudioData()
        
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
        #warning("Stop engine")
        
        DispatchQueue.global().async {
            guard self.recordingBackgroundTaskID != nil else { return }
            // End the task assertion.
            UIApplication.shared.endBackgroundTask(self.recordingBackgroundTaskID!)
            self.recordingBackgroundTaskID = UIBackgroundTaskIdentifier.invalid
        }
        
        isRecording = false
    }
    // MARK: - Filelist
    func fileButtonDidClicked() {
        cardViewUseCase = .file
    }
    
    func fileListOnDelete(_ recordedData: RecordedData) {
        PersistenceController.shared.deleteRecordedData(recordedData)
    }
    
    func fileListOnSelected(_ expandedData: RecordedData?) {
        
        self.expandedData = expandedData
        
        if let displayData = expandedData{
            displayRecordedDataOnMap(displayData)
        }
        // Stop the last expandedData on playing
        if expandedData != playingData {
            fileListOnStop()
        }
    }
    
    func requestFileOnPlaying(_ playingData: RecordedData?) {
        showPlayingPermissionAlert = isSubscribing
        guard !showPlayingPermissionAlert else { return }
        fileOnPlaying(playingData)
    }
    
    func stopSubscriptionAndPlaying(_ playingData: RecordedData?) {
        // Stop subscription
        stopSubscribeChannel()
        // Playing Data
        fileOnPlaying(playingData)
    }
    
    private func fileOnPlaying(_ playingData: RecordedData?) {
        
        if let pauseData = pauseData,  (pauseData == playingData) {
            print("Playing pause data")
            // TODO: get Puase Duration and setup Player
            self.playingData = pauseData
        } else {
            print("Play")
            
            // Reset the last playing data
            self.playingData?.playingDuration = 0
            self.pauseData?.playingDuration = 0
            
            self.pauseData = nil
            
            self.playingData = playingData
        }
        // 2 Parse and schechule in audioengine
        guard let playingData = playingData,
              let file = playingData.file else { return }
        
        let playingDuration = playingData.playingDuration
        
        let urAudioData = URRecordingDataHelper.parseURAudioData(file)
        
        DispatchQueue.global().async { [weak self] in
            guard let self = self else { return }
            // Request the task assertion and save the ID.
            if self.playingBackgroundTaskID == nil {
                self.playingBackgroundTaskID = UIApplication.shared.beginBackgroundTask (withName: "PlayingBackgroundTask") {
                    // End the task if time expires.
                    UIApplication.shared.endBackgroundTask(self.playingBackgroundTaskID!)
                    self.playingBackgroundTaskID = UIBackgroundTaskIdentifier.invalid
                }
            }
        }
        
        self.startDeviceMotionDetection()
        
        self.urAudioEngineInstance.setupPlayerDataAndStartPlayingAtSeconds(urAudioData, startOffset: playingDuration, updateInterval: 1) { updatedDuration in
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
                
                self.removeAnnotionOnMap()
            }
            // AudioEngine
            self.urAudioEngineInstance.removePlayerData()
            
            self.urAudioEngineInstance.stopScheduleAudioData()
            
            DispatchQueue.global().async { [weak self] in
                guard let self = self else { return }
                // End the task assertion.
                guard self.playingBackgroundTaskID != nil else { return }
                UIApplication.shared.endBackgroundTask(self.playingBackgroundTaskID!)
                self.playingBackgroundTaskID = UIBackgroundTaskIdentifier.invalid
            }
        }
        
        // 3. SetUp engine environment
        self.urAudioEngineInstance.setupAudioEngineEnvironmentForScheduleAudioData()
        
    }
    
    func fileListOnPause() {
        print("Pause")
        // TODO: record pause duration
        self.pauseData = self.playingData
        self.playingData = nil
        self.urAudioEngineInstance.removePlayerData()
        
        // AudioEngine
        urAudioEngineInstance.stopScheduleAudioData()
        
        DispatchQueue.global().async { [weak self] in
            guard let self = self else { return }
            // End the task assertion.
            guard self.playingBackgroundTaskID != nil else { return }
            UIApplication.shared.endBackgroundTask(self.playingBackgroundTaskID!)
            self.playingBackgroundTaskID = UIBackgroundTaskIdentifier.invalid
        }
    }
    
    func fileListOnStop() {
        print("Stop")
        // TODO: record pause duration
        self.pauseData = nil
        self.playingData = nil
        self.expandedData?.playingDuration = 0
        self.urAudioEngineInstance.removePlayerData()
        self.clearRoutesButtonDidClicked()
        
        // AudioEngine
        urAudioEngineInstance.stopScheduleAudioData()
        
        DispatchQueue.global().async { [weak self] in
            guard let self = self else { return }
            // End the task assertion.
            guard self.playingBackgroundTaskID != nil else { return }
            UIApplication.shared.endBackgroundTask(self.playingBackgroundTaskID!)
            self.playingBackgroundTaskID = UIBackgroundTaskIdentifier.invalid
        }
    }
    // MARK: - DirectionAndDistanceMetersView
    func clearDirectionAndDistanceMetersView() {
        udpsocketLatenctMs = 0
        receiverLastDirectionDegrees = 0
        receiverLastDistanceMeters = 0
    }
    // MARK: - Map
    func locateButtonDidClicked() {
        isLocationLocked.toggle()
    }
    
    private func removeAnnotionOnMap() {
        self.removeAnnotationItems.append(receiverAnnotationItem)
        
        self.receiverAnnotationItem = HomeMapAnnotation(coordinate: CLLocationCoordinate2D(), color: .clear)
    }
    
    func clearRoutesButtonDidClicked() {
        removeRoutes = displayRoutes
        removeAnnotionOnMap()
        displayRoutes.removeAll()
    }
    
    private func displayRecordedDataOnMap(_ displayData: RecordedData) {
        // Check cache
        for data in cacheRoutes {
            if data == displayData {
                // 1. Parse URAudioBuffers in locatinos
                guard let data = displayData.file else { return }
                
                let urAudioData = URRecordingDataHelper.parseURAudioData(data)
                
                let buffersLocation: [CLLocationCoordinate2D] = urAudioData.audioBuffers.filter { buffer->Bool in
                    buffer.metadata != nil
                }.map { buffer in
                    return CLLocationCoordinate2D(latitude: buffer.metadata!.locationCoordinate.latitude,
                                                  longitude: buffer.metadata!.locationCoordinate.longitude)
                }
                
                guard let startLocation = buffersLocation.first, let routes = displayData.routes else { continue }
                
                self.displayRoutesOnMap(centerLocation: startLocation, routes: routes)
                return
            }
        }
        // No routes cache
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
                guard let startLocation = buffersLocation.first else { return }
                DispatchQueue.main.async {
                    self.displayRoutesOnMap(centerLocation: startLocation, routes: routes)
                    // Cache generated routes
                    displayData.routes = routes
                }
                self.cacheRoutes.append(displayData)
            case .failure(let error):
                print(error)
            }
        }
    }
    
    private func displayRoutesOnMap(centerLocation: CLLocationCoordinate2D, routes: [MKRoute]) {
        //Remove the last routes
        self.removeRoutes = self.displayRoutes
        self.displayRoutes = routes
        // Clear the last display
        removeAnnotionOnMap()
        
        print(routes)
        self.isLocationLocked = false
        self.updateByMapItem = true
        let camera = MKMapCamera()
        camera.centerCoordinate = centerLocation
        // TODO: Calculate the camera needed distance
        camera.centerCoordinateDistance = 3000
        self.userCurrentMapCamera = camera
    }
    
    // MARK: - DirectionAndDistanceView
    func compassButtonDidClicked() {
        isShowingDirectionAndDistanceView = true
    }
    
    func compassButtonDidClosed() {
        isShowingDirectionAndDistanceView = false
    }
    
    func setStaticDistance() {
        isSetStaticDistanceMeters.toggle()
        
        urAudioEngineInstance.setStaticDistanceWithListener(isSetStaticDistanceMeters ? receiverLastDistanceMeters : nil)
    }
    
    func resetAnchorDegrees() {
        firstAnchorMotionCompassDegrees = nil
        firstAnchorMotion = nil
        userTrueNorthURMotionAttitude = URMotionAttitude()
    }
    // MARK: - Unspecify
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
    
    @objc func handleUDPSocketConnectionLatency(notification: Notification) {
        guard let msSecond = notification.userInfo?["millisecond"] as? UInt64 else { return }
        udpsocketLatenctMs = msSecond
    }
    
    // MARK: - SegmentSlideOverCard
    func segmentSlideOverCardDidClose() {
        cardViewUseCase = nil
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
        userLocation = locationCoordinate
        // Update UserAnnotion
        DispatchQueue.main.async {[weak self] in
            guard let self = self, let userLocation = self.userLocation, let userHeadingDegrees = self.userHeadingDegrees else { return }
            
            self.userAnootion = HomeMapAnnotation(coordinate: userLocation, userHeadingDegrees: userHeadingDegrees, type: .user, color: .blue)
        }
        
        if userURLocation != nil {
            userURLocation!.latitude = latitude
            userURLocation!.longitude = longitude
            userURLocation!.altitude = altitude
        } else {
            userURLocation = URLocationCoordinate3D(latitude: latitude, longitude: longitude, altitude: altitude)
            print("latitude: \(latitude), longitude: \(longitude)")
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
        
        userHeadingDegrees = isLocationLocked ? 0 : newHeading.trueHeading
        // Update UserAnnotion
        DispatchQueue.main.async {[weak self] in
            guard let self = self, let userLocation = self.userLocation, let userHeadingDegrees = self.userHeadingDegrees else { return }
            
            self.userAnootion = HomeMapAnnotation(coordinate: userLocation, userHeadingDegrees: userHeadingDegrees, type: .user, color: .blue)
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Location Manager Did Fail With Error: \(error.localizedDescription)")
    }
    func headphoneMotionManagerDidDisconnect(_ manager: CMHeadphoneMotionManager) {
        print("headphoneMotionManagerDidDisconnect")
    }
    
    func reloadCurrentUserTrueNorthURMotionAttitude() {
        guard let anchorMotion = firstAnchorMotion,
              let firstAnchorMotionCompassDegrees = firstAnchorMotionCompassDegrees,
              let motion = headphoneMotionManager.deviceMotion else {
                  firstAnchorMotionCompassDegrees = compassDegrees
                  firstAnchorMotion = headphoneMotionManager.deviceMotion
                  return}
        
        
        let trueNorthYawDegrees = (anchorMotion.attitude.yaw - motion.attitude.yaw) / Double.pi * 180 - firstAnchorMotionCompassDegrees
        let trueNorthPitchDegrees = (anchorMotion.attitude.pitch - motion.attitude.pitch) / Double.pi * 180
        let trueNorthRollDegrees = (anchorMotion.attitude.roll - motion.attitude.roll) / Double.pi * 180
        
        userTrueNorthURMotionAttitude?.rollDegrees = trueNorthRollDegrees
        userTrueNorthURMotionAttitude?.pitchDegrees = trueNorthPitchDegrees
        userTrueNorthURMotionAttitude?.yawDegrees = trueNorthYawDegrees
    }
}
// URAudioEngineDataSource
extension HomeMapViewModel: URAudioEngineDataSource {
    func urAudioEngine(currentLocationForEngine: URAudioEngine) -> URLocationCoordinate3D? {
        return userURLocation
    }
    
    func urAudioEngine(currentTrueNorthAnchorsMotionForEngine: URAudioEngine) -> URMotionAttitude? {
        
        reloadCurrentUserTrueNorthURMotionAttitude()
        
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
            
            self.receiverAnnotationItem = HomeMapAnnotation(coordinate: CLLocationCoordinate2D(latitude: receiverLatitude, longitude: receiverLongitude), type: .receiver, color: .orange)
        }
        
        guard let userURLocation = userURLocation else {print("Fail in getting userURLocation"); return }
        
        let directionAndDistance = userURLocation.distanceAndDistance(from: metaData.locationCoordinate)
        DispatchQueue.main.async {[weak self, directionAndDistance] in
            guard let self = self else { return }
            self.receiverLastDirectionDegrees = directionAndDistance.direction
            guard !self.isSetStaticDistanceMeters else { return }
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
        if cardViewUseCase == .record {
            DispatchQueue.main.async {[weak self] in
                self?.recordDuration = seconds
            }
        }
    }
    
    func didUpdateAudioRecordingMovingDistance(_ meters: Double) {
        if cardViewUseCase == .record {
            DispatchQueue.main.async {[weak self] in
                self?.recordMovingDistance = meters
            }
        }
    }
}

enum CardViewUseCase {
    case radio
    case record
    case file
    
    var cardAvailableMode: AvailablePosition {
        switch self {
        case .radio:
            return AvailablePosition([.bottom, .middle])
        case .record:
            return AvailablePosition([.bottom])
        case .file:
            return AvailablePosition([.bottom, .middle, .top])
        }
    }
    
    var firstPosition: CardPosition{
        switch self {
        case .radio:
            return .middle
        case .record, .file:
            return .bottom
        }
    }
}
