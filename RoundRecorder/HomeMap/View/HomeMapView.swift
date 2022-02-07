//
//  HomeMapView.swift
//  RoundRecorder
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
    
    @ObservedObject private var kGuardian = KeyboardGuardian(textFieldCount: 2)
    
    @State private var lastDragPosition: DragGesture.Value?
    
    @State private var menuScrollViewOffset: CGFloat = 0
    
    @State private var dragging: GridData?
    
    var body: some View {
        GeometryReader { outsideProxy in
            ZStack(alignment: Alignment.leading) {
                VStack(spacing: 0){
                    ZStack{
                        VStack {
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
                        }
                    
                        
                        VStack {
                            Spacer()
                            
                            ZStack {
                                VStack {
                                    Spacer()
                                    HStack{
                                        
                                        Spacer()
                                        
                                        VStack{
                                            Button {
                                                viewmodel.locateButtonDidClicked()
                                            } label: {
                                                Image(systemName: viewmodel.isLocationLocked ? "location.north.line.fill" : "location.fill")
                                                    .softOuterShadow(offset: 2, radius: 0.5)
                                                    .tint(Color.Neumorphic.secondary)
                                                    .frame(width: 30, height: 30)
                                            }
                                            
                                            Divider().frame(width: 30)
                                            
                                            Button {
                                                viewmodel.clearRoutesButtonDidClicked()
                                            } label: {
                                                Image(systemName: "goforward")
                                                    .softOuterShadow(offset: 2, radius: 0.5)
                                                    .tint(Color.Neumorphic.secondary)
                                                    .frame(width: 30, height: 30)
                                            }
                                        }
                                        .padding(5)
                                        .background(Color.Neumorphic.main)
                                        .clipShape(RoundedRectangle(cornerRadius: 10))
                                    }
                                }
                                
                                VStack {
                                    Spacer()
                                    HStack {
                                        if viewmodel.isShowingDirectionAndDistanceView {
                                            VStack{
                                                Spacer()
                                                DirectionAndDistanceView(directionType: viewmodel.directionAndDistanceViewDirectionType,
                                                                         closeButtonDidClick:{
                                                    viewmodel.compassButtonDidClosed()
                                                }, udpsocketLatenctMs: viewmodel.udpsocketLatenctMs,
                                                                               receiverDirection: viewmodel.receiverDirection,
                                                                               receiverMeters: $viewmodel.receiverLastDistanceMeters,
                                                                               isSetStaticDistance: $viewmodel.isSetStaticDistanceMeters,
                                                                               showWave: viewmodel.isShowingWave,
                                                                               volumeMaxPeakPercentage: viewmodel.volumeMaxPeakPercentage,
                                                                               distanceMeteDidClicked: {
                                                    viewmodel.setStaticDistance()
                                                }, resetAnchorDegreesDidClicked: {
                                                    viewmodel.resetAnchorDegrees()
                                                }, increaseButtonDidClicked: {
                                                    viewmodel.increaseStaticDistanceButtonDidClicked()
                                                }, decreaseButtonDidClicked: {
                                                    viewmodel.decreaseStaticDistanceButtonDidClicked()
                                                }, increaseButtonOnLongpress: {
                                                    viewmodel.increaseStaticDistanceButtonOnLongpress()
                                                }, decreaseButtonOnLongpress: {
                                                    viewmodel.decreaseStaticDistanceButtonOnLongpress()
                                                })
                                            }.frame(height: 200)
                                            
                                        } else {
                                            VStack {
                                                Rectangle().fill(.clear).frame(width: 30, height: 30)
                                                
                                                Button {
                                                    viewmodel.compassButtonDidClicked()
                                                } label: {
                                                    Image("compass")
                                                        .resizable()
                                                        .renderingMode(.template)
                                                        .scaleEffect(0.7)
                                                        .softOuterShadow(offset: 2, radius: 0.5)
                                                        .tint(Color.Neumorphic.secondary)
                                                        .frame(width: 30, height: 30)
                                                }
                                                .padding(5)
                                                .background(Color.Neumorphic.main)
                                                .clipShape(RoundedRectangle(cornerRadius: 10))
                                            }
                                        }
                                        Spacer()
                                    }
                                }
                            }
                            
                        }.padding(EdgeInsets(top: 0, leading: 0, bottom: 30, trailing: 0))
                        
                        
                    }
                    // MARK: Feature menu
                    ZStack{
                        
                        HStack(alignment: .center) {
                            Spacer()
                            ZStack{
                                Button {
                                    viewmodel.radioButtonDidClicked()
                                } label: {
                                    VStack(spacing:0){
                                        Image(systemName: "antenna.radiowaves.left.and.right")
                                            .tint((viewmodel.isSubscribing || viewmodel.isBroadcasting) ? Color.red : Color.Neumorphic.secondary)
                                            .frame(width: 30, height: 30)
                                        Text(I18n.string(.Radio)).font(.system(size: 10, weight: .bold)).foregroundColor((viewmodel.isSubscribing || viewmodel.isBroadcasting) ? Color.red : Color.Neumorphic.secondary)
                                    }.padding(0)
                                }.softOuterShadow(offset: 2, radius: 0.5)
                                    .background(.clear)
                                    .padding(0)
                            }
                            
                            
                            Spacer()
                            ZStack{
                                RoundedRectangle(cornerRadius: 11).frame(width: 22, height: 22)
                                    .foregroundColor(Color.Neumorphic.main)
                                Button {
                                    if viewmodel.isRecording {
                                        viewmodel.stopRRRecordingSession()
                                    } else {
                                        viewmodel.recordButtonDidClicked()
                                    }
                                    
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
                                        if viewmodel.isRecording {
                                            RoundedRectangle(cornerRadius: 1)
                                                .stroke(Color.Neumorphic.secondary, style: SwiftUI.StrokeStyle(lineWidth: 0.3, lineCap: .square, lineJoin: .round))
                                                .frame(width: 6, height: 6)
                                            RoundedRectangle(cornerRadius: 1)
                                                .fill(.red)
                                                .frame(width: 6, height: 6)
                                                .softOuterShadow(offset: 1, radius: 1)
                                        } else {
                                            ZStack{
                                                RoundedRectangle(cornerRadius: 1)
                                                    .fill(Color.Neumorphic.secondary)
                                                    .frame(width: 8, height: 1)
                                                RoundedRectangle(cornerRadius: 1)
                                                    .fill(Color.Neumorphic.secondary)
                                                    .frame(width: 1, height: 8)
                                                    
                                            }.softOuterShadow(offset: 1, radius: 1)
                                        }
                                        
                                    }.background(.clear)
                                }
                            }.scaleEffect(3)
                                .background(.clear)
                                .padding(0)
                            
                            Spacer()
                            
                            ZStack{
                                Button {
                                    viewmodel.fileButtonDidClicked()
                                } label: {
                                    VStack(spacing:0){
                                        Image(systemName: "list.bullet")
                                            .tint((viewmodel.playingData == nil) ? Color.Neumorphic.secondary : Color.red)
                                            .frame(width: 30, height: 30)
                                            .softOuterShadow(offset: 2, radius: 0.5)
                                        Text(I18n.string(.File)).font(.system(size: 10, weight: .bold)).foregroundColor((viewmodel.playingData == nil) ? Color.Neumorphic.secondary : Color.red)
                                    }.padding(0)
                                }
                                .softOuterShadow(offset: 2, radius: 0.5)
                                .background(.clear)
                                .padding(0)
                            }
                            Spacer()
                        }.padding(0)
                    }.padding(EdgeInsets(top: 5, leading: 0, bottom: 5, trailing: 0))
                        
                }.padding(0)
                    .background(Color.Neumorphic.main)
                /*  User current location
                VStack {
                    HStack {
                        VStack(alignment: .leading, spacing: 5) {
                            Text(viewmodel.userLocation == nil ? "latitude: " : "latitude: \(viewmodel.userLocation!.latitude)")
                            Text(viewmodel.userLocation == nil ? "longitude: " : "longitude: \(viewmodel.userLocation!.longitude)")
                        }
                        Spacer()
                        
                    }.padding(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 5))
                    Spacer()
                }
                 */
                ZStack{
                    if let useCase = viewmodel.cardViewUseCase {
                        SegmentSlideOverCardView(closeButtonDidClick: {viewmodel.segmentSlideOverCardDidClose()}, isSetReload: $viewmodel.setNeedReload, content: {
                            VStack(spacing: 0) {
                                switch useCase {
                                case .radio:
                                    BroadcastView(channelID: $viewmodel.broadcastID,
                                                  isConnecting: $viewmodel.isBroadcasting,
                                                  isShowingAlert: $viewmodel.showBroadcastPermissionAlert,
                                                  requestForBroadcastWithId: { channelID in
                                        viewmodel.requestForBroadcastChannelWith(channelID)
                                    }, keepRecordingWithBroadcastWithId: { channelID in
                                        viewmodel.keepRecordingWithBroadcastWithId(channelID)
                                    }, stopBroadcastAction: { channelID in
                                        viewmodel.stopBroadcastChannelWith(channelID)
                                    }).softOuterShadow()
                                    
                                    SubscribeView(channelID: $viewmodel.subscribeID,
                                                  isConnecting: $viewmodel.isSubscribing,
                                                  isShowingAlert: $viewmodel.showSubscribePermissionAlert,
                                                  requestForSubscribeChannel: {
                                        viewmodel.requestForSubscribeChannel()
                                    }, stopPlayingOnFileAndSubscribeChannel: {
                                        viewmodel.stopPlayingOnFileThenSubscribeChannel()
                                    }, stopSubscribetAction: {
                                        viewmodel.stopSubscribeChannel()
                                    }).softOuterShadow()
                                case .record:
                                    RecorderView(isRecordButtonPressed: $viewmodel.isRecording,
                                                 recordDuration: $viewmodel.recordDuration,
                                                 movingDistance: $viewmodel.recordMovingDistance,
                                                 recordName: $viewmodel.recordName,
                                                 recorderRRLocation: viewmodel.userRRLocation,
                                                 isShowingAlert: $viewmodel.showRecordingPermissionAlert,
                                                 requestForRecording: {
                                        viewmodel.requestForRecording()
                                    }, keepBroadcastWhileRecording: {
                                        viewmodel.keepBroadcastWhileRecording()
                                    }, stopRecording: {
                                        viewmodel.stopRRRecordingSession()
                                    }).softOuterShadow()
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
                            }
                            
                        }, cardPosition: $viewmodel.cardPosition, availableMode: useCase.cardAvailableMode)
                            .onChange(of: viewmodel.cardViewUseCase) { _ in
                                viewmodel.setNeedReload = true
                            }.offset(y: -kGuardian.slide)
                            
                    }
                }
                // Permission
                Button("") {
                    
                }.alert(viewmodel.permissionTitle, isPresented: $viewmodel.isShowingPermissionAlert) {
                    Button(I18n.string(.Setting), role: .cancel) {
                        let url = URL(string: UIApplication.openSettingsURLString)!
                        UIApplication.shared.open(url)
                    }
                    Button(I18n.string(.Ok)) {
                        
                    }
                } message: {
                    Text(viewmodel.permissionMsg)
                }.show(isVisible: viewmodel.isShowingPermissionAlert)
                    .alert(I18n.string(.ChannelIDInvalid), isPresented: $viewmodel.isChannelIDInvalidAlertShowing) {
                        
                }
            }.background(Color.Neumorphic.main.ignoresSafeArea())
        }
            .onAppear {
            #warning("Test Api work for temporarily")
            viewmodel.subscribeAllEvent()
            self.kGuardian.addObserver()
                
        }
        .onDisappear {
            self.kGuardian.removeObserver()
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
