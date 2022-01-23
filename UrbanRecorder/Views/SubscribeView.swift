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
    
    @Binding var isConnecting: Bool
    
    @Binding var isShowingAlert: Bool
    
    var requestForSubscribeChannel: (()->Void)
    
    var stopPlayingOnFileAndSubscribeChannel: (()->Void)
    
    var stopSubscribetAction: (()->Void)
    
    var actionString: String {
        isConnecting ? "Disconnect" : "Connect"
    }
    
    let alertMessage: String = "Stop the file on playing?"
    
    var body: some View {
        return ZStack {
                HStack{
                    Text("ChannelID: ").fontWeight(.bold)
                        .customFont(style: .headline, weight: .bold)
                                            .foregroundColor(Color.Neumorphic.secondary)
                                            .lineLimit(1)
                                            .padding(5)
                    if isConnecting {
                        TextField.init("", text: $channelID, prompt: nil).disabled(true)
                            .customFont(style: .subheadline, weight: .light)
                            .foregroundColor(Color.Neumorphic.secondary)
                    } else {
                        TextField.init("", text: $channelID, prompt: nil).disabled(false)
                            .customFont(style: .subheadline, weight: .light)
                            .foregroundColor(Color.Neumorphic.secondary)
                    }
                    
                    Button {
                        if isConnecting {
                            stopSubscribetAction()
                        } else {
                            // Request subscribe
                            requestForSubscribeChannel()
                        }
                    } label: {
                        Text(actionString)
                            .customFont(style: .footnote, weight: .heavy)
                            .foregroundColor(Color.Neumorphic.secondary)
                            .lineLimit(1)
                            .frame(height: 30)
                            .padding(EdgeInsets(top: 0, leading: 5, bottom: 0, trailing: 5))
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
        SubscribeView(channelID: .constant("Test"), isConnecting: .constant(false), isShowingAlert: .constant(false), requestForSubscribeChannel: {}, stopPlayingOnFileAndSubscribeChannel: {}, stopSubscribetAction: {})
    }
}
