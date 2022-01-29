# RoundRecorder

RoundRecorder 提供同時擷取音訊和地理資訊的 **錄製(廣播)** 與 **播放(訂閱)** 功能，在播放音訊時同步讀取地理資訊，並依據播放者當時下的地理位置模擬出**空間音訊**。使用支援空間音訊的耳機（AirPods Pro, AirPods Max, AirPods (3rd generation), etc.）能依據使用者的移動與轉向更新空間音訊，進而獲得更沈浸式的體驗。

RoundRecorder provides the ability to simultaneously **record(Broadcast)** and **play(Subscribe)** audio with geographic information. Using headphones that support playback of **spatial audio** (AirPods Pro, AirPods Max, AirPods (3rd generation), etc.) can play spatial audio based on the user's motion for a more immersive experience.
## Feature
### Radio
- This feature provides user subscribing the channel with the exact location where the broadcast user is broadcasting

    <img src="https://github.com/Holadddd/RoundRecorder/blob/master/RoundRecorder/Gif/Broadcast.gif" width="200"> <img src="https://github.com/Holadddd/RoundRecorder/blob/master/RoundRecorder/Gif/Subscription.gif" width="200"> 

### Recorder & Filestorage
- The recorder provides the ability to simultaneously record audio with geographic information.

    <img src="https://github.com/Holadddd/RoundRecorder/blob/master/RoundRecorder/Gif/Recorder.gif" width="200">

- When the user is playing the recorded file, the map will show the exact location where the user recorded this audio file.

    <img src="https://github.com/Holadddd/RoundRecorder/blob/master/RoundRecorder/Gif/Player.gif" width="200">
    
### Compass
- The compass will show the real distance and direction based on where the user played audio or where the user subscribe the channel.

    <img src="https://github.com/Holadddd/RoundRecorder/blob/master/RoundRecorder/Gif/Radio.gif" width="200">
    
- Adjust the relative position of the headphone and the mobile phone to the same heading 

    <img src="https://github.com/Holadddd/RoundRecorder/blob/master/RoundRecorder/Gif/Correction.png" width="200">
    
### Map
- Tracking on User's heading 

    <img src="https://github.com/Holadddd/RoundRecorder/blob/master/RoundRecorder/Gif/Heading.gif" width="200">

- Clear the route display on the map

    <img src="https://github.com/Holadddd/RoundRecorder/blob/master/RoundRecorder/Gif/ClearRoute.gif" width="200">


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
