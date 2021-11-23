//
//  RecorderView.swift
//  UrbanRecorder
//
//  Created by ting hui wu on 2021/10/25.
//

import SwiftUI

struct RecorderView: View {
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        Button("Press to dismiss") {
            dismiss()
        }
        .font(.title)
        .padding()
        .background(Color.black)
    }
}

struct RecorderView_Previews: PreviewProvider {
    static var previews: some View {
        RecorderView()
    }
}
