//
//  HomeMapView.swift
//  UrbanRecorder
//
//  Created by ting hui wu on 2021/10/21.
//

import Foundation
import SwiftUI
import MapKit

struct HomeMapView: View {
    
    @ObservedObject var viewmodel: HomeMapViewModel = HomeMapViewModel()
    
    @State private var showingSheet = false
    
    @State private var lastDragPosition: DragGesture.Value?
    
    @State private var menuScrollViewOffset: CGFloat = 0
    
    var body: some View {
        GeometryReader { outsideProxy in
            ZStack(alignment: Alignment.top) {
                VStack{
                    Map(coordinateRegion: $viewmodel.userCurrentRegion, interactionModes: .all, showsUserLocation: true, userTrackingMode: nil, annotationItems: viewmodel.annotationItems, annotationContent: { item in
                        MapAnnotation(coordinate: item.coordinate) {
                            Image(systemName: "gamecontroller.fill")
                                .foregroundColor(item.tint)
                        }
                    })
                        .edgesIgnoringSafeArea(.all)
                }
                
//                VStack{
//                    Spacer()
//                    HStack(alignment: .center, spacing: 50, content: {
//                        Button {
//                            viewmodel.recordButtonDidClicked()
//                        } label: {
//                            Image(systemName: "record.circle.fill")
//                                .foregroundStyle(.red, .white)
//                                .scaleEffect(viewmodel.buttonScale)
//                        }
//
//                        Button {
//                            viewmodel.playButtonDidClicked()
//                        } label: {
//                            Image(systemName: "play.circle.fill")
//                                .foregroundStyle(viewmodel.isSelectedItemPlayAble ? .green : .gray, .white)
//                                .scaleEffect(viewmodel.buttonScale)
//                        }.disabled(!viewmodel.isSelectedItemPlayAble)
//                    })
//                }.padding(50)
                
                SegmentSlideOverCardView(content: {
                    ForEach(0..<50) {i in
                        Text("\(i)")
                    }
                }, cardPosition: $viewmodel.cardPosition, availableMode: [.top, .middle, .bottom])
            }
        }
    }
}

struct HomeMapView_Preview: PreviewProvider {
    
    
    static var previews: some View {
        HomeMapView()
    }
}
