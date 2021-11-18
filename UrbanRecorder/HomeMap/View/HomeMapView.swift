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
                            Image(systemName: "gamecontroller.fill")
                                .foregroundColor(item.tint)
                        }
                    })
                        .edgesIgnoringSafeArea(.all)
                }
                
                VStack(alignment: .leading){
                    Text("Longitude: \(viewmodel.longitude)")
                    Text("Latitude: \(viewmodel.latitude)")
                    Text("Elevation: \(viewmodel.altitude)")
                }
                
                VStack(alignment: .leading){
                    HStack{
                        Text("UserID: ")
                        TextField.init("userID", text: $viewmodel.userID, prompt: nil)
                    }
                    
                    HStack{
                        Text("RecieverID: ")
                        TextField.init("recieverID", text: $viewmodel.recieverID, prompt: nil)
                    }
                    HStack{
                        Button("MakeCallSession") {
                            viewmodel.setupCallSessionChannel()
                        }
                    }
                    DirectionAndDistanceMetersView(receiverDirection: viewmodel.receiverDirection, receiverMeters: $viewmodel.receiverLastDistanceMeters)
                    Spacer()
                }
                
                SegmentSlideOverCardView(content: {
                    ForEach(0..<50) {i in
                        Text("\(i)")
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
