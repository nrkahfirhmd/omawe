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

                BottomActionBar()
            }
            .padding(.horizontal, 18)
            .padding(.vertical)
        }
    }
}

#Preview {
    LocationView()
}
