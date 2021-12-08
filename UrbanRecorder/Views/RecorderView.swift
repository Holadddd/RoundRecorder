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
    
    var body: some View {
        return VStack {
            Text(getRecorderTimeFormat(recordDuration))
                .fontWeight(.thin)
                .foregroundColor(Color.Neumorphic.secondary)
            HStack {
                Button {
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
}
 
struct RecorderView_Previews: PreviewProvider {
    static var previews: some View {
        RecorderView(recordDidClicked: {
            
        }, isRecordButtonPressed: .constant(false), recordDuration: .constant(0))
    }
}
