//
//  SubscribeView.swift
//  UrbanRecorder
//
//  Created by ting hui wu on 2021/12/5.
//

import SwiftUI

struct SubscribeView: View {
    
    @Binding var channelID: String
    
    var subscribetAction: (()->Void)
    
    var body: some View {
        return 
        VStack{
            HStack{
                Text("ChannelID: ")
                TextField.init("SubscribeChannelID", text: $channelID, prompt: nil)
                Button("Subscribe") {
                    subscribetAction()
                }.padding()
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
