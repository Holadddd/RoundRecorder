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
    
    @State private var lastDragPosition: DragGesture.Value?
    
    @State private var menuScrollViewOffset: CGFloat = 0
    
    @State private var dragging: GridData?
    
    var body: some View {
        GeometryReader { outsideProxy in
            ZStack(alignment: Alignment.leading) {
//                VStack{
//                    Spacer()
//                    HStack(alignment: .top){
//                        ScrollView(.horizontal, showsIndicators: false) {
//                            HStack(spacing: 20) {
//                                Spacer(minLength: 10)
//                                ForEach(viewmodel.featureData) { data in
//                                    Button {
//                                        data.action?()
//                                        viewmodel.featureData[data.id].isShowing.toggle()
//                                    } label: {
//                                        Text(data.title).fontWeight(.bold)
//                                            .frame(width: 120, height: 20)
//                                    }.softButtonStyle(RoundedRectangle(cornerRadius: 10), padding: 5,
//                                                      isPressed: viewmodel.featureData[data.id].isShowing)
//                                }
//
//                                Spacer(minLength: 10)
//                            }
//                            .padding(EdgeInsets(top: 10, leading: 0, bottom: 15, trailing: 0))
//                        }
//                    }.frame(width: UIScreen.main.bounds.width)
//                    HStack(alignment: .center) {
//                        Button {
//                            print("Radio did clicked")
//                        } label: {
//                            Image(systemName: "antenna.radiowaves.left.and.right")
//                                .tint(Color.Neumorphic.secondary)
//                                .frame(width: 30, height: 30)
//                        }
//
//                        Button {
//                            print("List did clicked")
//                        } label: {
//                            Image(systemName: "list.bullet")
//                                .tint(Color.Neumorphic.secondary)
//                                .frame(width: 30, height: 30)
//                        }
//                    }
//                }
                VStack(spacing: 0){
                    
                    MapView(isSetupCurrentLocation: $viewmodel.isSetupCurrentLocation,
                            userCurrentMapCamera: $viewmodel.userCurrentMapCamera,
                            isLocationLocked: $viewmodel.isLocationLocked,
                            headingDirection: viewmodel.headingDirection,
                            updateByMapItem: $viewmodel.updateByMapItem,
                            showsUserLocation: true,
                            removeAnnotationItems: $viewmodel.removeAnnotationItems,
                            userAnootionItem: viewmodel.userAnootion,
                            addAnnotationItem: viewmodel.receiverAnnotationItem,
                            displayRoutes: $viewmodel.displayRoutes,
                            removeRoutes: $viewmodel.removeRoutes)
                        .edgesIgnoringSafeArea(.all)
                    // MARK: Feature menu
                    ZStack{
                        
                        HStack(alignment: .center) {
                            Spacer()
                            
                            Button {
                                viewmodel.radioButtonDidClicked()
                            } label: {
                                VStack(spacing:0){
                                    Image(systemName: "antenna.radiowaves.left.and.right")
                                        .tint(Color.Neumorphic.secondary)
                                        .frame(width: 30, height: 30)
                                    Text("Radio").font(.system(size: 10, weight: .bold)).foregroundColor(Color.Neumorphic.secondary)
                                }.padding(0)
                            }
                            .softOuterShadow(offset: 2, radius: 0.5)
                            .background(.clear)
                            .padding(0)
                            Spacer()
                            ZStack{
                                RoundedRectangle(cornerRadius: 11).frame(width: 22, height: 22)
                                    .foregroundColor(Color.Neumorphic.main)
                                Button {
                                    viewmodel.recordButtonDidClicked()
                                } label: {
                                    ZStack{
                                        RoundedRectangle(cornerRadius: 10).frame(width: 20, height: 20)
                                            .foregroundColor(Color.Neumorphic.main)
                                            .softInnerShadow(Circle())
                                        RoundedRectangle(cornerRadius: 9).frame(width: 18, height: 18)
                                            .foregroundColor(Color.Neumorphic.main)
                                            .softOuterShadow(offset: 1, radius: 1)
                                        RoundedRectangle(cornerRadius: 8).frame(width: 16, height: 16)
                                            .foregroundColor(Color.Neumorphic.main)
                                            .softInnerShadow(Circle())
                                        Image(systemName: "plus")
                                            .scaleEffect(0.7)
                                            .tint(Color.Neumorphic.secondary)
                                            .softOuterShadow(offset: 1, radius: 0.5)
                                    }.background(.clear)
                                }
                            }.scaleEffect(3)
                                .background(.clear)
                                .padding(0)
                            Spacer()
                            
                            Button {
                                viewmodel.fileButtonDidClicked()
                            } label: {
                                VStack(spacing:0){
                                    Image(systemName: "list.bullet")
                                        .tint(Color.Neumorphic.secondary)
                                        .frame(width: 30, height: 30)
                                        .softOuterShadow(offset: 2, radius: 0.5)
                                    Text("File").font(.system(size: 10, weight: .bold)).foregroundColor(Color.Neumorphic.secondary)
                                }.padding(0)
                            }
                            .softOuterShadow(offset: 2, radius: 0.5)
                            .background(.clear)
                            .padding(0)
                            
                            Spacer()
                        }.padding(0)
                    }.padding(EdgeInsets(top: 5, leading: 0, bottom: 5, trailing: 0))
                }.padding(0)
                    .background(Color.Neumorphic.main)
                
                VStack {
                    HStack {
                        VStack(alignment: .leading, spacing: 5) {
                            Text(viewmodel.userLocation == nil ? "latitude: " : "latitude: \(viewmodel.userLocation!.latitude)")
                            Text(viewmodel.userLocation == nil ? "longitude: " : "longitude: \(viewmodel.userLocation!.longitude)")
                        }
                        Spacer()
                        VStack{
                            Button {
                                viewmodel.locateButtonDidClicked()
                            } label: {
                                Image(systemName: viewmodel.isLocationLocked ? "location.north.line.fill" : "location.fill")
                                    .tint(Color.Neumorphic.secondary)
                                    .frame(width: 30, height: 30)
                            }.softButtonStyle(RoundedRectangle(cornerRadius: 3), padding: 0, pressedEffect: .hard, isPressed: viewmodel.isLocationLocked)
                            
                            Button {
                                viewmodel.clearRoutesButtonDidClicked()
                            } label: {
                                Image(systemName: "goforward")
                                    .tint(Color.Neumorphic.secondary)
                                    .frame(width: 30, height: 30)
                            }.softButtonStyle(RoundedRectangle(cornerRadius: 3), padding: 0, pressedEffect: .hard, isPressed: viewmodel.isLocationLocked)
                        }.padding(EdgeInsets(top: 50, leading: 0, bottom: 0, trailing: 0))
                        
                            
                    }.padding(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 5))
                    Spacer()
                }
                if let useCase = viewmodel.cardViewUseCase {
                    SegmentSlideOverCardView(closeButtonDidClick: {viewmodel.segmentSlideOverCardDidClose()}, isSetReload: $viewmodel.setNeedReload, content: {
                        VStack(spacing: 0) {
                            switch useCase {
                            case .radio:
                                BroadcastView(channelID: $viewmodel.broadcastID,
                                              isBroadcasting: $viewmodel.isBroadcasting,
                                              isShowingAlert: $viewmodel.showBroadcastPermissionAlert,
                                              requestForBroadcastWithId: { channelID in
                                    viewmodel.requestForBroadcastChannelWith(channelID)
                                }, keepRecordingWithBroadcastWithId: { channelID in
                                    viewmodel.keepRecordingWithBroadcastWithId(channelID)
                                }, stopBroadcastAction: { channelID in
                                    viewmodel.stopBroadcastChannelWith(channelID)
                                })
                                
                                SubscribeView(channelID: $viewmodel.subscribeID,
                                              isSubscribing: $viewmodel.isSubscribing,
                                              isShowingAlert: $viewmodel.showSubscribePermissionAlert,
                                              requestForSubscribeChannel: {
                                    viewmodel.requestForSubscribeChannel()
                                }, stopPlayingOnFileAndSubscribeChannel: {
                                    viewmodel.stopPlayingOnFileThenSubscribeChannel()
                                }, stopSubscribetAction: {
                                    viewmodel.stopSubscribeChannel()
                                })
                            case .record:
                                RecorderView(isRecordButtonPressed: $viewmodel.isRecording,
                                             recordDuration: $viewmodel.recordDuration,
                                             movingDistance: $viewmodel.recordMovingDistance,
                                             recordName: $viewmodel.recordName,
                                             recorderURLocation: viewmodel.userURLocation,
                                             isShowingAlert: $viewmodel.showRecordingPermissionAlert,
                                             requestForRecording: {
                                    viewmodel.requestForRecording()
                                }, keepBroadcastWhileRecording: {
                                    viewmodel.keepBroadcastWhileRecording()
                                }, stopRecording: {
                                    viewmodel.stopURRecordingSession()
                                })
                            case .file:
                                FileListView(
                                    setReload: {
                                        viewmodel.setNeedReload = true
                                    },
                                    fileListCount: $viewmodel.fileListCount,
                                    isShowingAlert: $viewmodel.showPlayingPermissionAlert,
                                    requestOnPlaying: {data in
                                        viewmodel.requestFileOnPlaying(data)
                                    },
                                    stopSubscriptionAndPlaying: {data in
                                        viewmodel.stopSubscriptionAndPlaying(data)
                                    },
                                    onPause: {
                                        viewmodel.fileListOnPause()
                                    }, onSelected: { selectedData in
                                        
                                        viewmodel.fileListOnSelected(selectedData)
                                    },
                                    onDelete: { deletedData in
                                        
                                        viewmodel.fileListOnDelete(deletedData)
                                    },
                                    dataOnExpanded: $viewmodel.expandedData,
                                    dataOnPlaying: $viewmodel.playingData)
                            }
//
//                            DirectionAndDistanceMetersView(udpsocketLatenctMs: viewmodel.udpsocketLatenctMs,
//                                                           receiverDirection: viewmodel.receiverDirection,
//                                                           receiverMeters: $viewmodel.receiverLastDistanceMeters,
//                                                           isSetStaticDistance: $viewmodel.isSetStaticDistanceMeters,
//                                                           showWave: viewmodel.showWave,
//                                                           volumeMaxPeakPercentage: viewmodel.volumeMaxPeakPercentage) {
//                                viewmodel.setStaticDistance()
//                            } resetAnchorDegreesDidClicked: {
//                                viewmodel.resetAnchorDegrees()
//                            }
//                            .scaledToFill()
                        }
                    }, cardPosition: $viewmodel.cardPosition, availableMode: useCase.cardAvailableMode)
                        .onChange(of: viewmodel.cardViewUseCase) { _ in
                            viewmodel.setNeedReload = true
                        }
                }
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
            .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
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
