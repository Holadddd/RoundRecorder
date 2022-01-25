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
    func keyboardResponsive() -> ModifiedContent<Self, KeyboardResponsiveModifier> {
        return modifier(KeyboardResponsiveModifier())
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
                .softOuterShadow()
                .padding(5)
            content
                .background(Color.Neumorphic.main)
                .cornerRadius(10)
                
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

struct KeyboardResponsiveModifier: ViewModifier {
    @State private var offset: CGFloat = 0
    
    func body(content: Content) -> some View {
        content
            .padding(.bottom, offset)
            .onAppear {
                NotificationCenter.default.addObserver(forName: UIResponder.keyboardWillShowNotification, object: nil, queue: .main) { notif in
                    let value = notif.userInfo![UIResponder.keyboardFrameEndUserInfoKey] as! CGRect
                    let height = value.height
                    self.offset = height
                }
                
                NotificationCenter.default.addObserver(forName: UIResponder.keyboardWillHideNotification, object: nil, queue: .main) { notif in
                    self.offset = 0
                }
            }
    }
}


import SwiftUI
import Combine

final class KeyboardGuardian: ObservableObject {
    public var rects: Array<CGRect>
    public var keyboardRect: CGRect = CGRect()
    
    // keyboardWillShow notification may be posted repeatedly,
    // this flag makes sure we only act once per keyboard appearance
    public var keyboardIsHidden = true
    
    @Published var slide: CGFloat = 0
    
    var showField: Int = 0 {
        didSet {
            updateSlide()
        }
    }
    
    init(textFieldCount: Int) {
        self.rects = Array<CGRect>(repeating: CGRect(), count: textFieldCount)
        
    }
    
    func addObserver() {
        NotificationCenter.default.addObserver(self, selector: #selector(keyBoardWillShow(notification:)), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyBoardDidHide(notification:)), name: UIResponder.keyboardDidHideNotification, object: nil)
    }
    
    func removeObserver() {
        NotificationCenter.default.removeObserver(self)
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    
    
    @objc func keyBoardWillShow(notification: Notification) {
        if keyboardIsHidden {
            keyboardIsHidden = false
            if let rect = notification.userInfo?["UIKeyboardFrameEndUserInfoKey"] as? CGRect {
                keyboardRect = rect
                updateSlide()
            }
        }
    }
    
    @objc func keyBoardDidHide(notification: Notification) {
        keyboardIsHidden = true
        updateSlide()
    }
    
    func updateSlide() {
        
        if keyboardIsHidden {
            
            slide = 0
        } else {
            withAnimation(.easeOut(duration: 0.2)) {
                let diff = UIScreen.main.bounds.height - keyboardRect.minY
                slide = diff
            }
        }
    }
}
