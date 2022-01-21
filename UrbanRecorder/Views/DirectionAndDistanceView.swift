//
//  DirectionAndDistanceMetersView.swift
//  UrbanRecorder
//
//  Created by ting hui wu on 2021/11/11.
//

import SwiftUI
import Neumorphic

struct DirectionAndDistanceView: View {
    
    var directionType: DirectionType
    
    var closeButtonDidClick: (()->Void)
    
    var receiverDirection: Double
    
    @Binding var receiverMeters: Double
    
    @Binding var isSetStaticDistance: Bool
    
    var udpsocketLatenctMs: UInt64
    
    var udpsocketLatenctMsString: String {
        return udpsocketLatenctMs == 0 ? "" : "\(udpsocketLatenctMs) MS"
    }
    
    var volumeMaxPeakPercentage: Double
    
    var showWave: Bool
    
    var distanceMeteDidClicked: (()->Void)
    
    var resetAnchorDegreesDidClicked: (()->Void)
    
    var increaseButtonDidClicked: (()->Void)
    
    var decreaseButtonDidClicked: (()->Void)
    
    var increaseButtonOnLongpress: (()->Void)
    
    var decreaseButtonOnLongpress: (()->Void)
    
    let cornerRadius : CGFloat = 15
    let mainColor = Color.Neumorphic.main
    let secondaryColor = Color.Neumorphic.secondary
    
    let redDotSize: CGSize = CGSize(width: 25, height: 25)
    
    init(directionType: DirectionType,
         closeButtonDidClick:@escaping (()->Void),
         udpsocketLatenctMs: UInt64,
         receiverDirection: Double,
         receiverMeters: Binding<Double>,
         isSetStaticDistance:Binding<Bool>,
         showWave: Bool,
         volumeMaxPeakPercentage: Double,
         distanceMeteDidClicked: @escaping (()->Void),
         resetAnchorDegreesDidClicked: @escaping (()->Void),
         increaseButtonDidClicked: @escaping (()->Void),
         decreaseButtonDidClicked: @escaping (()->Void),
         increaseButtonOnLongpress: @escaping (()->Void),
         decreaseButtonOnLongpress: @escaping (()->Void)) {
        self.directionType = directionType
        self.closeButtonDidClick = closeButtonDidClick
        self.udpsocketLatenctMs = udpsocketLatenctMs
        self.receiverDirection = receiverDirection
        self._receiverMeters = receiverMeters
        self._isSetStaticDistance = isSetStaticDistance
        self.showWave = showWave
        self.volumeMaxPeakPercentage = volumeMaxPeakPercentage
        self.distanceMeteDidClicked = distanceMeteDidClicked
        self.resetAnchorDegreesDidClicked = resetAnchorDegreesDidClicked
        self.increaseButtonDidClicked = increaseButtonDidClicked
        self.decreaseButtonDidClicked = decreaseButtonDidClicked
        self.increaseButtonOnLongpress = increaseButtonOnLongpress
        self.decreaseButtonOnLongpress = decreaseButtonOnLongpress
    }
    
    var body: some View {
        
            // Adjust user motion by reset anchor degrees
            HStack(alignment: .center, spacing: 0.0){
                GeometryReader{ reader in
                    ZStack{
                        switch directionType {
                        case .compass:
                            ZStack{
                                Circle().stroke(Color.Neumorphic.main, style: StrokeStyle(lineWidth: 2, lineCap: .round, lineJoin: .round))
                                Circle().fill(mainColor).softInnerShadow(Circle())
                            }.frame(width: reader.size.height, height: reader.size.height)
                                
                            ZStack{
                            Circle().fill(mainColor).softOuterShadow()
                            Circle().stroke(Color.Neumorphic.main, style: StrokeStyle(lineWidth: 2, lineCap: .round, lineJoin: .round))
                            }.frame(width: reader.size.height - (redDotSize.width * 2), height: reader.size.height - (redDotSize.height * 2))
                            //RedDot
                            ZStack {
                                Circle().fill(.red)
                                    .scaleEffect(0.75)
                                    .softOuterShadow(offset: 2, radius: 2)
                                    .rotationEffect(.degrees(-receiverDirection))
                                Circle().fill(.red)
                                    .scaleEffect(0.7)
                                    .softInnerShadow(Circle(), darkShadow: .black, lightShadow: .pink, spread: 0, radius: 2)
                                    .rotationEffect(.degrees(-receiverDirection))
                                Circle().stroke(Color.Neumorphic.main, style: StrokeStyle(lineWidth: 1, lineCap: .round, lineJoin: .round))
                                    .scaleEffect(0.7)
                            }
                            .offset(x: 0, y: -reader.frame(in: .local).height/2 + redDotSize.height/2)
                            .frame(width: redDotSize.width, height: redDotSize.height)
                            .rotationEffect(.degrees(receiverDirection))
                            .animation(.easeInOut(duration: 0.2), value: receiverDirection)
                            
                        case .arrow:
                            // Arrow
                            ZStack {
                                Circle().stroke(Color.Neumorphic.main, style: StrokeStyle(lineWidth: 2, lineCap: .round, lineJoin: .round))
                                Circle().fill(mainColor).frame(width: reader.size.height, height: reader.size.height)
                                    .softInnerShadow(Circle())
                                
                                Arrow()
                                    .fill(.red, style: FillStyle())
//                                    .softOuterShadow(offset: 2, radius: 2)
                                    .offset(x: 0, y: -reader.frame(in: .local).height/2 + reader.frame(in: .local).height/8)
                                    .frame(width: reader.frame(in: .local).height/4, height: reader.frame(in: .local).height/4)
                                    .rotationEffect(.degrees(receiverDirection))
                                    .animation(.easeInOut(duration: 0.2), value: receiverDirection)
                            }.softOuterShadow()
                        }
                        
                        // Peak Wave
                        NeumorphicWaveView()
                            .scaleEffect(showWave ? volumeMaxPeakPercentage : showWave ? 0.4 : 0.01)
                            .opacity(showWave ? 0.1 : 1)
                        NeumorphicWaveView()
                            .scaleEffect(showWave ? volumeMaxPeakPercentage * 0.7 : showWave ? 0.3 : 0.01)
                            .opacity(showWave ? 0.1 : 1)
                        NeumorphicWaveView()
                            .scaleEffect(showWave ? volumeMaxPeakPercentage * 0.5 : showWave ? 0.2 : 0.01)
                            .opacity(showWave ? 0.1 : 1)
                        // Distance Meter Button
                        
                        VStack{
                            if isSetStaticDistance {
                                Button {
                                    increaseButtonDidClicked()
                                } label: {
                                    Image(systemName: "chevron.up")
                                        .resizable()
                                        .renderingMode(.template)
                                        .scaleEffect(0.7)
                                        .softOuterShadow(offset: 2, radius: 0.5)
                                        .tint(Color.Neumorphic.secondary)
                                        .frame(width: 20, height: 10)
                                }.simultaneousGesture(LongPressGesture().onEnded { _ in
                                    increaseButtonOnLongpress()
                                })
                            }
                            
                            Button(action: {
                                distanceMeteDidClicked()
                            }) {
                                Text(receiverMeters.toDisplayDistance())
                                    .frame(width: reader.frame(in: .local).height/2.5)
                                    .customFont(style: .caption1, weight: .light)
                                    .lineLimit(1)
                            }.softButtonStyle(RoundedRectangle(cornerRadius: 5), padding: 5, isPressed: isSetStaticDistance)
                                .disabled(true)
                            
                            if isSetStaticDistance {
                                Button {
                                    decreaseButtonDidClicked()
                                } label: {
                                    Image(systemName: "chevron.down")
                                        .resizable()
                                        .renderingMode(.template)
                                        .scaleEffect(0.7)
                                        .softOuterShadow(offset: 2, radius: 0.5)
                                        .tint(Color.Neumorphic.secondary)
                                        .frame(width: 20, height: 10)
                                }.simultaneousGesture(LongPressGesture().onEnded { _ in
                                    decreaseButtonOnLongpress()
                                })
                            }
                        }
                        
                        VStack{
//                            HStack{
//                                Button {
//                                    print("Next type")
//                                } label: {
//                                    Image(systemName: "arrowtriangle.right.fill")
//                                        .resizable()
//                                        .renderingMode(.template)
//                                        .scaleEffect(0.7)
//                                        .softOuterShadow(offset: 2, radius: 0.5)
//                                        .tint(Color.Neumorphic.secondary)
//                                        .frame(width: 20, height: 20)
//                                }
//
//                                Spacer()
//                            }
                            Spacer()
                            HStack{
                                Button {
                                    print("Show description")
                                } label: {
                                    Image(systemName: "questionmark.circle")
                                        .resizable()
                                        .renderingMode(.template)
                                        .scaleEffect(0.7)
                                        .softOuterShadow(offset: 2, radius: 0.5)
                                        .tint(Color.Neumorphic.secondary.opacity(0.5))
                                        .frame(width: 20, height: 20)
                                }

                                Spacer()
                            }
                        }
                    }
                    .frame(width: reader.frame(in: .local).height, height: reader.frame(in: .local).height)
                }.aspectRatio(1, contentMode: .fit)
                    .padding(5)
                
                VStack(alignment: .trailing) {
                    Button {
                        closeButtonDidClick()
                    } label: {
                        ZStack(){
                            RoundedRectangle(cornerRadius: 5).frame(width: 15, height: 2)
                                .rotationEffect(Angle(degrees: 45))
                                .foregroundColor(Color.Neumorphic.secondary)
                                .softOuterShadow()
                            RoundedRectangle(cornerRadius: 5).frame(width: 15, height: 2)
                                .rotationEffect(Angle(degrees: -45))
                                .foregroundColor(Color.Neumorphic.secondary)
                                .softOuterShadow()
                        }.frame(width: 30, height: 30)
                    }
                    Spacer()
                    Button(action: {
                        resetAnchorDegreesDidClicked()
                    }) {
                        Image(systemName: "pin")
                            .softOuterShadow(offset: 2, radius: 0.5)
                            .tint(Color.Neumorphic.secondary)
                            .frame(width: 30, height: 30)
                    }
                    Spacer()
                    HStack{
                        Spacer()
                        Text(udpsocketLatenctMsString)
                            .customFont(style: .caption1, weight: .light)
                            .foregroundColor(Color.Neumorphic.secondary.opacity(0.5))
                            .lineLimit(1)
                            .frame(height: 30)
                    }
                    
                }.padding(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0))
                    .frame(width: 50)
            }
            .padding(5)
            .background(Color.Neumorphic.main)
            .clipShape(RoundedRectangle(cornerRadius: 10))
    }
    
    enum DirectionType {
        case compass
        case arrow
    }
}

struct DirectionAndDistanceView_Previews: PreviewProvider {
    static var previews: some View {
        
        DirectionAndDistanceView(directionType: .arrow,closeButtonDidClick: {}, udpsocketLatenctMs: 11, receiverDirection: 0, receiverMeters: .constant(5), isSetStaticDistance: .constant(false), showWave: false, volumeMaxPeakPercentage: 0.8) {
            
        } resetAnchorDegreesDidClicked: {
            
        } increaseButtonDidClicked: {
            
        } decreaseButtonDidClicked: {
            
        } increaseButtonOnLongpress: {
            
        } decreaseButtonOnLongpress: {
            
        }
        
        DirectionAndDistanceView(directionType: .compass,closeButtonDidClick: {}, udpsocketLatenctMs: 11, receiverDirection: 0, receiverMeters: .constant(5), isSetStaticDistance: .constant(false), showWave: false, volumeMaxPeakPercentage: 0.8) {
            
        } resetAnchorDegreesDidClicked: {
            
        } increaseButtonDidClicked: {
            
        } decreaseButtonDidClicked: {
            
        } increaseButtonOnLongpress: {
            
        } decreaseButtonOnLongpress: {
            
        }
    }
}
