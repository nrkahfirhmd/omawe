//
//  TripInvitationView.swift
//  Omawe
//
//  Created by Muhammad Bintang Al-Fath on 05/07/26.
//

import SwiftUI
import UIKit
import SwiftData
import CloudKit

struct TripInvitationView: View {
    @Environment(\.dismiss) private var dismiss
    
    @Query(sort: \UserProfile.createdAt, order: .forward) private var userProfiles: [UserProfile]
    
    private var currentUserDisplayName: String {
        let profile = ProfileHelper.currentUserProfile(from: userProfiles)
        return ProfileHelper.displayName(for: profile) ?? UserSession.shared.displayName ?? "Anonymous"
    }
    
    private var previewParticipants: [Participant] {
        let profile = ProfileHelper.currentUserProfile(from: userProfiles)
        let displayName = ProfileHelper.displayName(for: profile) ?? UserSession.shared.displayName ?? "Anonymous"
        return [
            Participant(
                id: nil,
                tripID: CKRecord.ID(recordName: "preview-trip"),
                userID: CKRecord.ID(recordName: "current-user"),
                displayName: displayName,
                role: .owner,
                joinedAt: .now,
                avatarImageData: profile?.avatarImageData
            )
        ]
    }
    @Binding var draft: TripDraft
    let creationErrorMessage: String?
    let shareErrorMessage: String?
    let canConfirmTripCreation: Bool
    let isSavingTrip: Bool
    let isCreatingShare: Bool
    let hasCreatedTrip: Bool
    let shareURL: String?
    let onCreateTrip: () async throws -> String
    let onDismissAndReset: () -> Void
    
    @Binding var isCalendarPresented: Bool
    @Binding var isEditingInvitationDetails: Bool
    @Binding var isLocationSheetPresented: Bool
    @State private var didCopyShareLink = false
    @State private var locationSearchQuery = ""
    @State private var isResolvingLocation = false
    @State private var isEditTitle = false
    @StateObject private var locationSearchService = LocationSearchService()
    @Namespace private var invitationNamespace
    @FocusState private var isTripNameFocused: Bool
    
    init(
        draft: Binding<TripDraft>,
        creationErrorMessage: String?,
        shareErrorMessage: String?,
        canConfirmTripCreation: Bool,
        isSavingTrip: Bool,
        isCreatingShare: Bool,
        hasCreatedTrip: Bool,
        shareURL: String?,
        isCalendarPresented: Binding<Bool>,
        isEditingInvitationDetails: Binding<Bool>,
        isLocationSheetPresented: Binding<Bool>,
        onCreateTrip: @escaping () async throws -> String,
        onDismissAndReset: @escaping () -> Void
    ) {
        self._draft = draft
        self.creationErrorMessage = creationErrorMessage
        self.shareErrorMessage = shareErrorMessage
        self.canConfirmTripCreation = canConfirmTripCreation
        self.isSavingTrip = isSavingTrip
        self.isCreatingShare = isCreatingShare
        self.hasCreatedTrip = hasCreatedTrip
        self.shareURL = shareURL
        self._isCalendarPresented = isCalendarPresented
        self._isEditingInvitationDetails = isEditingInvitationDetails
        self._isLocationSheetPresented = isLocationSheetPresented
        self.onCreateTrip = onCreateTrip
        self.onDismissAndReset = onDismissAndReset
    }
    
    private var displayTripName: String {
        draft.trimmedName.isEmpty ? "Trip Name" : draft.trimmedName
    }
    
    private var displayLocationName: String {
        draft.trimmedLocationName.isEmpty ? "No location selected" : draft.trimmedLocationName
    }
    
    private var buttonTitle: String {
        if didCopyShareLink {
            return "Code Copied"
        }
        
        if hasCreatedTrip {
            return "Share Link"
        }
        
        if isSavingTrip || isCreatingShare {
            return "Creating Trip..."
        }
        
        return "Create Trip"
    }
    
    var body: some View {
        ZStack {
            
            InvitationStageBackground()
            
            CustomDynamicIsland(
                color: .black,
                borderColor: LinearGradient(stops: [
                    .init(color: Color(hex: "03B9D6"), location: 0.0),
                    .init(color: Color(hex: "7AE8FF"), location: 0.51),
                    .init(color: Color(hex: "03B9D6"), location: 1.0),
                ], startPoint: UnitPoint.leading, endPoint: .trailing),
                fillColor: .black
            )
            .padding(.top, 8)
            .ignoresSafeArea()
            
            VStack(spacing: 0) {
                if !isEditingInvitationDetails {
                    header
                        .padding(.top, 20)
                        .transition(.opacity.combined(with: .move(edge: .top)))
                }
                
                invitationTicket
                    .frame(maxWidth: isEditingInvitationDetails ? .infinity : 430)
                    .frame(maxHeight: isEditingInvitationDetails ? .infinity : nil)
                    .padding(.top, isEditingInvitationDetails ? 0 : 20)
                    .padding(.horizontal, isEditingInvitationDetails ? 0 : 24)
                    .animation(.spring(response: 0.54, dampingFraction: 0.88), value: isEditingInvitationDetails)
                    
                    .ignoresSafeArea()
                
                Spacer(minLength: 20)
                bottomControls
                    .padding(.horizontal, 24)
                    .transition(.opacity.combined(with: .move(edge: .bottom)))
                
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .animation(.spring(response: 0.54, dampingFraction: 0.88), value: isEditingInvitationDetails)
        .sheet(isPresented: $isLocationSheetPresented) {
            TripLocationPickerSheet(
                draft: $draft,
                locationSearchQuery: $locationSearchQuery,
                isLocationSheetPresented: $isLocationSheetPresented,
                isResolvingLocation: $isResolvingLocation,
                locationSearchService: locationSearchService
            )
            .presentationDetents([.medium, .large])
            .presentationDragIndicator(.visible)
            .presentationCornerRadius(32)
            .presentationBackground(.ultraThinMaterial)
        }
        .onChange(of: shareURL) { _, newURL in
            guard let newURL else { return }
            copyShareLink(newURL)
        }
        .onChange(of: hasCreatedTrip) { _, isCreated in
            if isCreated {
                HapticManager.shared.success()
            }
        }
        .navigationBarBackButtonHidden(true)
        .preferredColorScheme(.dark)
    }
    
    private var header: some View {
        VStack(spacing: 7) {
            Image(systemName: hasCreatedTrip ? "figure.walk.suitcase.rolling" : "eyes")
                .font(.button())
                .foregroundStyle(.white.opacity(0.3))
            
            Text(hasCreatedTrip ? "Ready to\nTrip" : "Invitation\nPreview")
                .font(.button())
                .fontWidth(.expanded)
                .foregroundStyle(.white.opacity(0.52))
                .multilineTextAlignment(.center)
                .lineSpacing(4)
        }
    }
    
    private var invitationTicket: some View {
        InvitationTicketContainer(isEditing: isEditingInvitationDetails) {
            if isEditingInvitationDetails {
                editingTicketContent
                    .transition(.opacity.combined(with: .scale(scale: 0.96)))
            } else {
                let previewTrip = Trip(
                    id: nil,
                    title: draft.name,
                    destination: draft.locationName,
                    startDate: draft.arrivalDate,
                    endDate: draft.arrivalDate,
                    ownerID: CKRecord.ID(recordName: "owner"),
                    ownerDisplayName: currentUserDisplayName,
                    invitationCode: draft.invitationCode,
                    locationAddress: draft.locationAddress,
                    apartmentUnitFloor: draft.apartmentUnitFloor,
                    locationNickname: draft.locationNickname,
                    createdAt: .now,
                    updatedAt: .now
                )
                PreviewTicketContent(trip: previewTrip, participants: previewParticipants)
                    .transition(.opacity.combined(with: .scale(scale: 0.98)))
            }
        }
    }
    

    
    private var editingTicketContent: some View {
        GeometryReader { geo in
            let totalHeight = geo.size.height
            let bottomRatio: CGFloat = 0.30
            let topHeight = totalHeight * (1.0 - bottomRatio)
            let bottomHeight = totalHeight * bottomRatio
            
            VStack(spacing: 0) {
                // Top Section (Title edit, Date picker)
                VStack(spacing: 0) {
                    Spacer()
                    
                    ZStack {
                        Text(displayTripName)
                            .font(.title1().weight(.semibold))
                            .fontWidth(.expanded)
                            .foregroundStyle(Color(red: 0.0, green: 0.19, blue: 0.22))
                            .multilineTextAlignment(.center)
                            .lineLimit(2)
                            .opacity(isEditTitle ? 0 : 1)
                        
                        TextField("", text: $draft.name)
                            .font(.title1().weight(.semibold))
                            .fontWidth(.expanded)
                            .foregroundStyle(Color(red: 0.0, green: 0.19, blue: 0.22))
                            .multilineTextAlignment(.center)
                            .opacity(isEditTitle ? 1 : 0)
                            .focused($isTripNameFocused)
                            .disabled(!isEditTitle)
                            .onAppear {
                                if isEditTitle {
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                                        isTripNameFocused = true
                                    }
                                }
                            }
                            .onSubmit {
                                isTripNameFocused = false
                                isEditTitle = false
                            }
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 10)
                    .background {
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .fill(Color.black.opacity(0.04))
                    }
                    .overlay {
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .stroke(
                                isEditTitle ? Theme.primaryBox : Color.black.opacity(0.08),
                                lineWidth: isEditTitle ? 2 : 1
                            )
                    }
                    .contentShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                    .onTapGesture {
                        guard !isEditTitle else { return }
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.88)) {
                            isEditTitle = true
                        }
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                            isTripNameFocused = true
                        }
                    }
                    .matchedGeometryEffect(id: "tripTitle", in: invitationNamespace)
                    .animation(.spring(response: 0.4, dampingFraction: 0.88), value: isEditTitle)
                    
                    Spacer(minLength: 24)
                    
                    TripDateTimeDraftPicker(
                        arrivalDate: $draft.arrivalDate,
                        isCalendarPresented: $isCalendarPresented,
                        color: .black
                    )
                    
                    Spacer()
                }
                .frame(height: topHeight)
                
                // Bottom Section (Location edit)
                VStack(spacing: 0) {
                    VStack(spacing: 20) {
                        Text("Location")
                            .font(.headline())
                            .foregroundStyle(.white)
                        TripDestinationDraftSection(
                            draft: $draft,
                            isLocationSheetPresented: $isLocationSheetPresented
                        )
                    }
                    .padding(.top, 16)
                    
                    Spacer()
                }
                .frame(height: bottomHeight)
            }
        }
        .padding(24)
    }
    

    
    private var bottomControls: some View {
        VStack(spacing: 12) {
            if !isEditingInvitationDetails {
                HStack(spacing: 12) {
                    if !hasCreatedTrip {
                        Button {
                            dismiss()
                            onDismissAndReset()
                        } label: {
                            Image(systemName: "chevron.left")
                                .font(.headline())
                                .padding(8)
                        }
                        .buttonStyle(.glass)
                        .buttonBorderShape(.circle)
                        .accessibilityLabel("Go back")
                    }
                    
                    Button {
                        if hasCreatedTrip {
                            if let shareURL {
                                copyShareLink(shareURL)
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                                    dismiss()
                                    onDismissAndReset()
                                }
                            } else {
                                dismiss()
                                onDismissAndReset()
                            }
                        }
                    } label: {
                        HStack(spacing: 14) {
                            if isSavingTrip || isCreatingShare {
                                ProgressView()
                                    .tint(.white)
                                    .frame(height: 15)
                            } else {
                                Image(systemName: primaryButtonIconName)
                                    .font(.button())
                            }
                            
                            Text(buttonTitle)
                                .font(.button())
                                .fontWidth(.expanded)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(16)
                        .foregroundStyle(canConfirmTripCreation || isSavingTrip || hasCreatedTrip || isCreatingShare ? .white : .white.opacity(0.52))
                        .overlay {
                            Capsule()
                                .stroke(hasCreatedTrip ? Theme.secondary : Theme.primary, lineWidth: 1.5)
                        }
                    }
                    .glassEffect(.clear)
                    .disabled(hasCreatedTrip ? false : (!canConfirmTripCreation || isSavingTrip))
                    .accessibilityLabel(buttonTitle)
                    
                    if !hasCreatedTrip {
                        Button {
                            withAnimation(.spring(response: 0.54, dampingFraction: 0.88)) {
                                isEditingInvitationDetails = true
                            }
                        } label: {
                            Image(systemName: "pencil.line")
                                .font(.headline())
                                .padding(8)
                        }
                        .buttonStyle(.glass)
                        .buttonBorderShape(.circle)
                        .accessibilityLabel("Edit invitation details")
                    }
                }
            } else {
                HStack {
                    Button {
                        dismissEditMode()
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
                        .foregroundStyle(.white )
                        .overlay {
                            Capsule()
                                .stroke(Theme.primary, lineWidth: 1.5)
                        }
                    }
                    .glassEffect(.clear)
                    
                    Button {
                        dismissEditMode()
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
            }
        }
    }
    
    private var primaryButtonIconName: String {
        if didCopyShareLink {
            return "checkmark.circle.fill"
        }
        if hasCreatedTrip {
            return "square.and.arrow.up.fill"
        }
        return "plus.circle.fill"
    }
    
    private func copyShareLink(_ url: String) {
        UIPasteboard.general.string = url
        
        withAnimation(.spring(response: 0.34, dampingFraction: 0.88)) {
            didCopyShareLink = true
        }
        
        Task {
            try? await Task.sleep(for: .seconds(1.6))
            
            await MainActor.run {
                withAnimation(.spring(response: 0.34, dampingFraction: 0.88)) {
                    didCopyShareLink = false
                }
            }
        }
    }
    
    private func dismissEditMode() {
        withAnimation(.spring(response: 0.54, dampingFraction: 0.88)) {
            isCalendarPresented = false
            isEditingInvitationDetails = false
        }
    }
    
    private func invitationAvatar(initials: String, tint: Color) -> some View {
        Text(initials)
            .font(.bodyText())
            .foregroundStyle(.black.opacity(0.74))
            .frame(width: 25, height: 25)
            .background(tint, in: Circle())
            .overlay {
                Circle()
                    .stroke(.black.opacity(0.72), lineWidth: 1)
            }
    }
}

#Preview {
    @Previewable @State var draft = TripDraft(
        name: "Bali",
        arrivalDate: Date(),
        locationName: "Canggu Beach Club",
        locationAddress: "Jl. Pantai Batu Bolong, Canggu",
//                apartmentUnitFloor: "Villa 3, Floor 2",
//                locationNickname: "Canggu Stay"
    )
    @Previewable @State var isCalendarPresented = false
    @Previewable @State var isEditingInvitationDetails = false
    @Previewable @State var isLocationSheetPresented = false
    
    TripInvitationView(
        draft: $draft,
        creationErrorMessage: nil,
        shareErrorMessage: nil,
        canConfirmTripCreation: true,
        isSavingTrip: false,
        isCreatingShare: false,
        hasCreatedTrip: false,
        shareURL: "https://www.icloud.com/share/test",
        isCalendarPresented: $isCalendarPresented,
        isEditingInvitationDetails: $isEditingInvitationDetails,
        isLocationSheetPresented: $isLocationSheetPresented,
        onCreateTrip: {
            try? await Task.sleep(for: .seconds(1))
            return "123456"
        },
        onDismissAndReset: {}
    )
}



