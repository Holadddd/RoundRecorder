//
//  DirectionAndDistanceMetersView.swift
//  UrbanRecorder
//
//  Created by ting hui wu on 2021/11/11.
//

import SwiftUI

struct DirectionAndDistanceMetersView: View {
    var receiverDirection: Double
    @Binding var receiverMeters: Double
    
    var body: some View {
        GeometryReader{ reader in
            ZStack{
                Canvas { context, size in
                    context.withCGContext { cgContext in
                        let rect = CGRect(origin: .zero, size: size).insetBy(dx: 20, dy: 20)
                        let path = CGPath(ellipseIn: rect, transform: nil)
                        cgContext.addPath(path)
                        cgContext.setStrokeColor(UIColor.black.cgColor)
                        cgContext.setFillColor(UIColor.green.cgColor)
                        cgContext.setLineWidth(10)
                        cgContext.setAlpha(0.5)
                        cgContext.drawPath(using: .eoFillStroke)
                        
                    }
                    
                    context.withCGContext { cgContext in
                        let midPoint = CGPoint(x: size.width/2.0, y: size.height/2.0)
                        let text = Text("\(receiverMeters.string(fractionDigits: 2)) M").font(.title).fontWeight(.heavy)
                        context.blendMode = GraphicsContext.BlendMode.softLight
                        context.draw(text, at: midPoint)
                    }
                }
                
                Canvas { context, size in
                    
                    context.withCGContext { cgContext in
                        let midPoint = CGPoint(x: size.width/2.0, y: size.height/2.0)   // ZStack is scaled to fit the size(squre), the weight and width are same value
                        let nexPoint = CGPoint(x: size.width/2.0, y: 0)
                        cgContext.move(to: nexPoint)
                        cgContext.setStrokeColor(UIColor.white.cgColor)
                        cgContext.setLineWidth(3)
                        cgContext.addLine(to: midPoint)
                        cgContext.drawPath(using: CGPathDrawingMode.eoFillStroke)
                    }
                }.rotationEffect(.degrees(receiverDirection))
                
            }
            .scaledToFit()
        }
    }
}

struct DirectionAndDistanceMetersView_Previews: PreviewProvider {
    static var previews: some View {
        
        DirectionAndDistanceMetersView(receiverDirection: 315, receiverMeters: .constant(5))
    }
}
