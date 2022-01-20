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
    func customFont( name: String = "", style: UIFont.TextStyle, weight: Font.Weight = .regular) -> some View {
        self.modifier(CustomFont(name: name, style: style, weight: weight))
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

struct CustomFont: ViewModifier {
    @Environment(\.sizeCategory) var sizeCategory

    var name: String = ""
    var style: UIFont.TextStyle
    var weight: Font.Weight = .regular

    func body(content: Content) -> some View {
        return content.font(Font.custom(
            name,
            size: UIFont.preferredFont(forTextStyle: style).pointSize)
            .weight(weight))
    }
}
