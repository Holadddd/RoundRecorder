//
//  RecorderView.swift
//  UrbanRecorder
//
//  Created by ting hui wu on 2021/12/5.
//

import SwiftUI
import Neumorphic

struct RecorderView: View {
    
    @Binding var isRecordButtonPressed: Bool
    
    @Binding var recordDuration: UInt
    
    @Binding var movingDistance: Double
    
    @Binding var recordName: String
    
    var recorderURLocation: URLocationCoordinate3D?
    
    @Binding var isShowingAlert: Bool
    
    var requestForRecording: (()->Void)
    
    var keepBroadcastWhileRecording: ()->Void
    
    var stopRecording: ()->Void
    
    let alertMessage: String = "Record while broadcasting?"
    
    var body: some View {
        
        return VStack {
            VStack {
                HStack {
                    Spacer()
                    TextField.init("",
                                   text: $recordName,
                                   prompt: Text("\(getDefaultRecordName())")
                    ).customFont(style: .subheadline, weight: .light)
                        .foregroundColor(Color.Neumorphic.secondary)
                    Spacer()
                }.padding(EdgeInsets(top: 10, leading: 3, bottom: 0, trailing: 0))
                
                ZStack {
                    HStack(alignment: .center) {
                        Text("Distance: \(movingDistance.string(fractionDigits: 1)) M")
                            .fontWeight(.light)
                            .foregroundColor(Color.Neumorphic.secondary)
                        Spacer()
                        Text("\(getRecorderTimeFormat(recordDuration))")
                            .fontWeight(.light)
                            .foregroundColor(Color.Neumorphic.secondary)
                    }.padding(0)
                    
                    Button {
                        if isRecordButtonPressed {
                            stopRecording()
                        } else {
                            checkFileNaming()
                            requestForRecording()
                        }
                    } label: {
                        if isRecordButtonPressed {
                            RoundedRectangle(cornerRadius: 5)
                                .frame(width: 40, height: 40)
                                .scaleEffect(0.4)
                                .softOuterShadow()
                        } else {
                            Circle()
                                .frame(width: 40, height: 40)
                                .scaleEffect(0.4)
                                .softOuterShadow()
                        }
                        
                    }
                    .softButtonStyle(RoundedRectangle(cornerRadius: 15), padding: 3, textColor: .red, pressedEffect: .hard, isPressed: self.isRecordButtonPressed)
                    .alert(alertMessage, isPresented: $isShowingAlert) {
                        Button("No", role: .cancel) {
                            print("Pause recording")
                        }
                        Button("Yes", role: .destructive) {
                            keepBroadcastWhileRecording()
                        }
                    }
                }.padding(10)
            }
            
        }.segmentCardView(title: "Recorder")
            .padding(10)
    }
    
    private func getDefaultRecordName() -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MM-dd_HH:mm"
        
        return dateFormatter.string(from: Date())
    }
    
    private func getRecorderTimeFormat(_ seconds: UInt) -> String {
        let timeUnit = seconds.toHoursMinutesSeconds()
        
        let hourUnit = timeUnit.0
        let minuteUnit = timeUnit.1.toTimeUnit()
        let secondUnit = timeUnit.2.toTimeUnit()
        
        if timeUnit.0 > 0 {
            return "\(hourUnit):\(minuteUnit):\(secondUnit)"
        } else {
            return "\(minuteUnit):\(secondUnit)"
        }
    }
    
    private func checkFileNaming() {
        if recordName == "" {
            recordName = getDefaultRecordName()
        }
    }
}

struct RecorderView_Previews: PreviewProvider {
    static var previews: some View {
        RecorderView(isRecordButtonPressed: .constant(false),
                     recordDuration: .constant(0),
                     movingDistance: .constant(5.5),
                     recordName: .constant(""),
                     recorderURLocation: URLocationCoordinate3D(latitude: 121.1, longitude: 25.4, altitude: 0),
                     isShowingAlert: .constant(false),
                     requestForRecording: {},
                     keepBroadcastWhileRecording: {},
                     stopRecording: {})
    }
}
