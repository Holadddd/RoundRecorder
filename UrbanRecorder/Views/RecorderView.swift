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
    
    var body: some View {
        return VStack {
            Text("00:00")
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
}
 
struct RecorderView_Previews: PreviewProvider {
    static var previews: some View {
        RecorderView(recordDidClicked: {
            
        }, isRecordButtonPressed: .constant(false))
    }
}
