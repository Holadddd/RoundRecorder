//
//  NeumorphicWaveView.swift
//  RoundRecorder
//
//  Created by ting hui wu on 2021/11/20.
//

import SwiftUI
import Neumorphic

struct NeumorphicWaveView: View {
    var body: some View {
        GeometryReader{ reader in
            ZStack {
                Circle().fill(Color.Neumorphic.main)
                    .scaleEffect(1)
                    .softOuterShadow(darkShadow: Color.Neumorphic.darkShadow, lightShadow: Color.Neumorphic.lightShadow, offset: reader.frame(in: .local).width / 25, radius: reader.frame(in: .local).width / 50)
                Circle().fill(Color.Neumorphic.main)
                    .scaleEffect(1)
                    .softInnerShadow(Circle(), darkShadow: Color.Neumorphic.lightShadow, lightShadow: Color.Neumorphic.darkShadow, spread: 0.07, radius: reader.frame(in: .local).width / 50)
                Circle().fill(Color.Neumorphic.main)
                    .softOuterShadow(darkShadow: Color.Neumorphic.lightShadow, lightShadow: Color.Neumorphic.darkShadow, offset: reader.frame(in: .local).width / 70, radius: reader.frame(in: .local).width / 80)
                    .scaleEffect(0.98)
                Circle().fill(Color.Neumorphic.main)
                    .softInnerShadow(Circle(), darkShadow: Color.Neumorphic.darkShadow, lightShadow: Color.Neumorphic.lightShadow, spread: 0.07, radius: reader.frame(in: .local).width / 80)
                    .scaleEffect(0.98)
                
            }.scaleEffect(0.9)
        }.scaledToFit()
    }
}

struct NeumorphicWaveView_Previews: PreviewProvider {
    static var previews: some View {
        NeumorphicWaveView()
    }
}
