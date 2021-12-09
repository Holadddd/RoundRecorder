//
//  RecorderView.swift
//  UrbanRecorder
//
//  Created by ting hui wu on 2021/12/5.
//

import SwiftUI
import Neumorphic

struct RecorderView: View {
    
    var recordDidClicked: (()->Void)
    
    @Binding var isRecordButtonPressed: Bool
    
    @Binding var recordDuration: UInt
    
    @Binding var movingDistance: Double
    
    @Binding var recordName: String
    
    var recorderLocation: URLocationCoordinate3D?
    
    var body: some View {
        
        return VStack {
            HStack {
                TextField.init("",
                               text: $recordName,
                               prompt: Text("\(getDefaultRecordName())"))
                    .fixedSize()
            }.padding(0)
            
            ZStack {
                HStack(alignment: .center) {
                    VStack(alignment: .leading) {
                        Text("Distance: \(movingDistance.string(fractionDigits: 1)) m")
                            .fontWeight(.thin)
                            .foregroundColor(Color.Neumorphic.secondary)
                        Text("Time: \(getRecorderTimeFormat(recordDuration))")
                            .fontWeight(.thin)
                            .foregroundColor(Color.Neumorphic.secondary)
                        
                    }.padding(EdgeInsets(top: 0,
                                         leading: 10,
                                         bottom: 0,
                                         trailing: 0))
                    Spacer()
                }
                
                Button {
                    checkFileNaming()
                    recordDidClicked()
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
            }
        }
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
    
    private func getDefaultRecordName() -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MM-dd_HH:mm"
        
        
        return dateFormatter.string(from: Date())
    }
    
    private func checkFileNaming() {
        if recordName == "" {
            recordName = getDefaultRecordName()
        }
    }
}

struct RecorderView_Previews: PreviewProvider {
    static var previews: some View {
        RecorderView(recordDidClicked: {
            
        }, isRecordButtonPressed: .constant(false), recordDuration: .constant(0), movingDistance: .constant(5.5), recordName: .constant(""), recorderLocation: URLocationCoordinate3D(latitude: 121.1, longitude: 25.4, altitude: 0))
    }
}
