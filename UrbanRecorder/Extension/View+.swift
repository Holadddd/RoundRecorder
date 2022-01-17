//
//  View+.swift
//  UrbanRecorder
//
//  Created by ting hui wu on 2021/10/22.
//

import SwiftUI
import Neumorphic

extension View {
    func expandHorizontally() -> some View {
        frame(maxWidth: .infinity)
    }
    func expandVertically() -> some View {
        frame(maxHeight: .infinity)
    }
    func show(isVisible: Bool) -> some View {
        ModifiedContent(content: self, modifier: Show(isVisible: isVisible))
    }
    func segmentCardView(title: String) -> some View {
        ModifiedContent(content: self, modifier: SegmentCardView(title: title))
    }
}

struct Show: ViewModifier {
    let isVisible: Bool

    @ViewBuilder
    func body(content: Content) -> some View {
        if isVisible {
            content
        } else {
            content.hidden()
                .frame(width: 0.1, height: 0.1)
        }
    }
}


struct SegmentCardView: ViewModifier {
    let title: String
    @ViewBuilder
    func body(content: Content) -> some View {
        
        VStack(alignment: .leading) {
            Text(title).font(.system(size: 14, weight: .bold)).foregroundColor(Color.Neumorphic.secondary)
            content
                .background(Color.Neumorphic.main)
                .cornerRadius(10)
                .softOuterShadow()
        }
    }
}
