//
//  HomeView.swift
//  Omawe
//
//  Created by Muhammad Bintang Al-Fath on 30/06/26.
//

import SwiftUI
import SwiftData

enum TripAction {
    case create
    case join
}

struct HomeView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.scenePhase) private var scenePhase
    @Query(sort: \UserProfile.createdAt, order: .forward) private var userProfiles: [UserProfile]
    @State var selectedTripAction: TripAction?
    @State var viewModel = HomeViewModel()
    @State var isTripStatusExpanded = false
    @State var isTripStatusPresented = false
    @State var selectedTripIndex = 0
    @Namespace private var dynamicIslandNamespace
    @State var createSlideProgress: CGFloat = 0
    @State var dynamicBoxSize: CGSize = .zero
    @State var isDynamicBoxExpanded = false
    @State var isTransitioningTopPanel = false
    @State var isProfilePresented = false
    @State private var isKeyboardVisible = false

    var body: some View {
        NavigationStack {
            ZStack(alignment: .top) {
                dynamicIslandOverlay
                mainContentStack
                createFlowOverlay
            }
            .contentShape(Rectangle())
            .simultaneousGesture(tripStatusOpenGesture)
            .animation(.spring(response: 0.5, dampingFraction: 0.9), value: selectedTripAction)
            .animation(.spring(response: 0.54, dampingFraction: 0.88), value: isTripStatusExpanded)
            .onChange(of: viewModel.trips.count, handleTripsCountChange)
            .onChange(of: selectedTripAction, handleSelectedTripActionChange)
            .onChange(of: viewModel.isInvitationPresented, handleInvitationPresentedChange)
            .onChange(of: scenePhase) { oldPhase, newPhase in
                if newPhase == .active {
                    Task {
                        await viewModel.loadTrips()
                    }
                }
            }
            .onReceive(NotificationCenter.default.publisher(for: CloudKitShareAcceptanceBridge.notificationName)) { notification in
                Task { await viewModel.acceptShare(from: notification) }
            }
            .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardWillShowNotification)) { _ in
                withAnimation(.easeOut(duration: 0.25)) {
                    isKeyboardVisible = true
                }
            }
            .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardWillHideNotification)) { _ in
                withAnimation(.easeOut(duration: 0.25)) {
                    isKeyboardVisible = false
                }
            }
            .onOpenURL { url in
                Task { await viewModel.acceptShare(from: url) }
            }
            .task {
                await viewModel.loadTrips()
                
                for metadata in CloudKitShareAcceptanceBridge.drainPendingMetadata() {
                    await viewModel.acceptShare(metadata)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            .background(homeBackground)
            .navigationDestination(isPresented: $viewModel.isInvitationPresented) {
                tripInvitationDestination
            }
            .navigationDestination(item: $viewModel.joinPreviewTrip) { trip in
                InvitationEnvelopeView(
                    trip: trip,
                    onJoinNow: {
                        try await viewModel.confirmJoinTrip(trip: trip)
                    },
                    onDismiss: {
                        viewModel.joinPreviewTrip = nil
                    }
                )
            }
            .sheet(isPresented: $isProfilePresented) {
                ProfileView()
                    .presentationDetents([.large])
                    .presentationDragIndicator(.visible)
            }
        }
    }
    
    // MARK: - Top-level pieces
    
    private var dynamicIslandOverlay: some View {
        CustomDynamicIsland(
            color: .black,
            borderColor: LinearGradient(stops: [
                .init(color: Color(hex: "03B9D6"), location: 0.0),
                .init(color: Color(hex: "7AE8FF"), location: 0.51),
                .init(color: Color(hex: "03B9D6"), location: 1.0),
            ], startPoint: UnitPoint.leading, endPoint: .trailing)
        )
        .padding(.top, 8)
        .opacity(selectedTripAction != .none || isTripStatusExpanded ? 0 : 1)
        .ignoresSafeArea(edges: .top)
    }
    
    private var mainContentStack: some View {
        VStack {
            Spacer()
            tripStatusBarView
            Spacer()
            greetingAndHintView
            Spacer()
            createJoinButtonView
        }
        .padding(.horizontal, 10)
        .ignoresSafeArea(.keyboard, edges: .bottom)
    }
    
    private var homeBackground: some View {
        Image(.homeBackground)
            .resizable()
            .scaledToFill()
            .ignoresSafeArea()
    }
    
    private var tripInvitationDestination: some View {
        TripInvitationView(
            draft: $viewModel.createTripDraft,
            creationErrorMessage: viewModel.creationErrorMessage,
            shareErrorMessage: viewModel.shareErrorMessage,
            canConfirmTripCreation: viewModel.canConfirmTripCreation,
            isSavingTrip: viewModel.isSavingTrip,
            isCreatingShare: viewModel.isCreatingShare,
            hasCreatedTrip: viewModel.hasCreatedTrip,
            shareURL: viewModel.shareURL,
            isCalendarPresented: $viewModel.isCalendarPresented,
            isEditingInvitationDetails: $viewModel.isEditingInvitationDetails,
            isLocationSheetPresented: $viewModel.isLocationPresented,
            onCreateTrip: {
                let code = try await viewModel.confirmTripCreation(using: modelContext)
                return code
            },
            onDismissAndReset: {
                viewModel.isInvitationPresented = false
                selectedTripAction = nil
                isDynamicBoxExpanded = false
                viewModel.resetCreateTripFlow()
            }
        )
    }
    
    // MARK: - Trip status bar
    
    private var tripStatusBarView: some View {
        ZStack {
            Image(viewModel.trips.isEmpty ? .tripStatusBar : .tripStatusBarCreated)
            
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(tripStatusTitle)
                        .font(.headline)
                    
                    Text(tripStatusSubtitle)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
    
    private var tripStatusTitle: String {
        viewModel.trips.isEmpty ? "You have no trip yet" : "\(viewModel.trips.count) upcoming \(viewModel.trips.count == 1 ? "trip" : "trips")"
    }
    
    private var tripStatusSubtitle: String {
        viewModel.trips.isEmpty ? "Let's create or join a trip now" : "Drag down to see more"
    }
    
    // MARK: - Greeting / hint
    
    private var greetingAndHintView: some View {
        VStack {
            Spacer()
            avatarView
            greetingTextView
            Spacer()
            swipeHintView
        }
        .opacity(selectedTripAction == nil ? 1 : 0)
        .scaleEffect(selectedTripAction == nil ? 1 : 0.92)
        .offset(y: selectedTripAction == nil ? 0 : -20)
    }
    
    /// The user's avatar.
    /// Apple Sign In does NOT provide a profile photo, so we generate
    /// an initials-based avatar using the first character of the display name.
    /// Falls back to a person icon if no name is available.
    private var avatarView: some View {
        let session = UserSession.shared
        let initials = session.displayName?.first.map(String.init)

        return Button {
            isProfilePresented = true
        } label: {
            ZStack {
                Circle()
                    .frame(width: 120)
                    .foregroundColor(.white)
                    .shadow(color: .init(hex: "#00C3FF").opacity(0.5),
                            radius: 21)

                Image(.frame74)

                if let initials {
                    Text(initials.uppercased())
                        .font(.system(size: 44, weight: .bold, design: .rounded))
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
                }
            }
        }
        .buttonStyle(.plain)
    }
    
    /// Greeting text that displays the user's first name from Apple Sign In.
    /// Falls back to "there" if no name was shared (e.g. user chose to hide it).
    private var greetingTextView: some View {
        let session = UserSession.shared
        // Extract just the first name for a friendly greeting.
        // Apple provides the full name as components; we use the first word
        // of the display name for brevity (e.g. "Muhammad" from "Muhammad Bintang").
        let firstName = session.displayName?
            .split(separator: " ")
            .first
            .map(String.init) ?? "there"

        return VStack(spacing: 12) {
            Text("Hi \(firstName)!")
                .font(.largeTitle)
                .fontWidth(.expanded)
                .fontWeight(.semibold)
                .foregroundColor(.cyan)
            
            Text("Let's make your\nfirst Omawe")
                .font(.bodyText())
                .multilineTextAlignment(.center)
        }
    }
    
    private var swipeHintView: some View {
        let hasTrips = !viewModel.trips.isEmpty

        return VStack(spacing: 12) {
            Image(systemName: "hand.draw")

            Text(swipeHintText)
                .multilineTextAlignment(.center)

            HStack(spacing: 4) {
                if hasTrips {
                    Image(systemName: "chevron.down.2")
                } else {
                    Image(systemName: "chevron.left.2")
                    Image(systemName: "chevron.right.2")
                }
            }
            .font(.title3())
        }
        .foregroundStyle(.gray.secondary)
    }
    
    private var swipeHintText: String {
        viewModel.trips.isEmpty ? "Swipe the slide\nto create or join trip" : "Drag down to\nsee your room"
    }
    
    // MARK: - Create / Join button
    
    private var createJoinButtonView: some View {
        CreateJoinButton(
            createAction: handleCreateAction,
            joinAction: handleJoinAction,
            resetAction: handleResetAction,
            createProgressChanged: { _ in }
        )
        .padding(.bottom, 30)
        .ignoresSafeArea()
        .frame(height: HomeLayout.bottomSliderHeight)
    }
    
    private func handleCreateAction() {
        guard !isTransitioningTopPanel else { return }
        if isTripStatusPresented {
            closeTripStatusPanel()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.20) {
                selectedTripAction = .create
                isDynamicBoxExpanded = false
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.03) {
                    withAnimation(.spring(response: 0.46, dampingFraction: 0.9)) {
                        isDynamicBoxExpanded = true
                    }
                }
            }
        } else {
            selectedTripAction = .create
            isDynamicBoxExpanded = false
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.03) {
                withAnimation(.spring(response: 0.46, dampingFraction: 0.9)) {
                    isDynamicBoxExpanded = true
                }
            }
        }
    }
    
    private func handleJoinAction() {
        guard !isTransitioningTopPanel else { return }
        if isTripStatusPresented {
            closeTripStatusPanel()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.20) {
                selectedTripAction = .join
                isDynamicBoxExpanded = false
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.03) {
                    withAnimation(.spring(response: 0.46, dampingFraction: 0.9)) {
                        isDynamicBoxExpanded = true
                    }
                }
            }
        } else {
            selectedTripAction = .join
            isDynamicBoxExpanded = false
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.03) {
                withAnimation(.spring(response: 0.46, dampingFraction: 0.9)) {
                    isDynamicBoxExpanded = true
                }
            }
        }
    }
    
    private func handleResetAction() {
        if isTripStatusPresented {
            closeTripStatusPanel()
            return
        }
        withAnimation(.spring(response: 0.72, dampingFraction: 0.88)) {
            isDynamicBoxExpanded = false
            selectedTripAction = nil
        }
    }
    
    // MARK: - Create flow overlay (top panel + Next step button)
    
    private var createFlowOverlay: some View {
        let flowBottomInset = HomeLayout.bottomSliderReservedHeight + HomeLayout.createFlowBottomGap
        let nextStepTopGap: CGFloat = 12
        
        return VStack(spacing: nextStepTopGap) {
            topPanelView
                .scaleEffect(topPanelScale, anchor: .top)
                .opacity(topPanelOpacity)
                .offset(y: topPanelVerticalOffset)
                .allowsHitTesting(isDynamicBoxExpanded || isTripStatusExpanded)
                .animation(.spring(response: 0.46, dampingFraction: 0.9), value: isDynamicBoxExpanded)
                .animation(.spring(response: 0.54, dampingFraction: 0.88), value: isTripStatusExpanded)
            
            if selectedTripAction == .create && viewModel.nextStepRequest < 3 {
                nextStepButton
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .padding(.bottom, isKeyboardVisible ? 50 : flowBottomInset)
        .ignoresSafeArea(.container)
    }
    
    private var nextStepButton: some View {
        let nextStepHeight: CGFloat = 55
        let isEnabled = viewModel.isNextStepEnabled
        
        return Button {
            viewModel.nextStepRequest += 1
        } label: {
            HStack(spacing: 14) {
                Text("Next step")
                    .font(.system(size: 15, weight: .bold, design: .rounded))
                    .fontWidth(.expanded)
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 15, weight: .bold))
            }
            .foregroundStyle(isEnabled ? Color.black : Color.gray.opacity(0.55))
            .frame(maxWidth: .infinity)
            .frame(height: nextStepHeight)
            .shadow(
                color: Color.omawePrimary.opacity(isEnabled ? 0.16 : 0),
                radius: 16,
                x: 0,
                y: 7
            )
        }
        .glassEffect(.clear)
        .overlay {
            RoundedRectangle(cornerRadius: 37, style: .continuous)
                .stroke(
                    Color.omawePrimary.opacity(isEnabled ? 0.95 : 0.35),
                    lineWidth: 1.5
                )
                .allowsHitTesting(false)
        }
        .disabled(!isEnabled)
        .opacity(selectedTripAction == .create && isDynamicBoxExpanded ? 1 : 0)
        .allowsHitTesting(selectedTripAction == .create && isDynamicBoxExpanded)
        .padding(.horizontal, 10)
        .animation(.spring(response: 0.42, dampingFraction: 0.86), value: isEnabled)
        .animation(.spring(response: 0.5, dampingFraction: 0.88), value: isDynamicBoxExpanded)
    }
    
    // MARK: - Top panel
    
    @ViewBuilder
    private var topPanelView: some View {
        if isTripStatusPresented && !viewModel.trips.isEmpty && selectedTripAction == nil {
            TripStatusDetailView(
                trips: viewModel.trips,
                members: viewModel.participants,
                userProfiles: userProfiles,
                selectedTripIndex: $selectedTripIndex,
                onClose: closeTripStatusPanel
            )
        } else if selectedTripAction == .join {
            JoinTripView(
                selectedTripAction: $selectedTripAction,
                onJoinInvitationCode: { code in
                    try await viewModel.previewTrip(invitationCode: code)
                },
                onAcceptShareLink: { url in
                    try await viewModel.acceptShare(from: url)
                }
            )
        } else {
            CreateTripView(
                draft: $viewModel.createTripDraft,
                selectedTripAction: $selectedTripAction,
                nextStepRequest: $viewModel.nextStepRequest,
                isNextStepEnabled: $viewModel.isNextStepEnabled,
                isInvitationPreviewPresented: $viewModel.isInvitationPresented,
                isCalendarPresented: $viewModel.isCalendarPresented,
                isLocationSheetPresented: $viewModel.isLocationPresented
            )
        }
    }
    
    // MARK: - onChange handlers (extracted so `.onChange` closures stay tiny)
    
    private func handleTripsCountChange(_ old: Int, _ count: Int) {
        if count == 0 {
            isTripStatusExpanded = false
            selectedTripIndex = 0
        } else if selectedTripIndex >= count {
            selectedTripIndex = max(0, count - 1)
        }
    }
    
    private func handleSelectedTripActionChange(_ old: TripAction?, _ action: TripAction?) {
        guard let action else {
            viewModel.resetCreateTripFlow()
            return
        }
        isTripStatusExpanded = false
        if action != .create {
            viewModel.isInvitationPresented = false
            viewModel.resetCreateTripFlow()
        }
    }
    
    private func handleInvitationPresentedChange(_ old: Bool, _ isPresented: Bool) {
        guard !isPresented else { return }
        if selectedTripAction == .create {
            isDynamicBoxExpanded = true
            viewModel.isNextStepEnabled = true
            viewModel.nextStepRequest = 2
        }
    }
    
    private func closeTripStatusPanel() {
        if isTransitioningTopPanel { return }
        isTransitioningTopPanel = true
        withAnimation(.spring(response: 0.28, dampingFraction: 0.90)) {
            isTripStatusExpanded = false
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.18) {
            isTripStatusPresented = false
            isTransitioningTopPanel = false
        }
    }
}



#Preview {
    HomeView()
}
