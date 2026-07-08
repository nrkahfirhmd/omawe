//
//  ProfileView.swift
//  Omawe
//
//  Created by Syed Israruddin on 06/07/26.
//


import SwiftUI
import PhotosUI
import SwiftData

struct ProfileView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var userProfiles: [UserProfile]
    @State private var profile: UserProfile?
    
    @Environment(\.dismiss) private var dismiss
    
    @AppStorage("selectedAvatarFrame") private var selectedAvatarFrame: AvatarFrameStyle = .dark
    
    private var trips: [Trip] {
        TripStore.shared.trips
    }

    private var totalTripsCount: Int {
        trips.count
    }

    private var upcomingTripsCount: Int {
        let today = Calendar.current.startOfDay(for: .now)
        return trips.filter { $0.startDate >= today }.count
    }

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

                    Text(profile?.displayName.isEmpty == false ? "Hi \(profile!.displayName)" : "Hi \(UserSession.shared.displayName ?? "New User")")
                        .font(.largeTitle)
                        .fontWidth(.expanded)
                        .fontWeight(.semibold)
                        .foregroundStyle(.primary)

                    statsRow
                    
                    settingsMenu
                    
                    Spacer()
                }
                .padding(.horizontal, 24)
            }
            .navigationTitle("Profile")
            .navigationBarTitleDisplayMode(.inline)
            .presentationBackground(.clear)
            .onAppear {
                setupProfile()
            }
        }
    }

    private func setupProfile() {
        if let existing = userProfiles.first(where: { $0.userID == UserSession.shared.userIdentifier }) ?? userProfiles.first {
            profile = existing
        } else {
            let newProfile = UserProfile(
                userID: UserSession.shared.userIdentifier ?? "",
                displayName: UserSession.shared.displayName ?? ""
            )
            modelContext.insert(newProfile)
            profile = newProfile
        }
    }

    private var profileAvatar: some View {
        ZStack {

            Image(selectedAvatarFrame.image)
            
            if let imageData = profile?.avatarImageData, let uiImage = UIImage(data: imageData) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 60, height: 60)
                    .clipShape(Circle())
            } else {
                let displayName = profile?.displayName.isEmpty == false ? profile!.displayName : UserSession.shared.displayName
                if let initials = displayName?.first.map(String.init) {
                    Text(initials.uppercased())
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [Color(hex: "03B9D6"), Color(hex: "7AE8FF")],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .frame(width: 60, height: 60)
                        .glassEffect(.clear, in: .circle)
                } else {
                    Image(.avatar)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 60, height: 60)
                }
            }
            
            NavigationLink {
                if let profile {
                    EditProfileView(profile: profile, selectedAvatarFrame: $selectedAvatarFrame)
                }
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
            NavigationLink {
                TripsListView(initialSegment: .totalTrips)
            } label: {
                ProfileStatCard(
                    background: .totalTripCardBG,
                    icon: "map",
                    title: "Total trips",
                    value: "\(totalTripsCount)"
                )
            }
            .buttonStyle(.plain)

            NavigationLink {
                TripsListView(initialSegment: .nextTrips)
            } label: {
                ProfileStatCard(
                    background: .nextTripCardBG,
                    icon: "calendar.badge.clock",
                    title: "Next trips",
                    value: "\(upcomingTripsCount)"
                )
            }
            .buttonStyle(.plain)
        }
    }

    private var settingsMenu: some View {
        VStack(spacing: 0) {
            NavigationLink {
                TripsListView()
            } label: {
                ProfileSettingsRow(
                    title: "Your trips",
                    trailingText: "",
                    showChevron: true
                )
            }
            .buttonStyle(.plain)

            Divider()

            ProfileTextSizeRow()

            Divider()

            HapticToggleRow(title: "Haptic feedback")

            Divider()

            NavigationLink {
                        PrivacyDataView()
                    } label: {
                        ProfileSettingsRow(
                            title: "Privacy & data",
                            trailingText: "",
                            showChevron: true
                        )
                    }
                    .buttonStyle(.plain)
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 10)
        .frame(width: 362)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
    }
}

enum AvatarFrameStyle: String, CaseIterable, Identifiable {
    case dark
    case light

    var id: String { rawValue }

    var image: ImageResource {
        switch self {
        case .dark:
            return .darkAvatarFrame
        case .light:
            return .lightAvatarFrame
        }
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

struct EditProfileView: View {
    var profile: UserProfile
    @Binding var selectedAvatarFrame: AvatarFrameStyle
    @Environment(\.dismiss) private var dismiss
    
    @State private var nickname = ""
    @State private var dateOfBirth = Date.now
    @State private var gender = ""
    @State private var pendingAvatarData: Data?
    
    @State private var selectedPhotoItem: PhotosPickerItem?
    @State private var selectedAvatarImage: Image?

    var body: some View {
        ZStack {
            Image(.homeBackground)
                .resizable()
                .scaledToFill()
                .ignoresSafeArea()
            

            VStack(spacing: 28) {
                ZStack {
            

                    Image(selectedAvatarFrame.image)

                    if let selectedAvatarImage {
                        selectedAvatarImage
                            .resizable()
                            .scaledToFill()
                            .frame(width: 60, height: 60)
                            .clipShape(Circle())
                    } else if let imageData = pendingAvatarData ?? profile.avatarImageData, let uiImage = UIImage(data: imageData) {
                        Image(uiImage: uiImage)
                            .resizable()
                            .scaledToFill()
                            .frame(width: 60, height: 60)
                            .clipShape(Circle())
                    } else {
                        let displayName = nickname.isEmpty ? UserSession.shared.displayName : nickname
                        if let initials = displayName?.first.map(String.init) {
                            Text(initials.uppercased())
                                .font(.system(size: 32, weight: .bold, design: .rounded))
                                .foregroundStyle(
                                    LinearGradient(
                                        colors: [Color(hex: "03B9D6"), Color(hex: "7AE8FF")],
                                        startPoint: .top,
                                        endPoint: .bottom
                                    )
                                )
                                .frame(width: 60, height: 60)
                                .glassEffect(.clear, in: .circle)
                        } else {
                            Image(.avatar)
                                .resizable()
                                .scaledToFit()
                                .frame(width: 60, height: 60)
                        }
                    }
                }
                .padding(.top, 80)

                Text(profile.displayName.isEmpty ? "Hi User" : "Hi \(profile.displayName)")
                    .font(.largeTitle())
                    .fontWidth(.expanded)
                    .fontWeight(.semibold)

                PhotosPicker(
                    selection: $selectedPhotoItem,
                    matching: .images
                ) {
                    Label("Change image", systemImage: "photo")
                        .font(.headline())
                        .foregroundStyle(.primary)
                        .padding(.horizontal, 22)
                        .frame(height: 46)
                        .background(.black.opacity(0.08))
                        .clipShape(Capsule())
                }
                .onChange(of: selectedPhotoItem) { _, newItem in
                    Task {
                        guard let data = try? await newItem?.loadTransferable(type: Data.self),
                              let uiImage = UIImage(data: data) else {
                            return
                        }

                        selectedAvatarImage = Image(uiImage: uiImage)
                        pendingAvatarData = data
                    }
                }

                Picker("", selection: $selectedAvatarFrame) {
                    Text("Dark frame").tag(AvatarFrameStyle.dark)
                    Text("Light frame").tag(AvatarFrameStyle.light)
                }
                .pickerStyle(.segmented)
                .padding(.horizontal, 30)

                profileInfoCard

                Spacer()
            }
            .padding(.horizontal, 24)
        }
        .navigationTitle("Profile")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button {
                    profile.displayName = nickname
                    profile.dateOfBirth = dateOfBirth
                    profile.gender = gender
                    if let pendingData = pendingAvatarData {
                        profile.avatarImageData = pendingData
                    }
                    dismiss()
                } label: {
                    Image(systemName: "checkmark")
                }
                .buttonStyle(.glassProminent)
            }
        }
        .onAppear {
            nickname = profile.displayName
            dateOfBirth = profile.dateOfBirth
            gender = profile.gender
        }
    }

    private var profileInfoCard: some View {
        VStack(spacing: 0) {
            HStack {
                Text("Nickname")
                    .font(.bodyText())

                Spacer()

                TextField("Nickname", text: $nickname)
                    .font(.bodyText())
                    .multilineTextAlignment(.trailing)
                    .foregroundStyle(.secondary)
            }
            .frame(height: 56)

            Divider()

            DatePicker(
                "Date of Birth",
                selection: $dateOfBirth,
                displayedComponents: .date
            )
            .font(.bodyText())
            .frame(height: 56)
            .tint(.cyan)

            Divider()

            HStack {
                Text("Gender")
                    .font(.bodyText())

                Spacer()

                Picker("Gender", selection: $gender) {
                    Text("Female").tag("Female")
                    Text("Male").tag("Male")
                    Text("Other").tag("Other")
                    Text("Prefer not to say").tag("Prefer not to say")
                }
                .pickerStyle(.menu)
                .tint(.cyan)
            }
            .frame(height: 56)
        }
        .padding(.horizontal, 18)
        .frame(width: 362)
        .background(.white)
        .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
    }
}

struct EditProfileRow: View {
    let title: String
    let value: String
    
    

    var body: some View {
        HStack {
            Text(title)
                .font(.bodyText())

            Spacer()

            Text(value)
                .font(.bodyText())
                .foregroundStyle(.secondary)
        }
        .frame(height: 56)
    }
}


    


struct PrivacyDataView: View {
    var body: some View {
        
        ZStack {
            Image(.homeBackground)
                .resizable()
                .scaledToFill()
                .ignoresSafeArea()
            VStack {
                
                //Spacer()
                
                Text("At Omawe, privacy comes first. Your location is only shared with the friends you choose and only for the duration of an active trip. Once the trip ends, location sharing automatically stops. \n\n We collect only the information necessary to provide core features such as real-time trip tracking, arrival updates, and route coordination. We do not sell personal data or use precise location for advertising purposes.\n \n Users have full control over their privacy: \n • Start or stop location sharing at any time.\n • Share location only with invited trip members.\n • Remove yourself from a trip whenever you want.\n • Manage notification and location permissions in the app.\n\n All communication is ensured a safe and reliable group travel experience.")

                    .padding()
                    .padding(.top, 70)
                    
                Spacer()
                
            }
            
        }
        .navigationTitle("Privacy & data")
        .navigationBarTitleDisplayMode(.inline)
        
        
    }
    
}

#Preview {
    ProfileView()
}
