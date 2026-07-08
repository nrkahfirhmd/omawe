//
//  TripHeaderCard.swift
//  Omawe
//
//  Created by Nurkahfi Rahmada on 06/07/26.
//

import SwiftUI

struct TripHeaderCard: View {
    @Binding var isExpanded: Bool

    var body: some View {
        VStack(spacing: 12) {
            TripHeader()

            HeaderStats()

            if isExpanded {
                Divider()
                    .background(Color.white)

                ExpandedContent()
                    .transition(
                        .asymmetric(
                            insertion: .move(edge: .bottom).combined(with: .opacity),
                            removal: .opacity
                        )
                    )
            }
            
            VStack {
                Capsule()
                    .frame(width: 75, height: 5)
            }
            .padding(.bottom, 6)
        }
        .padding(.horizontal, 24)
        .padding(.top, 56)
        .frame(maxWidth: .infinity)
        .background(GridGradientBackground(color: Theme.secondaryBox))
        .clipShape(RoundedRectangle(cornerRadius: 35))
        .animation(.spring(duration: 0.45), value: isExpanded)
        .foregroundStyle(.white)
    }
}

private struct TripHeader: View {
    var body: some View {
        VStack(spacing: 6) {
            Text("Ex-Boyfriends Celebration!")
                .font(.headline())
                .fontWeight(.bold)
                .multilineTextAlignment(.center)

            Text("by @\(UserSession.shared.displayName ?? "Anonymous") • 27/06/2026 • 11:30")
                .font(.caption1())
                .foregroundStyle(.secondary)
        }
        .foregroundStyle(.white)
    }
}

private struct HeaderStats: View {
    var body: some View {
        HStack(spacing: 0) {
            stat(title: "People", value: "12")

            Divider()
                .frame(height: 70)
                .background(Color.white)

            stat(title: "ETA", value: "11:00", color: .yellow)

            Divider()
                .frame(height: 70)
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

private struct ExpandedContent: View {
    var body: some View {
        VStack(spacing: 28) {
            Button {
            } label: {
                Label("Gonna be late", systemImage: "message.badge")
                    .padding(.horizontal)
                    .font(.caption1())
            }
            .buttonStyle(.borderedProminent)
            .tint(.brown.opacity(0.8))

            HStack {
                Button {
                } label: {
                    Image(systemName: "chevron.left")
                        .font(.title2.bold())
                        .frame(width: 54, height: 54)
                        .background(.ultraThinMaterial)
                        .clipShape(Circle())
                }

                Spacer()

                Text("Bingtang")
                    .font(.title3())
                    .fontWidth(.expanded)

                Spacer()

                Button {
                } label: {
                    Image(systemName: "chevron.right")
                        .font(.title2.bold())
                        .frame(width: 54, height: 54)
                        .background(.ultraThinMaterial)
                        .clipShape(Circle())
                }
            }

            HStack(spacing: 16) {
                Image(systemName: "location.fill")
                Capsule().fill(.white.opacity(0.35)).frame(height: 6)
                Image(systemName: "flag.fill")
            }
        }
        .padding(.top, 8)
    }
}

#Preview {
    TripHeaderCard(isExpanded: .constant(false))
}
