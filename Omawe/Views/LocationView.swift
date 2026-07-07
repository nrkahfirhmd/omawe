//
//  LocationView.swift
//  Omawe
//
//  Created by Muhammad Bintang Al-Fath on 30/06/26.
//

import SwiftUI
import MapKit

struct LocationView: View {
    @State private var camera: MapCameraPosition = .region(
        MKCoordinateRegion(
            center: CLLocationCoordinate2D(
                latitude: -8.748,
                longitude: 115.167
            ),
            span: MKCoordinateSpan(
                latitudeDelta: 0.12,
                longitudeDelta: 0.12
            )
        )
    )
    @State private var isHeaderExpanded = false

    var body: some View {
        ZStack {
            // MARK: Map
            Map(position: $camera)
                .ignoresSafeArea()

            // MARK: Overlay
            VStack {
                TripHeaderCard(isExpanded: $isHeaderExpanded)
                    .simultaneousGesture(
                        LongPressGesture(minimumDuration: 0)
                            .onChanged { _ in
                                withAnimation(.spring(response: 0.45, dampingFraction: 0.9)) {
                                    isHeaderExpanded = true
                                }
                            }
                            .onEnded { _ in
                                withAnimation(.spring(response: 0.45, dampingFraction: 0.9)) {
                                    isHeaderExpanded = false
                                }
                            }
                    )

                Spacer()
                
                VStack(spacing: 18) {
                    HStack(spacing: 10) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundStyle(.red)
                        
                        Text("Your report has been recorded")
                            .foregroundStyle(.red)
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 12)
                    .background(.white.opacity(0.9))
                    .clipShape(Capsule())

                    HStack(alignment: .bottom) {
                        Button {
                        } label: {
                            Image(systemName: "chevron.left")
                                .font(.title3)
                                .foregroundStyle(.black)
                                .frame(width: 62, height: 62)
                                .background(.ultraThinMaterial)
                                .clipShape(Circle())
                        }

                        Spacer()

                        Button {
                        } label: {
                            Text("Report")
                                .font(.headline)
                                .foregroundStyle(.white)
                                .frame(maxWidth: .infinity)
                                .frame(height: 58)
                                .background(.ultraThinMaterial)
                                .overlay {
                                    RoundedRectangle(cornerRadius: 28)
                                        .stroke(
                                            Color.cyan,
                                            lineWidth: 2
                                        )
                                }
                                .clipShape(
                                    Capsule()
                                )
                        }

                        Spacer()
                        
                        Button {
                        } label: {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .font(.title3)
                                .foregroundStyle(.black)
                                .frame(width: 62, height: 62)
                                .background(.ultraThinMaterial)
                                .clipShape(Circle())
                        }
                    }
                }
            }
            .padding(.horizontal, 18)
            .padding(.vertical)
        }
    }
}

#Preview {
    LocationView()
}
