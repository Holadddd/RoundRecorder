//
//  BroadcastView.swift
//  UrbanRecorder
//
//  Created by ting hui wu on 2021/12/5.
//

import SwiftUI
import Neumorphic

struct BroadcastView: View {
    @Binding var channelID: String
    
    @Binding var isBroadcasting: Bool
    
    @Binding var isShowingAlert: Bool
    
    var requestForBroadcastWithId: ((String)->Void)
    
    var keepRecordingWithBroadcastWithId: ((String)->Void)
    
    var stopBroadcastAction: (String)->()
    
    let alertMessage: String = "Broadcast while recording?"
    
    var body: some View {
        return HStack{
            Text("ChannelID: ").fontWeight(.bold)
                .foregroundColor(Color.Neumorphic.secondary)
            // Prvent Modifying state during view update
            if isBroadcasting {
                TextField.init("BroadcastChannelID", text: $channelID, prompt: nil).disabled(true)
            } else {
                TextField.init("BroadcastChannelID", text: $channelID, prompt: nil).disabled(false)
            }
            
            Button(isBroadcasting ? "Stop" : "Broadcast") {
                if isBroadcasting {
                    stopBroadcastAction(channelID)
                } else {
                    requestForBroadcastWithId(channelID)
                }
            }.softButtonStyle(RoundedRectangle(cornerRadius: 5), padding: 3, textColor: Color.Neumorphic.secondary, pressedEffect: .hard)
                .padding()
                .alert(alertMessage, isPresented: $isShowingAlert) {
                    Button("No", role: .cancel) {
                        print("Keep recording with file")
                    }
                    Button("Yes", role: .destructive) {
                        keepRecordingWithBroadcastWithId(channelID)
                    }
                }
        }
    }
}

struct BroadcastView_Previews: PreviewProvider {
    static var previews: some View {
        BroadcastView(channelID: .constant("Test"), isBroadcasting: .constant(false), isShowingAlert: .constant(false), requestForBroadcastWithId: {_ in}, keepRecordingWithBroadcastWithId: {_ in}, stopBroadcastAction: {_ in})
    }
}
