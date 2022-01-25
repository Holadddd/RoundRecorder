//
//  ICon.swift
//  RoundRecorder
//
//  Created by ting hui wu on 2022/1/25.
//

import SwiftUI
import Neumorphic

struct ICon: View {
    
    var gradient: LinearGradient = {
        let gradient = LinearGradient(gradient:
                                        Gradient(colors: [Color.red,Color.red]),
                                      startPoint: .topLeading,
                                     endPoint: .bottomTrailing)
        
        return gradient
    }()
    
    var body: some View {
        ZStack{
            Rectangle().fill(Color.Neumorphic.main)
            
            ZStack{
                Path { path in
                    let width = UIScreen.main.bounds.width
                    let height = UIScreen.main.bounds.height
                    
                    let x1: CGFloat = width * 0.62
                    let y1 = width - 5
                    
                    let y2 = y1 - 84
                    // 2.
                    path.addLines( [
                        CGPoint(x: width - x1, y: y2),
                        CGPoint(x: width - x1, y:  y1 - 130)
                        
                    ])
                    
                    let x3: CGFloat = width * 0.385
                    
                    let x5: CGFloat = width * 0.33
                    // 3.)
                    path.addLines( [
                        CGPoint(x: width - x3, y: y1 - 125),
                        CGPoint(x: width - x5, y:  y2)
                    ])
                    // 4. Circle
                    let cx1: CGFloat = width/2 - 100
                    let cy1: CGFloat = width/2 - 130
                    
                    path.addEllipse(in: CoreGraphics.CGRect(x: cx1, y: cy1, width: 200, height: 200))
                    
                    // 5.
                    path.closeSubpath()
                }.strokedPath(StrokeStyle(lineWidth: 20, lineCap: .round, lineJoin: .round))
                    .fill(gradient)
                    .softOuterShadow(offset: 2, radius: 2)
                    .softOuterShadow(offset: 6 , radius: 3)
                
                Path { path in
                    let width = UIScreen.main.bounds.width
                    let height = UIScreen.main.bounds.height
                    
                    // 4. Circle
                    let cx1: CGFloat = width/2 - 30
                    let cy1: CGFloat = width/2 - 60
                    
                    path.addEllipse(in: CoreGraphics.CGRect(x: cx1, y: cy1, width: 60, height: 60))
                    
                    // 5.
                    path.closeSubpath()
                }.fill(gradient)
                    .softOuterShadow(offset: 2, radius: 2)
                    .softOuterShadow(offset: 6 , radius: 3)
            }.offset(x: 0, y: 10)
            
        }.aspectRatio(1, contentMode: .fit)
            .frame(width:  UIScreen.main.bounds.width, height:  UIScreen.main.bounds.width)
        
        
    }
}

struct ICon_Previews: PreviewProvider {
    static var previews: some View {
        ICon()
            .environment(\.colorScheme, .light)
        
        ICon()
            .environment(\.colorScheme, .dark)
    }
}
