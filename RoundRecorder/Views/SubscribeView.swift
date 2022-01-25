//
//  SubscribeView.swift
//  RoundRecorder
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
        isConnecting ? I18n.string(.Disconnect) : I18n.string(.Connect)
    }
    
    let alertMessage: String = "\(I18n.string(.StopTheFileOnPlaying))?"
    
    var body: some View {
        return ZStack {
                HStack{
                    Text("\(I18n.string(.ChannelID)): ").fontWeight(.regular)
                        .customFont(style: .headline, weight: .bold)
                                            .foregroundColor(Color.Neumorphic.secondary)
                                            .lineLimit(1)
                                            .padding(5)
                                            .softOuterShadow()
                    if isConnecting {
                        TextField.init("", text: $channelID, prompt: nil).disabled(true)
                            .foregroundColor(Color.Neumorphic.secondary)
                            .customFont(style: .footnote, weight: .heavy)
                            .softOuterShadow()
                    } else {
                        TextField.init("", text: $channelID, prompt: nil).disabled(false)
                            .foregroundColor(Color.Neumorphic.secondary)
                            .customFont(style: .footnote, weight: .heavy)
                            .softOuterShadow()
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
                            .softOuterShadow(offset: 2, radius: 1)
                    }.softButtonStyle(RoundedRectangle(cornerRadius: 10), padding: 3, textColor: Color.Neumorphic.secondary, pressedEffect: .hard)
                        .padding()
                        .alert(alertMessage, isPresented: $isShowingAlert) {
                            Button(I18n.string(.No), role: .cancel) {
                                print("Keep playing with file")
                            }
                            Button(I18n.string(.Yes), role: .destructive) {
                                stopPlayingOnFileAndSubscribeChannel()
                            }
                        }
                }.segmentCardView(title: I18n.string(.Subscribe))
        }.padding(10)
    }
}

struct SubscribeView_Previews: PreviewProvider {
    static var previews: some View {
        SubscribeView(channelID: .constant("Test"), isConnecting: .constant(false), isShowingAlert: .constant(false), requestForSubscribeChannel: {}, stopPlayingOnFileAndSubscribeChannel: {}, stopSubscribetAction: {})
    }
}
