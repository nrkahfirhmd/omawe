//
//  ProfileView.swift
//  Omawe
//
//  Created by Syed Israruddin on 06/07/26.
//


import SwiftUI

struct ProfileView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        
        NavigationStack {
            ZStack {
                Image(.homeBackground)
                    .resizable()
                    .scaledToFill()
                    .ignoresSafeArea()

                VStack(spacing: 24) {
                    
                    Spacer()
                           .frame(height: 70)
                    
                    profileAvatar

                    Text("Hi Baeni")
                        .font(.largeTitle)
                        .fontWidth(.expanded)
                        .fontWeight(.semibold)
                        .fontWidth(.expanded)
                        .foregroundStyle(.primary)

                    statsRow
                    
                    settingsMenu
                    
                    Spacer()
                }
                .padding(.horizontal, 24)
            }
            .navigationTitle("Profile")
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    private var profileAvatar: some View {
        ZStack {
            Circle()
                .frame(width: 120)
                .foregroundColor(.white)
                .shadow(color: .init(hex: "#00C3FF").opacity(0.5), radius: 21, x: 0, y: 0)

            Image(.frame74)
            Image(.avatar)
            
            Button {
                // edit avatar action later
            } label: {
                Image(systemName: "paintbrush")
                    .font(.title3)
                    .foregroundStyle(.gray)
                    .frame(width: 48, height: 48)
                    .background(.ultraThinMaterial)
                    .clipShape(Circle())
            }
            .offset(x: 50, y: -40)
        }
    }

    private var statsRow: some View {
        HStack(spacing: 16) {
            ProfileStatCard(
                background: .totalTripCardBG,
                icon: "map",
                title: "Total trip",
                value: "8"
            )

            ProfileStatCard(
                background: .nextTripCardBG,
                icon: "calendar.badge.clock",
                title: "Next trip",
                value: "2"
            )
        }
    }

    private var settingsMenu: some View {
        VStack(spacing: 0) {
            ProfileSettingsRow(
                title: "Trips list",
                trailingText: "Detail",
                showChevron: true
            )

            Divider()

            ProfileTextSizeRow()

            Divider()

            HapticToggleRow(title: "Haptic feedback")

            Divider()

            ProfileSettingsRow(
                title: "Privacy & data",
                trailingText: "Detail",
                showChevron: true
            )
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 10)
        .frame(width: 362)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
    }
}

struct ProfileStatCard: View {
    let background: ImageResource
    let icon: String
    let title: String
    let value: String

    var body: some View {
        ZStack {
            Image(background)
                .resizable()
                .scaledToFill()

            HStack {
                VStack(alignment: .leading, spacing: 6) {
                    Image(systemName: icon)
                        .font(.title2)
                        .foregroundStyle(.white)

                    Text(title)
                        .font(.headline())
                        .foregroundStyle(.white)
                }

                Spacer()

                Text(value)
                    .font(.largeTitle)
                    .fontWidth(.expanded)
                    .fontWeight(.semibold)
                    .foregroundStyle(.white)
            }
            .padding(.horizontal, 18)
        }
        .frame(height: 78)
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .clipped()
    }
}

struct ProfileSettingsRow: View {
    let title: String
    let trailingText: String
    let showChevron: Bool

    var body: some View {
        HStack {
            Text(title)
                .font(.bodyText())

            Spacer()

            Text(trailingText)
                .font(.bodyText())
                .foregroundStyle(.secondary)

            if showChevron {
                Image(systemName: "chevron.right")
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(Color.omawePrimary)
            }
        }
        .frame(height: 52)
    }
}

struct ProfileTextSizeRow: View {
    var body: some View {
        HStack {
            Text("Text size")
                .font(.bodyText())

            Spacer()

            HStack(spacing: 18) {
                Button { } label: {
                    Image(systemName: "minus")
                }

                Divider()
                    .frame(height: 24)

                Button { } label: {
                    Image(systemName: "plus")
                }
            }
            .font(.headline())
            .foregroundStyle(.primary)
            .padding(.horizontal, 16)
            .frame(height: 32)
            .background(Color.gray.opacity(0.12))
            .clipShape(Capsule())
        }
        .frame(height: 52)
    }
}

struct HapticToggleRow: View {
    @State private var isOn = true

    let title: String

    var body: some View {
        HStack {
            Text(title)
                .font(.bodyText())

            Spacer()

            Toggle("", isOn: $isOn)
                .labelsHidden()
                .tint(.green)
        }
        .frame(height: 52)
    }
}

struct TripsListView: View {
    var body: some View {
        Text("Trips list")
            .navigationTitle("Trips list")
            .navigationBarTitleDisplayMode(.inline)
    }
}

struct PrivacyDataView: View {
    var body: some View {
        Text("Privacy & data")
            .navigationTitle("Privacy & data")
            .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    ProfileView()
}
