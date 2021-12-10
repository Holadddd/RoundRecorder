//
//  HomeMapView.swift
//  UrbanRecorder
//
//  Created by ting hui wu on 2021/10/21.
//

import Foundation
import SwiftUI
import MapKit
import Neumorphic
import UniformTypeIdentifiers

struct HomeMapView: View {
    
    @ObservedObject var viewmodel: HomeMapViewModel = HomeMapViewModel()
    
    @State private var showingSheet = false
    
    @State private var lastDragPosition: DragGesture.Value?
    
    @State private var menuScrollViewOffset: CGFloat = 0
    
    @State private var dragging: GridData?
    
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
                            HStack(alignment: .top){
                                ScrollView(.horizontal, showsIndicators: false) {
                                    HStack(spacing: 30) {
                                        Spacer(minLength: 10)
                                        ForEach(viewmodel.featureData) { data in
                                            Button {
                                                data.action?()
                                                viewmodel.featureData[data.id].isShowing.toggle()
                                            } label: {
                                                Text(data.title).fontWeight(.bold)
                                                    .frame(width: 120, height: 60)
                                            }.softButtonStyle(RoundedRectangle(cornerRadius: 15), padding: 5, isPressed: viewmodel.featureData[data.id].isShowing)
                                            
                                        }
                                        
                                        Spacer(minLength: 10)
                                    }
                                    .padding()
                                }
                                
                            }.frame(width: outsideProxy.frame(in: .local).width)
                            
                            ForEach(viewmodel.featureData) { data in
                                if data.isShowing {
                                    switch data.id {
                                    case 0:
                                            BoradcastView(channelID: $viewmodel.broadcastID, broadcastAction: {
                                                viewmodel.broadcastChannel()
                                            })
                                    case 1:
                                            VStack{
                                                SubscribeView(channelID: $viewmodel.subscribeID) {
                                                    viewmodel.subscribeChannel()
                                                }
                                                HStack{
                                                    // Prompt Note
                                                    Text("MS: \(viewmodel.udpsocketLatenctMs)")
                                                        .foregroundColor(.fixedLightGray)
                                                    Spacer()
                                                }
                                                HStack{
                                                    DirectionAndDistanceMetersView(receiverDirection: viewmodel.receiverDirection,
                                                                                   receiverMeters: $viewmodel.receiverLastDistanceMeters,
                                                                                   showWave: viewmodel.showWave,
                                                                                   volumeMaxPeakPercentage: viewmodel.volumeMaxPeakPercentage) {
                                                        // TODO: Fixed the distance
                                                        print("TODO: Fixed the distance")

                                                    } resetAnchorDegreesDidClicked: {
                                                        viewmodel.resetAnchorDegrees()
                                                    }
                                                    .scaledToFill()
                                                }
                                            }
                                    case 2:
                                        RecorderView(recordDidClicked: { viewmodel.recordButtonDidClicked() }, saveButtonDidClicked: { index in
                                            viewmodel.saveURAudioData(at: index)
                                        },
                                                     isRecordButtonPressed: $viewmodel.isRecording,
                                                     recordDuration: $viewmodel.recordDuration,
                                                     movingDistance: $viewmodel.recordMovingDistance,
                                                     recordName: $viewmodel.recordName,
                                                     recorderLocation: viewmodel.userLocation
                                        )
                                    default:
                                        Spacer(minLength: 0)
                                    }
                                }
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
            .environment(\.colorScheme, .light)
    }
}

struct DragRelocateDelegate: DropDelegate {
    let item: GridData
    @Binding var listData: [GridData]
    @Binding var current: GridData?

    func dropEntered(info: DropInfo) {
        if item != current {
            let from = listData.firstIndex(of: current!)!
            let to = listData.firstIndex(of: item)!
            if listData[to].id != current!.id {
                listData.move(fromOffsets: IndexSet(integer: from),
                    toOffset: to > from ? to + 1 : to)
            }
        }
    }

    func dropUpdated(info: DropInfo) -> DropProposal? {
        return DropProposal(operation: .move)
    }

    func performDrop(info: DropInfo) -> Bool {
        self.current = nil
        return true
    }
}
