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
    
    @Binding var isSetReload: Bool
    
    var content: () -> Content
    
    @Binding var cardPosition: CardPosition
    
    var availableMode: AvailablePosition = AvailablePosition()
    
    let axes: Axis.Set = .vertical
    
    @State var onScrollingSession: Bool = false
    
    @State var isScrollingOnScrollView: Bool = false
    
    @State var isScrollingOnCard: Bool = false
    
    @State var scrollViewMaxOffset: CGFloat = 0
    // Scroll Offset
    var minusIndicatorHeight: CGFloat = 30
    
    @State private var scrollViewSizeHeight: CGFloat = 0
    
    @State private var scrollViewContentHeight: CGFloat = 0
    
    @State private var scrollViewOffset: CGFloat = 0
    
    var adjustmentScrollViewOffset: CGFloat {
        return scrollViewOffset + diffInSizeAndContentHeight / 2
    }
    
    var diffInSizeAndContentHeight: CGFloat {
        let diffInSizeAndContentHeight: CGFloat = scrollViewContentHeight > scrollViewSizeHeight ? scrollViewContentHeight - scrollViewSizeHeight + minusIndicatorHeight + 5 : 0
        
        return diffInSizeAndContentHeight
    }
    
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
                    .frame(height: 30)
                
                
                GeometryReader{ value in
                    NavigationView{
                        ScrollView {
                            ZStack{
                                VStack{
                                    content()
                                    Spacer().padding(10)
                                }
                                .expandHorizontally()
                                .overlay(
                                    GeometryReader { proxy in
                                        Color.clear.onAppear {
                                            scrollViewSizeHeight = value.size.height
                                            scrollViewContentHeight = proxy.size.height
                                            print("value.size: \(value.size.height)")
                                            print("proxy.size: \(proxy.size.height)")
                                        }
                                        .onChange(of: isSetReload) { _ in
                                            if isSetReload {
                                                print("value.size: \(value.size.height)")
                                                print("Reload size: \(proxy.size.height)")
                                                scrollViewContentHeight = proxy.size.height
                                                isSetReload.toggle()
                                            }
                                        }
                                        
                                    }
                                )
                            }
                        }
                        .content.offset(x: 0, y: adjustmentScrollViewOffset)
                        .coordinateSpace(name: "scroll")
                        .padding(0)
                        .navigationBarHidden(true)
                        .background(Color.themeBackgroud)
                    }.navigationBarTitleDisplayMode(.inline)
                        
                }
            }
        }
        .gesture(
            DragGesture()
                .onChanged({ drag in
                    
                    let predictShiftOffset = drag.predictedEndLocation.y - drag.location.y
                    
                    let currentCardOffset = cardPosition.offsetValue + cardViewOffset
                    
                    let updatePosition = cardPosition.updatePositionResult(with: currentCardOffset + predictShiftOffset, availableMode: availableMode.modes)
                    
                    let isCardReachTopOffset = currentCardOffset <= (availableMode.maxMode.offsetValue)
                    
                    let isUpdatedPermit = abs(predictShiftOffset) > 0.1
                    
                    // Update offset
                    if isScrollingOnScrollView && onScrollingSession , let lastDragPosition = lastDragPosition  {
                        let scrollShiftOffSet = drag.location.y - lastDragPosition.location.y
                        let updatedScrollViewOffset = scrollViewOffset + scrollShiftOffSet
                        // update scrollView offset
                        cardViewOffset = 0
                        if updatedScrollViewOffset < 0 && (updatedScrollViewOffset > -diffInSizeAndContentHeight) {
                            scrollViewOffset = updatedScrollViewOffset
                        }
                    }
                    
                    if isScrollingOnCard && onScrollingSession {
                        // update card offset
                        cardViewOffset += drag.translation.height
                        scrollViewOffset = 0
                    }
                    
                    let updatedScrollViewOffset = scrollViewOffset + predictShiftOffset
                    
                    if  isUpdatedPermit {
                        if (predictShiftOffset <= 0) {
                            // Scroll Up
                            // if CardOffset Cant be updated
                            if !onScrollingSession {
                                if isCardReachTopOffset {
                                    // Setting is On scrolling session
                                    isScrollingOnScrollView = true
                                    isScrollingOnCard = false
                                } else {
                                    // Update card offset
                                    isScrollingOnScrollView = false
                                    isScrollingOnCard = true
                                }
                                
                                onScrollingSession = true
                            } else {
                                // Switch Scrolling target while on session
                                if isCardReachTopOffset {
                                    isScrollingOnScrollView = true
                                    isScrollingOnCard = false
                                    cardPosition = updatePosition
                                }
                            }
                        } else {
                            // Scroll Down
                            // if scrollOffset Cant be updated
                            if !onScrollingSession {
                                if updatedScrollViewOffset < 0 && isScrollingOnScrollView {
                                    // Update On ScrollView
                                    isScrollingOnScrollView = true
                                    isScrollingOnCard = false
                                } else {
                                    isScrollingOnScrollView = false
                                    isScrollingOnCard = true
                                }
                                
                                onScrollingSession = true
                            }
                        }
                    }
                    
                    lastDragPosition = drag
                })
                .onEnded({ drag in
                    onScrollingSession = false
                    
                    let predictShiftOffset = drag.predictedEndLocation.y - drag.location.y

                    let currentCardOffset = cardPosition.offsetValue + cardViewOffset

                    let updatePosition = cardPosition.updatePositionResult(with: currentCardOffset + predictShiftOffset, availableMode: availableMode.modes)
                    
                    let isCardWillOnTop = cardPosition.isPositionStatusIsOnTop(updatePosition, availableMode: availableMode.modes)

                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7, blendDuration: 0)) {
                        if isScrollingOnCard {
                            // Finish at the middel between card position
                            cardPosition = updatePosition
                            cardViewOffset = 0
                        }

                        if isScrollingOnScrollView {
                            cardViewOffset = 0
                        }
                    }
                    
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
