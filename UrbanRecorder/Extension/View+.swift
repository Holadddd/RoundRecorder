//
//  View+.swift
//  UrbanRecorder
//
//  Created by ting hui wu on 2021/10/22.
//

import SwiftUI

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
