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
    
    var broadcastAction: (String)->()
    
    var stopBroadcastAction: (String)->()
    
    var body: some View {
        return HStack{
            Text("ChannelID: ").fontWeight(.bold)
                .foregroundColor(Color.Neumorphic.secondary)
            TextField.init("BroadcastChannelID", text: $channelID, prompt: nil).disabled(isBroadcasting)
            Button(isBroadcasting ? "Stop" : "Broadcast") {
                if isBroadcasting {
                    stopBroadcastAction(channelID)
                } else {
                    broadcastAction(channelID)
                }
            }.softButtonStyle(RoundedRectangle(cornerRadius: 5), padding: 3, textColor: Color.Neumorphic.secondary, pressedEffect: .hard)
                .padding()
        }
    }
}

struct BroadcastView_Previews: PreviewProvider {
    static var previews: some View {
        BroadcastView(channelID: .constant("TEST"), isBroadcasting: .constant(false), broadcastAction: { _ in
            
        }, stopBroadcastAction: { _ in
            
        })
    }
}
