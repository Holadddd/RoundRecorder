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
    
    @Binding var isConnecting: Bool
    
    @Binding var isShowingAlert: Bool
    
    var requestForBroadcastWithId: ((String)->Void)
    
    var keepRecordingWithBroadcastWithId: ((String)->Void)
    
    var stopBroadcastAction: (String)->()
    
    var actionString: String {
        isConnecting ? "Disconnect" : "Connect"
    }
    
    let alertMessage: String = "Broadcast while recording?"
    
    var body: some View {
        return ZStack {
            HStack{
                Text("ChannelID: ")
                    .customFont(style: .headline, weight: .bold)
                                        .foregroundColor(Color.Neumorphic.secondary)
                                        .lineLimit(1)
                                        .padding(5)
                // Prvent Modifying state during view update
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
                        stopBroadcastAction(channelID)
                    } else {
                        requestForBroadcastWithId(channelID)
                    }
                } label: {
                    Text(actionString)
                        .customFont(style: .footnote, weight: .heavy)
                        .foregroundColor(Color.Neumorphic.secondary)
                        .lineLimit(1)
                        .frame(height: 30)
                        .padding(EdgeInsets(top: 0, leading: 5, bottom: 0, trailing: 5))
                }.softButtonStyle(RoundedRectangle(cornerRadius: 10), padding: 3, textColor: Color.Neumorphic.secondary, pressedEffect: .hard)
                    .padding()
                    .alert(alertMessage, isPresented: $isShowingAlert) {
                        Button("No", role: .cancel) {
                            print("Keep recording with file")
                        }
                        Button("Yes", role: .destructive) {
                            keepRecordingWithBroadcastWithId(channelID)
                        }
                    }
            }.segmentCardView(title: "Broadcast")
            
        }.padding(10)
    }
}

struct BroadcastView_Previews: PreviewProvider {
    static var previews: some View {
        BroadcastView(channelID: .constant("Test"), isConnecting: .constant(false), isShowingAlert: .constant(false), requestForBroadcastWithId: {_ in}, keepRecordingWithBroadcastWithId: {_ in}, stopBroadcastAction: {_ in})
    }
}
