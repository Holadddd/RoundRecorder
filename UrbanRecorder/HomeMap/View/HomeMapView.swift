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
            ZStack(alignment: Alignment.leading) {
                
                VStack{
                    Map(coordinateRegion: $viewmodel.userCurrentRegion, interactionModes: .all, showsUserLocation: true, userTrackingMode: nil, annotationItems: viewmodel.annotationItems, annotationContent: { item in
                        MapAnnotation(coordinate: item.coordinate) {
                            Image(systemName: item.imageSystemName)
                                .foregroundColor(item.tint)
                                
                        }
                    })
                        .edgesIgnoringSafeArea(.all)
                }
                
                SegmentSlideOverCardView(content: {
                    VStack{
                        HStack{
                            Text("ChannelID: ")
                            TextField.init("SubscribeChannelID", text: $viewmodel.userID, prompt: nil)
//                            Button("Subscribe") {
//                                viewmodel.subscribeChannel()
//                            }.padding()
                        }
                        HStack{
                            Text("ChannelID: ")
                            TextField.init("BroadcastChannelID", text: $viewmodel.recieverID, prompt: nil)
                            Button("Broadcast") {
                                viewmodel.broadcastChannel()
                            }.padding()
                        }
                        HStack{
                            // Prompt Note
                            Text(" ")
                        }
                        HStack{
                            DirectionAndDistanceMetersView(receiverDirection: viewmodel.receiverDirection,
                                                           receiverMeters: $viewmodel.receiverLastDistanceMeters, showWave: viewmodel.showWave,
                                                           volumeMaxPeakPercentage: viewmodel.volumeMaxPeakPercentage) {
                                // TODO: Fixed the distance
                                print("TODO: Fixed the distance")
                                
                            } resetAnchorDegreesDidClicked: {
                                viewmodel.resetAnchorDegrees()
                            }
                            .scaledToFill()
                        }
                    }
                }, cardPosition: $viewmodel.cardPosition, availableMode: AvailablePosition([.top, .middle, .bottom]))
            }
        }.onAppear {
            #warning("Test Api work for temporarily")
            viewmodel.subscribeAllEvent()
        }
        .onTapGesture {
            UIApplication.shared.endEditing()
        }
    }
}

struct HomeMapView_Preview: PreviewProvider {
    
    
    static var previews: some View {
        HomeMapView()
    }
}
