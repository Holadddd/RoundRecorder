//
//  DirectionAndDistanceMetersView.swift
//  UrbanRecorder
//
//  Created by ting hui wu on 2021/11/11.
//

import SwiftUI
import Neumorphic

struct DirectionAndDistanceMetersView: View {
    var receiverDirection: Double
    @Binding var receiverMeters: Double
    
    var udpsocketLatenctMs: UInt64
    
    var udpsocketLatenctMsString: String {
        return udpsocketLatenctMs == 0 ? "MS:" : "MS: \(udpsocketLatenctMs)"
    }
    
    var volumeMaxPeakPercentage: Double
    
    var showWave: Bool
    
    var distanceMeteDidClicked: (()->Void)
    
    var resetAnchorDegreesDidClicked: (()->Void)
    
    let cornerRadius : CGFloat = 15
    let mainColor = Color.Neumorphic.main
    let secondaryColor = Color.Neumorphic.secondary
    
    let redDotSize: CGSize = CGSize(width: 25, height: 25)
    
    let compassWidth:CGFloat = UIScreen.main.bounds.width * 0.8
    
    init(udpsocketLatenctMs: UInt64, receiverDirection: Double, receiverMeters: Binding<Double>, showWave: Bool, volumeMaxPeakPercentage: Double, distanceMeteDidClicked: @escaping (()->Void), resetAnchorDegreesDidClicked: @escaping (()->Void)) {
        self.udpsocketLatenctMs = udpsocketLatenctMs
        self.receiverDirection = receiverDirection
        self._receiverMeters = receiverMeters
        self.showWave = showWave
        self.volumeMaxPeakPercentage = volumeMaxPeakPercentage
        self.distanceMeteDidClicked = distanceMeteDidClicked
        self.resetAnchorDegreesDidClicked = resetAnchorDegreesDidClicked
    }
    
    var body: some View {
        
        // Adjust user motion by reset anchor degrees
        ZStack {
            VStack(alignment: .center, spacing: 0) {
                HStack(alignment: VerticalAlignment.center) {
                    Text(udpsocketLatenctMsString)
                        .foregroundColor(.fixedLightGray)
                    Spacer()
                    Button(action: {
                        resetAnchorDegreesDidClicked()
                    }) {
                        Image(systemName: "pin")
                            .frame(width: 5, height: 5, alignment: .center)
                    }.softButtonStyle(Circle())
                        .disabled(false)
                }.padding(EdgeInsets(top: 0, leading: 5, bottom: 5, trailing: 5))
                Spacer()
            }
            
            GeometryReader{ reader in
                ZStack{
                    Circle().fill(mainColor).frame(width: reader.size.width, height: reader.size.height)
                        .softInnerShadow(Circle(), spread: 0.05)
                    
                    Circle().fill(mainColor).frame(width: reader.size.width - (redDotSize.width * 2), height: reader.size.height - (redDotSize.height * 2))
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
                    .offset(x: 0, y: -reader.size.height/2 + redDotSize.height/2)
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
                        Text("\(receiverMeters.string(fractionDigits: 2)) M").font(.title).fontWeight(.heavy)
                    }.softButtonStyle(RoundedRectangle(cornerRadius: cornerRadius))
                        .disabled(true)
                    
                }.aspectRatio(1, contentMode: .fit)
            }.frame(width: compassWidth, height: compassWidth, alignment: .center)
        }
    }
}

struct DirectionAndDistanceMetersView_Previews: PreviewProvider {
    static var previews: some View {
        
        DirectionAndDistanceMetersView(udpsocketLatenctMs: 11, receiverDirection: 315, receiverMeters: .constant(5), showWave: false, volumeMaxPeakPercentage: 0.8) {
            
        } resetAnchorDegreesDidClicked: {
            
        }

    }
}
