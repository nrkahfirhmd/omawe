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
        VStack(spacing: 18) {
            TripHeader()

            HeaderStats()

            if isExpanded {
                Divider()

                ExpandedContent()
                    .transition(
                        .asymmetric(
                            insertion: .move(edge: .bottom).combined(with: .opacity),
                            removal: .opacity
                        )
                    )
            }
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 35))
        .animation(.spring(duration: 0.45), value: isExpanded)
    }

    func tripItem(
        title: String,
        value: String,
        color: Color = .white
    ) -> some View {
        VStack {
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)

            Text(value)
                .font(.title3)
                .bold()
                .foregroundStyle(color)
        }
    }
}

private struct TripHeader: View {
    var body: some View {
        VStack(spacing: 6) {
            Text("Ex-Boyfriends Celebration!")
                .font(.largeTitle)
                .fontWeight(.bold)
                .multilineTextAlignment(.center)

            Text("by @Bintang • 27/06/2026 • 11:30")
                .font(.title3)
                .foregroundStyle(.secondary)
        }
    }
}

private struct HeaderStats: View {
    var body: some View {
        HStack(spacing: 0) {
            stat(title: "People", value: "12")

            Divider()
                .frame(height: 70)
                .padding(.horizontal)

            stat(title: "ETA", value: "11:00", color: .yellow)

            Divider()
                .frame(height: 70)
                .padding(.horizontal)

            stat(title: "Distance", value: "15km", color: .yellow)
        }
    }

    @ViewBuilder
    private func stat(title: String, value: String, color: Color = .white) -> some View {
        VStack(spacing: 4) {
            Text(title)
                .font(.title3)
                .fontWeight(.semibold)
                .foregroundStyle(.secondary)

            Text(value)
                .font(.system(size: 28, weight: .bold))
                .foregroundStyle(color)
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
                    .padding(.horizontal, 18)
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
                    .font(.system(size: 36, weight: .bold))

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
            .foregroundStyle(.white)
        }
        .padding(.top, 8)
    }
}

#Preview {
    TripHeaderCard(isExpanded: .constant(true))
}
