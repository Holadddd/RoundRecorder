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
    
    @Binding var isShowingAlert: Bool
    
    var requestForSubscribeChannel: (()->Void)
    
    var stopPlayingOnFileAndSubscribeChannel: (()->Void)
    
    var stopSubscribetAction: (()->Void)
    
    let alertMessage: String = "Stop the file on playing?"
    
    var body: some View {
        return ZStack {
                HStack{
                    Text("ChannelID: ").fontWeight(.bold)
                        .foregroundColor(Color.Neumorphic.secondary)
                        .padding(5)
                    if isSubscribing {
                        TextField.init("", text: $channelID, prompt: nil).disabled(true)
                    } else {
                        TextField.init("", text: $channelID, prompt: nil).disabled(false)
                    }
                    
                    Button(isSubscribing ? "Stop" : "Subscribe") {
                        if isSubscribing {
                            stopSubscribetAction()
                        } else {
                            // Request subscribe
                            requestForSubscribeChannel()
                        }
                    }.softButtonStyle(RoundedRectangle(cornerRadius: 5), padding: 3, textColor: Color.Neumorphic.secondary, pressedEffect: .hard)
                        .padding()
                        .alert(alertMessage, isPresented: $isShowingAlert) {
                            Button("No", role: .cancel) {
                                print("Keep playing with file")
                            }
                            Button("Yes", role: .destructive) {
                                stopPlayingOnFileAndSubscribeChannel()
                            }
                        }
                }.segmentCardView(title: "Subscribe")
        }.padding(10)
    }
}

struct SubscribeView_Previews: PreviewProvider {
    static var previews: some View {
        SubscribeView(channelID: .constant("Test"), isSubscribing: .constant(false), isShowingAlert: .constant(false), requestForSubscribeChannel: {}, stopPlayingOnFileAndSubscribeChannel: {}, stopSubscribetAction: {})
    }
}
