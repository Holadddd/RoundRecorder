//
//  DirectionAndDistanceMetersView.swift
//  UrbanRecorder
//
//  Created by ting hui wu on 2021/11/11.
//

import SwiftUI
import Neumorphic

struct DirectionAndDistanceMetersView: View {
    
    var closeButtonDidClick: (()->Void)
    
    var receiverDirection: Double
    
    @Binding var receiverMeters: Double
    
    @Binding var isSetStaticDistance: Bool
    
    var udpsocketLatenctMs: UInt64
    
    var udpsocketLatenctMsString: String {
        return udpsocketLatenctMs == 0 ? "" : "MS: \(udpsocketLatenctMs)"
    }
    
    var volumeMaxPeakPercentage: Double
    
    var showWave: Bool
    
    var distanceMeteDidClicked: (()->Void)
    
    var resetAnchorDegreesDidClicked: (()->Void)
    
    let cornerRadius : CGFloat = 15
    let mainColor = Color.Neumorphic.main
    let secondaryColor = Color.Neumorphic.secondary
    
    let redDotSize: CGSize = CGSize(width: 25, height: 25)
    
//    let compassWidth:CGFloat = UIScreen.main.bounds.width * 0.8
    
    init(closeButtonDidClick:@escaping (()->Void),
         udpsocketLatenctMs: UInt64,
         receiverDirection: Double,
         receiverMeters: Binding<Double>,
         isSetStaticDistance:Binding<Bool>,
         showWave: Bool,
         volumeMaxPeakPercentage: Double,
         distanceMeteDidClicked: @escaping (()->Void),
         resetAnchorDegreesDidClicked: @escaping (()->Void)) {
        self.closeButtonDidClick = closeButtonDidClick
        self.udpsocketLatenctMs = udpsocketLatenctMs
        self.receiverDirection = receiverDirection
        self._receiverMeters = receiverMeters
        self._isSetStaticDistance = isSetStaticDistance
        self.showWave = showWave
        self.volumeMaxPeakPercentage = volumeMaxPeakPercentage
        self.distanceMeteDidClicked = distanceMeteDidClicked
        self.resetAnchorDegreesDidClicked = resetAnchorDegreesDidClicked
    }
    
    var body: some View {
        
            // Adjust user motion by reset anchor degrees
            HStack(alignment: .center, spacing: 0.0){
                GeometryReader{ reader in
                    ZStack{
                        Circle().fill(mainColor).frame(width: reader.size.height, height: reader.size.height)
                            .softInnerShadow(Circle(), spread: 0.05)
                        
                        Circle().fill(mainColor).frame(width: reader.size.height - (redDotSize.width * 2), height: reader.size.height - (redDotSize.height * 2))
                            .softOuterShadow()
                        
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
                        }
                        .offset(x: 0, y: -reader.frame(in: .local).height/2 + redDotSize.height/2)
                        .frame(width: redDotSize.width, height: redDotSize.height)
                        .rotationEffect(.degrees(receiverDirection))
                        .animation(.easeInOut(duration: 0.2), value: receiverDirection)
                        
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
                        Button(action: {
                            distanceMeteDidClicked()
                        }) {
                            Text(receiverMeters.toDisplayDistance())
                                .softOuterShadow(offset: 2, radius: 2)
                                .frame(width: reader.frame(in: .local).height/2.5)
                                .customFont(style: .caption1, weight: .light)
                                .lineLimit(1)
                            
                        }.softButtonStyle(RoundedRectangle(cornerRadius: 5), padding: 5, isPressed: isSetStaticDistance)
                        
                    }
                    .frame(width: reader.frame(in: .local).height, height: reader.frame(in: .local).height)
                }.aspectRatio(1, contentMode: .fit)
                
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
                            .foregroundColor(.fixedLightGray)
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
}

struct DirectionAndDistanceMetersView_Previews: PreviewProvider {
    static var previews: some View {
        
        DirectionAndDistanceMetersView(closeButtonDidClick: {}, udpsocketLatenctMs: 11, receiverDirection: 315, receiverMeters: .constant(5), isSetStaticDistance: .constant(false), showWave: false, volumeMaxPeakPercentage: 0.8) {
            
        } resetAnchorDegreesDidClicked: {
            
        }
        
    }
}
