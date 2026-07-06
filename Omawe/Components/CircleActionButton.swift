//
//  CircleActionButton.swift
//  Omawe
//
//  Created by Nurkahfi Rahmada on 06/07/26.
//

import SwiftUI

struct CircleActionButton: View {
    let systemImage: String

    var body: some View {
        Button {
        } label: {
            Image(systemName: systemImage)
                .font(.title3)
                .foregroundStyle(.black)
                .frame(width: 62, height: 62)
                .background(.ultraThinMaterial)
                .clipShape(Circle())
        }
    }
}
