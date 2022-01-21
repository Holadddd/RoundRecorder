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

struct Arrow: Shape {
    // 1.
    func path(in rect: CGRect) -> Path {
        Path { path in
            let width = rect.width
            let height = rect.height
            
            // 2.
            path.addLines( [
                CGPoint(x: width * 0.4, y: height),
                CGPoint(x: width * 0.4, y: height * 0.4),
                CGPoint(x: width * 0.2, y: height * 0.4),
                CGPoint(x: width * 0.5, y: height * 0.1),
                CGPoint(x: width * 0.8, y: height * 0.4),
                CGPoint(x: width * 0.6, y: height * 0.4),
                CGPoint(x: width * 0.6, y: height)
                
            ])
            // 3.
            path.closeSubpath()
        }
    }
}

