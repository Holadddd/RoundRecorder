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
    
    var volumeMaxPeakPercentage: Double
    
    var showWave: Bool
    
    var distanceMeteDidClicked: (()->Void)
    
    var resetAnchorDegreesDidClicked: (()->Void)
    
    let cornerRadius : CGFloat = 15
    let mainColor = Color.Neumorphic.main
    let secondaryColor = Color.Neumorphic.secondary
    
    let redDotSize: CGSize = CGSize(width: 25, height: 25)
    
    init(receiverDirection: Double, receiverMeters: Binding<Double>, showWave: Bool, volumeMaxPeakPercentage: Double, distanceMeteDidClicked: @escaping (()->Void), resetAnchorDegreesDidClicked: @escaping (()->Void)) {
        self.receiverDirection = receiverDirection
        self._receiverMeters = receiverMeters
        self.showWave = showWave
        self.volumeMaxPeakPercentage = volumeMaxPeakPercentage
        self.distanceMeteDidClicked = distanceMeteDidClicked
        self.resetAnchorDegreesDidClicked = resetAnchorDegreesDidClicked
    }
    
    var body: some View {
        GeometryReader{ reader in
            ZStack {
                
                ZStack{
                    Circle().fill(mainColor).frame(width: reader.size.width, height: reader.size.height)
                        .softInnerShadow(Circle(), spread: 0.05)
                    
                    //                Canvas { context, size in
                    //                    context.withCGContext { cgContext in
                    //                        let rect = CGRect(origin: .zero, size: size).insetBy(dx: 20, dy: 20)
                    //                        let path = CGPath(ellipseIn: rect, transform: nil)
                    //                        cgContext.addPath(path)
                    //                        cgContext.setStrokeColor(UIColor.black.cgColor)
                    //                        cgContext.setFillColor(UIColor.green.cgColor)
                    //                        cgContext.setLineWidth(10)
                    //                        cgContext.setAlpha(0.5)
                    //                        cgContext.drawPath(using: .eoFillStroke)
                    //
                    //                    }
                    //
                    //                    context.withCGContext { cgContext in
                    //                        let midPoint = CGPoint(x: size.width/2.0, y: size.height/2.0)
                    //                        let text = Text("\(receiverMeters.string(fractionDigits: 2)) M").font(.title).fontWeight(.heavy)
                    //                        context.blendMode = GraphicsContext.BlendMode.softLight
                    //                        context.draw(text, at: midPoint)
                    //                    }
                    //                }
                    //
                    //                Canvas { context, size in
                    //
                    //                    context.withCGContext { cgContext in
                    //                        let midPoint = CGPoint(x: size.width/2.0, y: size.height/2.0)   // ZStack is scaled to fit the size(squre), the weight and width are same value
                    //                        let nexPoint = CGPoint(x: size.width/2.0, y: 0)
                    //                        cgContext.move(to: nexPoint)
                    //                        cgContext.setStrokeColor(UIColor.red.cgColor)
                    //                        cgContext.setLineWidth(10)
                    //                        cgContext.addLine(to: midPoint)
                    //                        cgContext.drawPath(using: CGPathDrawingMode.eoFillStroke)
                    //                    }
                    //                }.rotationEffect(.degrees(receiverDirection))
                    
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
                        .disabled(false)
                    
                }
                .scaledToFit()
                .scaleEffect(1)
                // Adjust user motion by reset anchor degrees
                Button(action: {
                    resetAnchorDegreesDidClicked()
                }) {
                    Image(systemName: "pin")
                        .frame(width: 5, height: 5, alignment: .center)
                        .padding(0)
                }.softButtonStyle(Circle())
                    .ignoresSafeArea()
                    .disabled(false)
                    .offset(x: reader.frame(in: .local).maxX / 2, y:  -(reader.frame(in: .local).maxY/2))
                
                
            }.padding(5)
        }
    }
}

struct DirectionAndDistanceMetersView_Previews: PreviewProvider {
    static var previews: some View {
        
        DirectionAndDistanceMetersView(receiverDirection: 315, receiverMeters: .constant(5), showWave: false, volumeMaxPeakPercentage: 0.8) {
            
        } resetAnchorDegreesDidClicked: {
            
        }

    }
}
