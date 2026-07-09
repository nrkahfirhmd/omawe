//
//  TripDetailView.swift
//  Omawe
//
//  Created by Gleenryan on 02/07/26.
//

import SwiftUI

struct TripDetailMember: Identifiable, Equatable {
    var id: String { name }
    let name: String
    let avatarData: Data?
}

// MARK: - Trip Detail View
struct TripDetailView: View {
    var trip: TripData
    var members: [TripDetailMember]
    var isOwner: Bool = false
    var tripModel: Trip? = nil
    var onLeave: (() -> Void)? = nil
    var onRemoveMember: ((TripDetailMember) -> Void)? = nil
    var onDeleteTrip: (() -> Void)? = nil
    
    @State private var currentMemberPage = 0
    @State private var isEditing = false
    @State private var editableMembers: [TripDetailMember] = []
    @State private var isShowingInvitation = false
    @Environment(\.dismiss) private var dismiss
    
    private let membersPerPage = 5
    
    var resolvedIsOwner: Bool {
        if isOwner { return true }
        let ownerName = UserSession.shared.displayName ?? ""
        return !ownerName.isEmpty && trip.subtitle.contains("@\(ownerName)")
    }
    
    private var displayMembers: [TripDetailMember] {
        isEditing ? editableMembers : members
    }
    
    private var memberPages: [[TripDetailMember]] {
        let source = displayMembers
        guard !source.isEmpty else { return [[]] }
        return stride(from: 0, to: source.count, by: membersPerPage).map {
            Array(source[$0..<min($0 + membersPerPage, source.count)])
        }
    }
    
    private var detailSubtitle: String {
        if isEditing {
            return trip.subtitle
        }
        if resolvedIsOwner {
            return "You are the group creator"
        } else {
            if let range = trip.subtitle.range(of: "by @"),
               let endRange = trip.subtitle.range(of: " •") {
                let owner = trip.subtitle[range.upperBound..<endRange.lowerBound]
                return "Created by @\(owner)"
            }
            return "You are a participant"
        }
    }
    
    private var tripDateTimeString: String {
        let components = trip.subtitle.components(separatedBy: " • ")
        if components.count >= 2 {
            return components.dropFirst().joined(separator: " • ")
        }
        return trip.subtitle
    }
    
    var body: some View {
        ZStack {
            InvitationStageBackground(hasJoined: true)
            
            VStack(spacing: 0) {
                // Top Custom Dynamic Island
                CustomDynamicIsland(
                    color: Theme.primaryBox,
                    fillColor: Theme.primaryBox,
                    borderWidth: 2,
                    width: 126,
                    height: 37,
                    isContentVisible: false
                )
                .padding(.top, 8)
                
                // Location Card
                HStack(spacing: 12) {
                    let locationParts = trip.location.split(separator: ",", maxSplits: 1).map(String.init)
                    let placeName = locationParts.first ?? trip.location
                    let address = locationParts.count > 1 ? locationParts[1].trimmingCharacters(in: .whitespaces) : ""
                    
                    ZStack {
                        Circle()
                            .fill(Color(hex: "03B9D6"))
                            .frame(width: 40, height: 40)
                        
                        Image(systemName: "paperplane.fill")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundStyle(Color(red: 0.05, green: 0.25, blue: 0.24))
                    }
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text(placeName)
                            .font(.system(size: 15, weight: .bold))
                            .foregroundStyle(.white)
                        
                        if !address.isEmpty {
                            Text(address)
                                .font(.system(size: 12))
                                .foregroundStyle(.white.opacity(0.6))
                                .lineLimit(1)
                        }
                    }
                    
                    Spacer()
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(Color.white.opacity(0.08))
                .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
                .padding(.horizontal, 16)
                .padding(.bottom, 24)
                
                // Title and Header info
                VStack(spacing: 4) {
                    HStack(spacing: 12) {
                        Text(trip.title)
                            .font(.title2)
                            .fontWidth(.expanded)
                            .fontWeight(.bold)
                            .foregroundStyle(Color(hex: "49FFEC"))
                            .multilineTextAlignment(.center)
                            .lineLimit(2)
                            .fixedSize(horizontal: false, vertical: true)
                        
                        if isEditing {
                            Button {
                                onDeleteTrip?()
                                dismiss()
                            } label: {
                                Image(systemName: "trash.fill")
                                    .foregroundStyle(.white)
                                    .padding(10)
                                    .background(Color.white.opacity(0.12), in: Circle())
                            }
                        }
                    }
                    .padding(.horizontal, 24)
                    
                    Text(detailSubtitle)
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.6))
                        .padding(.bottom, 16)
                    
                    // People count
                    HStack(alignment: .firstTextBaseline, spacing: 6) {
                        Text("\(displayMembers.count)")
                            .font(.system(size: 54, weight: .bold, design: .rounded))
                            .fontWidth(.expanded)
                            .foregroundStyle(Color(hex: "49FFEC"))
                        Text("People")
                            .font(.subheadline.bold())
                            .foregroundStyle(.white.opacity(0.6))
                    }
                    .padding(.bottom, 8)
                    
                    // Date & Time
                    HStack(spacing: 6) {
                        Image(systemName: "calendar")
                            .foregroundStyle(.white.opacity(0.6))
                        Text(tripDateTimeString)
                            .foregroundStyle(.white.opacity(0.6))
                    }
                    .font(.system(size: 13, weight: .medium))
                    .padding(.bottom, 20)
                }
                
                // Paginated members list
                PaginatedMemberList(
                    pages: memberPages,
                    currentPage: $currentMemberPage,
                    isEditing: isEditing,
                    ownerName: UserSession.shared.displayName ?? "",
                    onRemove: { name in
                        withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                            editableMembers.removeAll { $0 == name }
                            let maxPage = max(0, memberPages.count - 1)
                            if currentMemberPage > maxPage {
                                currentMemberPage = maxPage
                            }
                        }
                    }
                )
                
                // Page indicator
                MemberPageIndicator(
                    totalPages: memberPages.count,
                    currentPage: currentMemberPage
                )
                .padding(.top, 14)
                .padding(.bottom, 24)
                
                Spacer()
                
                // Bottom controls
                if isEditing {
                    EditBottomBar(
                        onCancel: {
                            withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                                editableMembers = members
                                isEditing = false
                            }
                        },
                        onSave: {
                            let removedMembers = members.filter { !editableMembers.contains($0) }
                            for member in removedMembers {
                                onRemoveMember?(member)
                            }
                            withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                                isEditing = false
                            }
                        }
                    )
                    .padding(.bottom, 8)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                } else {
                    TripDetailBottomBar(
                        isOwner: resolvedIsOwner,
                        onBack: {
                            dismiss()
                        },
                        onLeave: {
                            onLeave?()
                            dismiss()
                        },
                        onEdit: {
                            editableMembers = members
                            withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                                isEditing = true
                            }
                        }, onSeeInvitation: {
                            isShowingInvitation = true
                        }
                    )
                    .padding(.bottom, 8)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
            .ignoresSafeArea(edges: .top)
            .navigationBarBackButtonHidden(true)
            .navigationDestination(isPresented: $isShowingInvitation) {
                if let tripModel {
                    JoinInvitationView(
                        trip: tripModel,
                        isViewOnly: true,
                        isOwner: resolvedIsOwner,
                        onLeave: {
                            onLeave?()
                        },
                        onEdit: {
                            editableMembers = members
                            withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                                isEditing = true
                            }
                        },
                        onDismiss: {
                            isShowingInvitation = false
                        }
                    )
                }
            }
        }
    }
}

// MARK: - Paginated Member List
struct PaginatedMemberList: View {
    var pages: [[TripDetailMember]]
    @Binding var currentPage: Int
    var isEditing: Bool
    var ownerName: String = ""
    var onRemove: ((TripDetailMember) -> Void)?
    
    var body: some View {
        TabView(selection: $currentPage) {
            ForEach(pages.indices, id: \.self) { pageIndex in
                VStack(spacing: 8) {
                    ForEach(Array(pages[pageIndex].enumerated()), id: \.offset) { _, member in
                        MemberRow(
                            name: member.name,
                            avatarData: member.avatarData,
                            isEditing: isEditing && (member.name != ownerName),
                            onRemove: { onRemove?(member) }
                        )
                    }
                    Spacer()
                }
                .padding(.horizontal, 20)
                .tag(pageIndex)
            }
        }
        .tabViewStyle(.page(indexDisplayMode: .never))
        .frame(height: 360, alignment: .top)
    }
}

// MARK: - Member Page Indicator
struct MemberPageIndicator: View {
    var totalPages: Int
    var currentPage: Int
    
    var body: some View {
        HStack(spacing: 6) {
            ForEach(0..<totalPages, id: \.self) { index in
                Capsule()
                    .fill(index == currentPage ? .white : .white.opacity(0.3))
                    .frame(
                        width: index == currentPage ? 20 : 7,
                        height: 7
                    )
                    .animation(.spring(response: 0.3, dampingFraction: 0.7), value: currentPage)
            }
        }
    }
}

// MARK: - Member Row
struct MemberRow: View {
    var name: String
    var avatarData: Data? = nil
    var isEditing: Bool = false
    var onRemove: (() -> Void)?
    
    var body: some View {
        HStack(spacing: 12) {
            if let avatarData, let uiImage = UIImage(data: avatarData) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 38, height: 38)
                    .clipShape(Circle())
            } else {
                Image(.avatar)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 38, height: 38)
            }
            
            Text(name)
                .font(.system(size: 15, weight: .medium))
                .foregroundStyle(.white.opacity(0.9))
            
            Spacer()
            
            if isEditing {
                Button {
                    onRemove?()
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title3)
                        .foregroundStyle(.white.opacity(0.5))
                }
                .transition(.scale.combined(with: .opacity))
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(Color.white.opacity(0.04))
        .clipShape(Capsule())
        .overlay {
            Capsule()
                .stroke(.white.opacity(0.08), lineWidth: 1)
        }
    }
}

// MARK: - Bottom Bar (View Mode)
struct TripDetailBottomBar: View {
    var isOwner: Bool = false
    var onBack: () -> Void
    var onLeave: (() -> Void)? = nil
    var onEdit: () -> Void
    var onSeeInvitation: () -> Void = {}
    
    var body: some View {
        HStack(spacing: 12) {
            Button {
                onBack()
            } label: {
                Image(systemName: "chevron.left")
                    .font(.headline())
                    .padding(8)
            }
            .buttonStyle(.glass)
            .buttonBorderShape(.circle)
            .accessibilityLabel("Go back")
            
            Button {
                onSeeInvitation()
            } label: {
                HStack(spacing: 14) {
                    Image(systemName: "eyes")
                        .font(.button())
                    
                    Text("See Invitation")
                        .font(.button())
                        .fontWidth(.expanded)
                }
                .frame(maxWidth: .infinity)
                .padding(16)
                .foregroundStyle(.white)
                .overlay {
                    Capsule()
                        .stroke(Theme.primary, lineWidth: 1.5)
                }
            }
            .glassEffect(.clear)
            
            if isOwner {
                Button {
                    onEdit()
                } label: {
                    Image(systemName: "pencil")
                        .font(.headline())
                        .padding(8)
                }
                .buttonStyle(.glass)
                .buttonBorderShape(.circle)
                .accessibilityLabel("Edit trip")
            } else {
                Button {
                    onLeave?()
                } label: {
                    Image(systemName: "rectangle.portrait.and.arrow.right")
                        .font(.headline())
                        .padding(8)
                }
                .buttonStyle(.glass)
                .buttonBorderShape(.circle)
                .accessibilityLabel("Leave trip")
            }
        }
        .padding(.horizontal, 16)
    }
}

// MARK: - Bottom Bar (Edit Mode)
struct EditBottomBar: View {
    var onCancel: () -> Void
    var onSave: () -> Void
    
    var body: some View {
        HStack(spacing: 12) {
            Button {
                onCancel()
            } label: {
                HStack(spacing: 14) {
                    Image(systemName: "xmark")
                        .font(.button())
                    
                    Text("Cancel")
                        .font(.button())
                        .fontWidth(.expanded)
                }
                .frame(maxWidth: .infinity)
                .padding(16)
                .foregroundStyle(.white)
                .overlay {
                    Capsule()
                        .stroke(Theme.primary, lineWidth: 1.5)
                }
            }
            .glassEffect(.clear)
            
            Button {
                onSave()
            } label: {
                HStack(spacing: 14) {
                    Image(systemName: "checkmark")
                        .font(.button())
                    
                    Text("Done")
                        .font(.button())
                        .fontWidth(.expanded)
                }
                .frame(maxWidth: .infinity)
                .padding(16)
                .foregroundStyle(.white)
                .background(Capsule().fill(Color.blue.opacity(0.32)))
                .overlay {
                    Capsule()
                        .stroke(Theme.primary, lineWidth: 1.5)
                }
            }
            .glassEffect(.clear)
        }
        .padding(.horizontal, 16)
    }
}

#Preview {
    let trip = TripData(
        theme: Theme.themeSecondary,
        icon: "balloon.2",
        title: "Ex-Boyfriends Celebration! hashfhasfgasgfksa",
        subtitle: "by @Bintang • 27/06/2026 • 11:30",
        people: 12,
        location: "Fore Kopi, Jl. Dewi Sri No.69, Legian, Kec...",
        footerTitle: "Trip detail"
    )
    
    let members = [
        TripDetailMember(name: "Gleen Ryan", avatarData: nil)
    ]
    
    TripDetailView(trip: trip, members: members)
}
