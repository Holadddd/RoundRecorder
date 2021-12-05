//
//  SegmentSlideOverCardView.swift
//  UrbanRecorder
//
//  Created by ting hui wu on 2021/10/25.
//
import Foundation
import SwiftUI
import Neumorphic

struct SegmentSlideOverCardView<Content: View> : View {
    
    @State var lastDragPosition: DragGesture.Value?
    
    @State private var cardViewOffset: CGFloat = 0
    
    @State private var scrollViewOffset: CGFloat = 0
    
    var content: () -> Content
    
    @Binding var cardPosition: CardPosition
    
    var availableMode: AvailablePosition = AvailablePosition()
    
    let axes: Axis.Set = .vertical
    
    @State var scrollAble: Bool = false
    
    @State var isScrollingOnScrollView: Bool = false
    
    @State var isScrollingOnCard: Bool = false
    
    @State var scrollViewMaxOffset: CGFloat = 0
    
    var body: some View {
        
        
        return ZStack{
            VStack(alignment: .center, spacing: 0) {
                Image(systemName: "minus")
                    .expandHorizontally()
                    .foregroundColor(.gray)
                    .padding(10)
                    .scaleEffect(2)
                    .background(Color.themeBackgroud)
                    .zIndex(1)
                
                
                GeometryReader{ value in
                    NavigationView{
                        ScrollView {
                            ZStack{
                                VStack{
                                    content()
                                        .expandHorizontally()
                                    Spacer().padding(10)
                                }
                                .overlay(
                                    GeometryReader { proxy in
                                        Color.clear.onAppear {
                                            scrollViewMaxOffset = value.frame(in: .local).size.height - proxy.size.height
                                        }
                                    }
                                ).background(Color.themeBackgroud)
                            }
                        }
                        .content.offset(x: 0, y: scrollViewOffset)
                        .coordinateSpace(name: "scroll")
                        .padding(0)
                        .navigationBarHidden(true)
                    }.navigationBarTitleDisplayMode(.inline)
                }
            }
        }
        .gesture(
            DragGesture()
                .onChanged({ drag in
                    
                    if let lastDragPosition = lastDragPosition {
                        
                        let scrollShiftOffSet = drag.location.y - lastDragPosition.location.y
                        
                        let currentCardOffset = cardPosition.offsetValue + cardViewOffset
                        if currentCardOffset > (availableMode.maxMode.offsetValue) && !isScrollingOnScrollView {
                            isScrollingOnCard = true
                            scrollViewOffset = 0
                            
                            cardViewOffset += drag.translation.height
                            
                            let currentCardOffset = cardPosition.offsetValue + cardViewOffset
                            if currentCardOffset > availableMode.minMode.offsetValue {
                                cardViewOffset -= drag.translation.height
                            }
                        } else {
                            let updatedOffset = scrollViewOffset + scrollShiftOffSet
                            if updatedOffset <= 0 && updatedOffset > scrollViewMaxOffset {
                                isScrollingOnScrollView = true
                                
                                scrollViewOffset = updatedOffset
                            } else if !isScrollingOnScrollView {
                                
                                if isScrollingOnCard {
                                    
                                    if updatedOffset <= 0 && updatedOffset > scrollViewMaxOffset {
                                        scrollViewOffset = updatedOffset
                                    }
                                } else {
                                    if updatedOffset > scrollViewMaxOffset {
                                        cardViewOffset += drag.translation.height
                                    } else {
                                        if drag.translation.height > 0 {
                                            cardViewOffset -= drag.translation.height
                                        }
                                    }
                                }
                            }
                        }
                    }
                    
                    lastDragPosition = drag
                })
                .onEnded({ drag in
                    let predictShiftOffset = drag.predictedEndLocation.y - drag.location.y
                    
                    let currentOffset = cardPosition.offsetValue + cardViewOffset
                    
                    let updatePosition = cardPosition.updatePositionResult(with: currentOffset + predictShiftOffset, availableMode: availableMode.modes)
                    
                    let isCardWillOnTop = cardPosition.isPositionStatusIsOnTop(updatePosition, availableMode: availableMode.modes)
                    
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7, blendDuration: 0)) {
                        if isScrollingOnCard {
                            cardPosition = updatePosition
                            
                            cardViewOffset = 0
                            
                            if !isCardWillOnTop {
                                scrollViewOffset = 0
                                scrollAble = false
                            }
                        }
                        
                        if isScrollingOnScrollView {
                            if (scrollViewOffset + predictShiftOffset) > 0 {
                                scrollViewOffset = 0
                                scrollAble = false
                            } else if (scrollViewOffset + predictShiftOffset) < scrollViewMaxOffset {
                                scrollViewOffset = scrollViewMaxOffset
                            } else {
                                scrollViewOffset += predictShiftOffset
                                scrollAble = true
                            }
                            
                        }
                    }
                    
                    isScrollingOnScrollView = false
                    
                    if scrollViewOffset == 0 {
                        isScrollingOnCard = false
                    }
                    
                    lastDragPosition = nil
                })
        )
        .background(Color.Neumorphic.main)
        .cornerRadius(10)
        .softOuterShadow(darkShadow: .fixedDarkGray, lightShadow: .fixedLightGray, offset: 5, radius: 5)
        .offset(y: cardPosition.offsetValue + cardViewOffset)
        .ignoresSafeArea(edges: Edge.Set.bottom)
        
        
    }
    
    private func calculateContentOffset(fromOutsideProxy outsideProxy: GeometryProxy, insideProxy: GeometryProxy) -> CGFloat {
        if axes == .vertical {
            return outsideProxy.frame(in: .global).minY - insideProxy.frame(in: .global).minY
        } else {
            return outsideProxy.frame(in: .global).minX - insideProxy.frame(in: .global).minX
        }
    }
}

struct AvailablePosition {
    var modes: [CardPosition]
    
    init(_ modes: [CardPosition] = [.bottom, .middle]) {
        self.modes = modes.sorted(by:{$0.offsetValue < $1.offsetValue})
    }
    
    var maxMode: CardPosition {
        return modes[0]
    }
    
    var minMode: CardPosition {
        return modes[modes.count - 1]
    }
}

enum CardPosition: CGFloat {
    
    case top
    case middle
    case bottom
    
    var offsetValue: CGFloat {
        switch self {
        case .top:
            return 0
        case .middle:
            return UIScreen.main.bounds.height / 2
        case .bottom:
            return UIScreen.main.bounds.height - 150
        }
    }
    
    mutating func moveAbove() {
        switch self {
        case .top, .middle:
            self = .top
        case .bottom:
            self = .middle
        }
    }
    
    mutating func moveBelow() {
        switch self {
        case .top:
            self = .middle
        case .middle, .bottom:
            self = .bottom
        }
    }
    
    mutating func updatePositionResult(with offset: CGFloat, availableMode: [CardPosition]) -> CardPosition {
        
        switch availableMode.count {
        case 3:
            let topRange = (CardPosition.top.offsetValue + CardPosition.middle.offsetValue) / 2
            
            let midRange = (CardPosition.middle.offsetValue + CardPosition.bottom.offsetValue) / 2
            
            switch offset {
            case -.infinity..<topRange:
                return .top
            case topRange..<midRange:
                return .middle
            default:
                return .bottom
                
            }
        case 2:
            let sortedMode = availableMode.sorted(by:{$0.offsetValue < $1.offsetValue})
            
            let midRange = (sortedMode[0].offsetValue + sortedMode[1].offsetValue) / 2
            
            switch offset {
            case -.infinity..<midRange:
                return sortedMode[0]
            default:
                return sortedMode[1]
            }
        default:
            return availableMode[0]
        }
    }
    
    mutating func isPositionStatusIsOnTop(_ position: CardPosition, availableMode: [CardPosition]) -> Bool {
        let sortedMode = availableMode.sorted(by:{$0.offsetValue < $1.offsetValue})
        return position == sortedMode[0]
    }
}

private struct ScrollOffsetPreferenceKey: PreferenceKey {
    static var defaultValue: CGFloat = .zero
    
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {}
}
