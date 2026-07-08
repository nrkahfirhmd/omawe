//
//  PermissionView.swift
//  Omawe
//
//  Created by Nurkahfi Rahmada on 08/07/26.
//

import SwiftUI
import Lottie
import CoreLocation

struct PermissionView: View {
    let onNext: () -> Void

    @State private var phase = 0
    @StateObject private var locationManager = LocationPermissionManager()
    
    private var allPermissionsGranted: Bool {
        locationManager.locationGranted && locationManager.backgroundGranted
    }
    
    var body: some View {
        ZStack {
            Image("DarkBlueBackground")
                .resizable()
                .scaledToFill()
                .ignoresSafeArea()

            SpotlightBeam()

            VStack {
                Spacer()

                ZStack {
                    ZStack {
                        Circle()
                            .stroke(Color.white.opacity(0.8), lineWidth: 10)
                            .frame(width: 150, height: 150)
                        
                        Image(systemName: "hand.raised.fill")
                            .font(.system(size: 90))
                            .foregroundStyle(.white.opacity(0.8))
                    }
                    
                    VStack {
                        Text("Share your journey")
                            .font(.title1())
                            .fontWeight(.bold)
                            .fontWidth(.expanded)

                        Text("Grant a couple of permissions so meeting up feels effortless.")
                            .multilineTextAlignment(.center)
                            .font(.caption1())
                            .padding(.bottom, 30)
                    }
                    .foregroundStyle(.white)
                    .padding(.top, 200)
                    .shadow(
                        color: .black.opacity(0.6),
                        radius: 10,
                        x: 0,
                        y: 0
                    )
                }

                VStack(spacing: 18) {
                    PermissionCard(
                        icon: "location.fill.viewfinder",
                        title: "Location",
                        description: "Omawe shares your trip status and ETA with companions using your location.",
                        granted: locationManager.locationGranted
                    )

                    PermissionCard(
                        icon: "app.badge",
                        title: "Background Activity",
                        description: "Continue sharing your location while Omawe is in the background.",
                        granted: locationManager.backgroundGranted
                    )
                    
                    HStack {
                        Image(systemName: "lock")
                        
                        Text("Your location is only shared during trips you choose to join.")
                    }
                    .font(.caption2())
                    .foregroundStyle(.white.secondary)
                }
                
                Spacer()

                Button {
                    HapticManager.shared.boom()
                    
                    if allPermissionsGranted {
                        onNext()
                    } else {
                        locationManager.requestPermissions()
                    }
                } label: {
                    Text(allPermissionsGranted ? "Next" : "Allow All Access")
                        .fontWeight(.bold)
                        .fontWidth(.expanded)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 22)
                        .background(
                            Capsule()
                                .fill(
                                    LinearGradient(
                                        colors: [
                                            Color(hex: "03B9D6"),
                                            Color(hex: "7AE8FF")
                                        ],
                                        startPoint: .top,
                                        endPoint: .bottom
                                    )
                                )
                        )
                }
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 48)
        }
        .onChange(of: locationManager.locationGranted) { oldValue, newValue in
            if !oldValue && newValue {
                HapticManager.shared.tickTickTick()
            }
        }
        .onChange(of: locationManager.backgroundGranted) { oldValue, newValue in
            if !oldValue && newValue {
                HapticManager.shared.tickTickTick()
            }
        }
    }
    
    struct PermissionCard: View {
        let icon: String
        let title: String
        let description: String
        let granted: Bool
        
        private var accent: Color {
            granted ? Color(hex: "03B9D6") : .gray
        }

        private var textColor: Color {
            granted ? .white : .gray
        }

        var body: some View {
            HStack(spacing:13) {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: granted
                                ? [Color(hex:"03B9D6"), Color(hex:"7AE8FF")]
                                : [.gray.opacity(0.5), .gray],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width:50, height:50)
                    .overlay {
                        Image(systemName: icon)
                            .font(.title3)
                            .foregroundStyle(textColor)
                    }

                VStack(alignment:.leading, spacing:6){
                    Text(title)
                        .font(.button())
                        .fontWidth(.expanded)

                    Text(description)
                        .font(.caption1())
                }
                .foregroundStyle(textColor)

                Spacer()
            }
            .padding(16)
            .background(
                granted
                    ? .white.opacity(0.10)
                    : .white.opacity(0.04)
            )
            .clipShape(RoundedRectangle(cornerRadius:30))
            .overlay {
                RoundedRectangle(cornerRadius: 30)
                    .stroke(
                        granted
                            ? .white.opacity(0.5)
                            : .white.opacity(0.15)
                    )
            }
        }
    }
}

#Preview {
    PermissionView {
        debugLog("Next tapped")
    }
}
