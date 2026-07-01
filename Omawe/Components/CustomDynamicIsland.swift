//
//  CustomDynamicIsland.swift
//  Omawe
//
//  Created by Muhammad Bintang Al-Fath on 01/07/26.
//

import SwiftUI

struct CustomDynamicIsland: View {
    private let color: LinearGradient
    private let borderWidth: CGFloat
    private let width: CGFloat
    private let height: CGFloat
    
    init(
        color: LinearGradient = LinearGradient(stops: [
            .init(color: Color.omawePrimary, location: 0),
            .init(color: Color.omawePrimarySoft, location: 0.51),
            .init(color: Color.omawePrimary, location: 1),
        ], startPoint: .top, endPoint: UnitPoint.bottom),
        borderWidth: CGFloat = 0,
        width: CGFloat = 126,
        height: CGFloat = 37
    ) {
        self.color = color
        self.borderWidth = borderWidth
        self.width = width
        self.height = height
    }
    
    var body: some View {
        ZStack {
            Capsule()
                .fill(.white)
                .overlay {
                    Capsule(style: .continuous)
                        .fill(.white)
                        .stroke(
                            color, lineWidth: 1)
                }
                .frame(width: width+10, height: height+10)
            
            Capsule(style: .continuous)
                .fill(.white)
                .overlay {
                    Capsule(style: .continuous)
                        .fill(color)
                }
                .frame(width: width, height: height)
        }
    }
}

#Preview {
    ZStack {
        Color(.systemGray6)
            .ignoresSafeArea()
        
        CustomDynamicIsland(
            color: LinearGradient(stops: [
                .init(color: Color.omawePrimary, location: 0),
                .init(color: Color.omawePrimarySoft, location: 0.51),
                .init(color: Color.omawePrimary, location: 1),], startPoint: .top, endPoint: UnitPoint.bottom),
            borderWidth: 2,
            width: 126,
            height: 37
        )
    }
}
