//
//  DirectionAndDistanceMetersView.swift
//  UrbanRecorder
//
//  Created by ting hui wu on 2021/11/11.
//

import SwiftUI

struct DirectionAndDistanceMetersView: View {
    @Binding var directionDegrees: Double
    @Binding var distanceMeter: Double
    
    var body: some View {
        GeometryReader{ reader in
            VStack{
                Text("Direction: \(String(format:"%.0f", directionDegrees))")
                Text("Disance: \(String(format:"%.2f", distanceMeter)) m")
            }
        }
    }
}

struct DirectionAndDistanceMetersView_Previews: PreviewProvider {
    static var previews: some View {
        
        DirectionAndDistanceMetersView(directionDegrees: .constant(315), distanceMeter: .constant(5))
    }
}
