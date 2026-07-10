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
    @Binding var creationErrorMessage: String?
    @Binding var shareErrorMessage: String?
    let canConfirmTripCreation: Bool
    @Binding var isSavingTrip: Bool
    @Binding var isCreatingShare: Bool
    @Binding var hasCreatedTrip: Bool
    @Binding var shareURL: String?
    let onCreateTrip: () async throws -> String
    let onDismissAndReset: () -> Void
    let isViewOnly: Bool
    var isOwner: Bool = false
    var onUpdateTrip: (() -> Void)? = nil
    
    @Binding var isCalendarPresented: Bool
    @Binding var isEditingInvitationDetails: Bool
    @Binding var isLocationSheetPresented: Bool
    @State private var didCopyShareLink = false
    @State private var isFetchingShareLink = false
    @State private var locationSearchQuery = ""
    @State private var isResolvingLocation = false
    @State private var isEditTitle = false
    @StateObject private var locationSearchService = LocationSearchService()
    @Namespace private var invitationNamespace
    @FocusState private var isTripNameFocused: Bool
    
    init(
        draft: Binding<TripDraft>,
        creationErrorMessage: Binding<String?>,
        shareErrorMessage: Binding<String?>,
        canConfirmTripCreation: Bool,
        isSavingTrip: Binding<Bool>,
        isCreatingShare: Binding<Bool>,
        hasCreatedTrip: Binding<Bool>,
        shareURL: Binding<String?>,
        isCalendarPresented: Binding<Bool>,
        isEditingInvitationDetails: Binding<Bool>,
        isLocationSheetPresented: Binding<Bool>,
        onCreateTrip: @escaping () async throws -> String,
        onDismissAndReset: @escaping () -> Void,
        isViewOnly: Bool = false
    ) {
        self._draft = draft
        self._creationErrorMessage = creationErrorMessage
        self._shareErrorMessage = shareErrorMessage
        self.canConfirmTripCreation = canConfirmTripCreation
        self._isSavingTrip = isSavingTrip
        self._isCreatingShare = isCreatingShare
        self._hasCreatedTrip = hasCreatedTrip
        self._shareURL = shareURL
        self._isCalendarPresented = isCalendarPresented
        self._isEditingInvitationDetails = isEditingInvitationDetails
        self._isLocationSheetPresented = isLocationSheetPresented
        self.onCreateTrip = onCreateTrip
        self.onDismissAndReset = onDismissAndReset
        self.isViewOnly = isViewOnly
    }
    
    // Convenience initializer for read-only view from TripDetailView
    init(
        draft: Binding<TripDraft>,
        isViewOnly: Bool,
        isOwner: Bool = false,
        isCalendarPresented: Binding<Bool> = .constant(false),
        isEditingInvitationDetails: Binding<Bool> = .constant(false),
        isLocationSheetPresented: Binding<Bool> = .constant(false),
        onUpdateTrip: (() -> Void)? = nil,
        onDismiss: @escaping () -> Void
    ) {
        self._draft = draft
        self._creationErrorMessage = .constant(nil)
        self._shareErrorMessage = .constant(nil)
        self.canConfirmTripCreation = false
        self._isSavingTrip = .constant(false)
        self._isCreatingShare = .constant(false)
        self._hasCreatedTrip = .constant(true)
        self._shareURL = .constant(nil)
        self._isCalendarPresented = isCalendarPresented
        self._isEditingInvitationDetails = isEditingInvitationDetails
        self._isLocationSheetPresented = isLocationSheetPresented
        self.onCreateTrip = { "" }
        self.onDismissAndReset = onDismiss
        self.isViewOnly = isViewOnly
        self.isOwner = isOwner
        self.onUpdateTrip = onUpdateTrip
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
            
            if let creationErrorMessage {
                VStack {
                    Spacer()
                    Text(creationErrorMessage)
                        .font(.caption.bold())
                        .foregroundStyle(.red)
                        .padding()
                        .background(.black.opacity(0.8), in: Capsule())
                        .padding(.bottom, 120)
                }
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }
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
                    if !hasCreatedTrip || isViewOnly {
                        Button {
                            if isViewOnly {
                                onDismissAndReset()
                            } else {
                                dismiss()
                                onDismissAndReset()
                            }
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
                        if isViewOnly {
                            shareTripLink()
                        } else if hasCreatedTrip {
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
                        } else {
                            Task {
                                do {
                                    let code = try await onCreateTrip()
                                    copyShareLink(code)
                                    hasCreatedTrip = true
                                } catch {
                                    print("❌ onCreateTrip task failed with error: \(error)")
                                }
                            }
                        }
                    } label: {
                        HStack(spacing: 14) {
                            if isSavingTrip || isCreatingShare || isFetchingShareLink {
                                ProgressView()
                                    .tint(.white)
                                    .frame(height: 15)
                            } else {
                                Image(systemName: isViewOnly ? "link" : primaryButtonIconName)
                                    .font(.button())
                            }
                            
                            Text(isViewOnly ? "Share link" : buttonTitle)
                                .font(.button())
                                .fontWidth(.expanded)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(16)
                        .foregroundStyle(isViewOnly || canConfirmTripCreation || isSavingTrip || hasCreatedTrip || isCreatingShare ? .white : .white.opacity(0.52))
                        .overlay {
                            Capsule()
                                .stroke(isViewOnly || hasCreatedTrip ? Theme.secondary : Theme.primary, lineWidth: 1.5)
                        }
                    }
                    .glassEffect(.clear)
                    .disabled(isViewOnly ? isFetchingShareLink : (hasCreatedTrip ? false : (!canConfirmTripCreation || isSavingTrip)))
                    .accessibilityLabel(isViewOnly ? "Share link" : buttonTitle)
                    
                    if !hasCreatedTrip || isOwner {
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
                        .foregroundStyle(.white)
                        .overlay {
                            Capsule()
                                .stroke(Theme.primary, lineWidth: 1.5)
                        }
                    }
                    .glassEffect(.clear)
                    
                    Button {
                        dismissEditMode()
                        if isViewOnly {
                            onUpdateTrip?()
                        }
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
    
    private func shareTripLink() {
        guard !draft.invitationCode.isEmpty else { return }
        isFetchingShareLink = true
        
        Task {
            do {
                let inviteService = CloudKitInviteService()
                if let invite = try await inviteService.findInvite(by: draft.invitationCode) {
                    await MainActor.run {
                        isFetchingShareLink = false
                        shareURL(invite.shareURL)
                    }
                } else {
                    await MainActor.run {
                        isFetchingShareLink = false
                        if let url = URL(string: "https://omawe.app/join?code=\(draft.invitationCode)") {
                            shareURL(url)
                        }
                    }
                }
            } catch {
                await MainActor.run {
                    isFetchingShareLink = false
                    if let url = URL(string: "https://omawe.app/join?code=\(draft.invitationCode)") {
                        shareURL(url)
                    }
                }
            }
        }
    }

    private func shareURL(_ url: URL) {
        let activityVC = UIActivityViewController(activityItems: [url], applicationActivities: nil)
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let rootViewController = windowScene.windows.first?.rootViewController {
            
            if let popoverController = activityVC.popoverPresentationController {
                popoverController.sourceView = rootViewController.view
                popoverController.sourceRect = CGRect(x: rootViewController.view.bounds.midX, y: rootViewController.view.bounds.midY, width: 0, height: 0)
                popoverController.permittedArrowDirections = []
            }
            
            rootViewController.present(activityVC, animated: true, completion: nil)
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
        creationErrorMessage: .constant(nil),
        shareErrorMessage: .constant(nil),
        canConfirmTripCreation: true,
        isSavingTrip: .constant(false),
        isCreatingShare: .constant(false),
        hasCreatedTrip: .constant(false),
        shareURL: .constant("https://www.icloud.com/share/test"),
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



