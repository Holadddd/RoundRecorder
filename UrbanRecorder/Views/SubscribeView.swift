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
    
    var subscribetAction: (()->Void)
    
    var body: some View {
        return 
        VStack{
            HStack{
                Text("ChannelID: ").fontWeight(.bold)
                    .foregroundColor(Color.Neumorphic.secondary)
                
                TextField.init("SubscribeChannelID", text: $channelID, prompt: nil)
                
                Button("Subscribe") {
                    subscribetAction()
                }.softButtonStyle(RoundedRectangle(cornerRadius: 5), padding: 3, textColor: Color.Neumorphic.secondary, pressedEffect: .hard)
                    .padding()
            }
        }
    }
}

struct SubscribeView_Previews: PreviewProvider {
    static var previews: some View {
        SubscribeView(channelID: .constant("1234"), subscribetAction: {
            
        })
    }
}
