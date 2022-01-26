# RoundRecorder

RoundRecorder 提供同時擷取**音訊和地理資訊**的**錄製**與**廣播**功能，在播放音訊時同步讀取地理資訊，並依據播放者當時下的地理位置模擬出**空間音訊**。使用支援空間音訊的耳機（AirPods Pro, AirPods Max, AirPods (3rd generation), etc.）能依據使用者的移動與轉向更新**立體音訊**，進而達到更沈浸式的體驗。
透過地圖與指針能獲得**廣播者**或**錄製音檔**即時的地理資訊。

RoundRecorder provides ability for **recording** and **broadcasting** the **audio** with **geographic information** simultaneously. Use a headphone that supports to play with **spatial audio**(AirPods Pro, AirPods Max, AirPods (3rd generation), etc.) can enable the ability of playing **spatial audio** according to the user's motion for a more immersive experience.
Real-time geographic information can be provide by map and pointer.
## Feature
### Radio
- 透過建立廣播頻道發布音訊與定位

    <img src="https://github.com/Holadddd/RoundRecorder/blob/master/RoundRecorder/Gif/Broadcast.gif" width="200"> <img src="https://github.com/Holadddd/RoundRecorder/blob/master/RoundRecorder/Gif/Subscription.gif" width="200"> 

### Recorder & Filestorage
- 編輯檔名並錄製

    <img src="https://github.com/Holadddd/RoundRecorder/blob/master/RoundRecorder/Gif/Recorder.gif" width="200">

- 顯示錄製路線與播放

    <img src="https://github.com/Holadddd/RoundRecorder/blob/master/RoundRecorder/Gif/Player.gif" width="200">
    
### Compass
- 顯示廣播定位

    <img src="https://github.com/Holadddd/RoundRecorder/blob/master/RoundRecorder/Gif/Radio.gif" width="200">
    
- 重新校正耳機空間定位

### Map
- 同步使用者方位
- 清除路徑


## Requirement

- Swift 5
- 📱 iOS 15 or above

## Capabilitis Requirement

| Key | Usage |
| -------- | -------- |
| Privacy - Motion Usage Description| RoundRecorder requires motion information for better user experience.|
| Privacy - Microphone Usage Description| RoundRecorder requires microphone access to record or broadcast audio. |
| Privacy - Location Always and When In Use Usage Description| RoundRecorder requires user’s location for better user experience.|
| Privacy - Location When In Use Usage Description| RoundRecorder requires user’s location for better user experience.|

## Dependency
### Swift Package Manager
- [SocketIO-16.0.0](https://github.com/socketio/socket.io-client-swift.git)
- [CocoaAsyncSocket-7.6.5](https://github.com/robbiehanson/CocoaAsyncSocket)
- [Neumorphic-RecorderExtension](https://github.com/Holadddd/neumorphic)
## Build ⚒

You need the latest Xcode and macOS. Xcode 12 and macOS Catalina 10.15. 4 or later are recommended.

## Contacts
Ting Hui WU

wu19931221@gmail.com