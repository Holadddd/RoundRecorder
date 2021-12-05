//
//  Grid+.swift
//  UrbanRecorder
//
//  Created by ting hui wu on 2021/12/5.
//

import SwiftUI
import UniformTypeIdentifiers

struct GridData: Identifiable, Equatable {
    static func == (lhs: GridData, rhs: GridData) -> Bool {
        return lhs.id == rhs.id
    }
    
    let id: Int
    let title: String
    var isShowing: Bool
    let action: (()->Void)?
    
}

struct GridItemButton: View {
    var data: GridData
    
    var body: some View {
        Button {
            data.action?()
        } label: {
            Text(data.title)
                .font(.headline)
                .foregroundColor(.white)
        }.softButtonStyle(RoundedRectangle(cornerRadius: 15))
    }
}
