//
//  OnTripView.swift
//  Omawe
//
//  Created by Nurkahfi Rahmada on 07/07/26.
//

import SwiftUI

struct OnTripView: View {
    var body: some View {
        DynamicBox(
            theme: Theme.themeTertiary,
            icon: "",
            title: "Ex-boyfriends Celebration",
            subtitle: "by @Bintang • 27/06/2026 • 11:30",
            helperText: "",
            footerTitle: "You are in Bintang's Trip"
        ) {
//            ZStack {
//                GIFView(name: "on_trip")
//                    .ignoresSafeArea()
//                    .frame(width: .infinity)
//                    .frame(height: 220)
//                    .mask(
//                        LinearGradient(
//                            stops: [
//                                .init(color: .clear, location: 0),
//                                .init(color: .white, location: 0.25),
//                                .init(color: .white, location: 0.85),
//                                .init(color: .clear, location: 1)
//                            ],
//                            startPoint: .top,
//                            endPoint: .bottom
//                        )
//                    )
//
//                LinearGradient(
//                    colors: [
//                        .black.opacity(0.7),
//                        .clear,
//                        .black.opacity(0.95)
//                    ],
//                    startPoint: .top,
//                    endPoint: .bottom
//                )
//                .ignoresSafeArea()
//            }
            
            VStack(spacing: 14) {
                HStack(spacing: 16) {
                    Image(systemName: "location.fill")
                    Capsule().fill(.white.opacity(0.35)).frame(height: 6)
                    Image(systemName: "flag.fill")
                }
                
                VStack(spacing: 12) {
                    Label("Toko Kopi Jaya, Kuta", systemImage: "location")
                        .font(.caption1().bold())
                    
                    HeaderStats()
                    
                    Button {
                        
                    } label: {
                        ZStack {
                            Capsule()
                                .foregroundStyle(.ultraThinMaterial)
                                .frame(width: .infinity, height: 50)
                            
                            Label("View on Map", systemImage: "map")
                                .font(.button())
                        }
                    }
                }
                .padding(12)
                .frame(maxWidth: .infinity)
                .background(GridGradientBackground(color: Theme.tertiaryBox))
                .border(Color.white.opacity(0.1), width: 2)
                .clipShape(RoundedRectangle(cornerRadius: 35))
            }
            .padding(.horizontal, 24)
        }
        .transition(.scale(scale: 0.18, anchor: .top).combined(with: .opacity))
    }
}

private struct HeaderStats: View {
    var body: some View {
        HStack(spacing: 0) {
            stat(title: "People", value: "12", color: .omawePrimary)

            Divider()
                .frame(height: 40)
                .background(Color.white)

            stat(title: "ETA", value: "11:00", color: .yellow)

            Divider()
                .frame(height: 40)
                .background(Color.white)
            
            stat(title: "Distance", value: "15km", color: .yellow)
        }
    }

    @ViewBuilder
    private func stat(title: String, value: String, color: Color = .white) -> some View {
        VStack(spacing: 4) {
            Text(title)
                .font(.caption2())
                .fontWeight(.semibold)
                .foregroundStyle(.secondary)

            Text(value)
                .font(.button())
                .foregroundStyle(color)
                .fontWidth(.expanded)
        }
        .frame(maxWidth: .infinity)
    }
}

#Preview {
    OnTripView()
}
