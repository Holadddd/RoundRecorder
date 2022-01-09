//
//  SubscribeView.swift
//  UrbanRecorder
//
//  Created by ting hui wu on 2021/12/5.
//

import SwiftUI
import Neumorphic

struct SubscribeView: View {
    
    @Binding var channelID: String
    
    @Binding var isSubscribing: Bool
    
    var subscribetAction: (()->Void)
    
    var stopSubscribetAction: (()->Void)
    
    var body: some View {
        return VStack{
            HStack{
                Text("ChannelID: ").fontWeight(.bold)
                    .foregroundColor(Color.Neumorphic.secondary)
                if isSubscribing {
                    TextField.init("SubscribeChannelID", text: $channelID, prompt: nil).disabled(true)
                } else {
                    TextField.init("SubscribeChannelID", text: $channelID, prompt: nil).disabled(false)
                }
                
                Button(isSubscribing ? "Stop" : "Subscribe") {
                    if isSubscribing {
                        stopSubscribetAction()
                    } else {
                        subscribetAction()
                    }
                }.softButtonStyle(RoundedRectangle(cornerRadius: 5), padding: 3, textColor: Color.Neumorphic.secondary, pressedEffect: .hard)
                    .padding()
            }
        }
    }
}

struct SubscribeView_Previews: PreviewProvider {
    static var previews: some View {
        SubscribeView(channelID: .constant("1234"), isSubscribing:.constant(false) ,subscribetAction: {
            
        }, stopSubscribetAction: { })
    }
}
