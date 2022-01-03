//
//  BoradcastView.swift
//  UrbanRecorder
//
//  Created by ting hui wu on 2021/12/5.
//

import SwiftUI
import Neumorphic

struct BoradcastView: View {
    @Binding var channelID: String
    
    var broadcastAction: ()->()
    
    var body: some View {
        return HStack{
            Text("ChannelID: ").fontWeight(.bold)
                .foregroundColor(Color.Neumorphic.secondary)
            TextField.init("BroadcastChannelID", text: $channelID, prompt: nil)
            Button("Broadcast") {
                broadcastAction()
            }.softButtonStyle(RoundedRectangle(cornerRadius: 5), padding: 3, textColor: Color.Neumorphic.secondary, pressedEffect: .hard)
                .padding()
        }
    }
}

struct BoradcastView_Previews: PreviewProvider {
    static var previews: some View {
        BoradcastView(channelID: .constant("TEST"), broadcastAction: {
            
        })
    }
}
