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
    @Query(sort: \TripModel.createdAt, order: .reverse) var trips: [TripModel]
    @Query(sort: \TripMember.joinedAt, order: .forward) private var tripMembers: [TripMember]
    @Query(sort: \UserProfile.createdAt, order: .forward) private var userProfiles: [UserProfile]
    @State var selectedTripAction: TripAction?
    @State private var viewModel = HomeViewModel()
    @State var isTripStatusExpanded = false
    @State var isTripStatusPresented = false
    @State var selectedTripIndex = 0
    @Namespace private var dynamicIslandNamespace
    @State var createSlideProgress: CGFloat = 0
    @State var dynamicBoxSize: CGSize = .zero
    @State var isDynamicBoxExpanded = false
    @State var isTransitioningTopPanel = false
    @State var isProfilePresented = false
    // let screenSize = UIScreen.main.bounds.size
    
var body: some View {
    NavigationStack {
        ZStack(alignment: .top) {
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
            
            VStack {
                Spacer()
                ZStack {
                    Image(trips.isEmpty ? .tripStatusBar : .tripStatusBarCreated)
                    
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(trips.isEmpty ? "You have no trip yet" : "\(trips.count) upcoming \(trips.count == 1 ? "trip" : "trips")")
                                .font(.headline)
                            
                            Text(trips.isEmpty ? "Let's create or join a trip now" : "Drag down to see more")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                
                Spacer()
                
                VStack {
                    
                    Spacer()
                    
//                    ZStack {
//                        Circle()
//                            .frame(width: 120)
//                            .foregroundColor(.white)
//                            .shadow(color: .init(hex: "#00C3FF").opacity(0.5), radius: 21, x: 0, y: 0)
//                        Image(.frame74)
//                        Image(.avatar)
//                    }
                    
                    Button {
                        isProfilePresented = true
                    } label: {
                        ZStack {
                            Circle()
                                .frame(width: 120)
                                .foregroundColor(.white)
                                .shadow(color: .init(hex: "#00C3FF").opacity(0.5), radius: 21, x: 0, y: 0)

                            Image(.frame74)
                            Image(.avatar)
                        }
                    }
                    .buttonStyle(.plain)
                    
                    VStack(spacing: 12) {
                        Text("Hi Beani!")
                            .font(.largeTitle)
                            .fontWidth(.expanded)
                            .fontWeight(.semibold)
                            .foregroundColor(.cyan)
                        
                        
                        Text("Let's make your\nfirst Omawe")
                            .font(.bodyText())
                            .multilineTextAlignment(.center)
                    }
                    
                    Spacer()
                    
                    
                    VStack(spacing: 12) {
                        Image(systemName: "hand.draw")
                            .foregroundStyle(.gray.secondary)
                            .font(.title3())
                        
                        Text(trips.isEmpty ? "Swipe the slide\nto create or join trip" : "Drag down to\nsee your room")
                            .multilineTextAlignment(.center)
                            .foregroundStyle(.gray.secondary)
                        
                        HStack {
                            Image(systemName: trips.isEmpty ? "chevron.left.2" : "chevron.down.2")
                                .foregroundStyle(.gray.secondary)
                                .font(.title3())
                            
                            Image(systemName: trips.isEmpty ? "chevron.right.2" : "")
                                .foregroundStyle(.gray.secondary)
                                .font(.title3())
                        }
                    }
                    
                    
                }
                
                Spacer()
                
                CreateJoinButton(
                    createAction: {
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
                    },
                    joinAction: {
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
                    },
                    resetAction: {
                        if isTripStatusPresented {
                            closeTripStatusPanel()
                            return
                        }
                        withAnimation(.spring(response: 0.72, dampingFraction: 0.88)) {
                            isDynamicBoxExpanded = false
                            selectedTripAction = nil
                        }
                    },
                    createProgressChanged: { _ in
                        // The slider now only selects the Create action.
                        // The DynamicBox owns the expansion animation from the collapsed island.
                    }
                )
                .padding(.bottom, 30)
                .ignoresSafeArea()
                .frame(height: HomeLayout.bottomSliderHeight)
            }
            .padding(.horizontal, 10)
            .ignoresSafeArea(.keyboard, edges: .bottom)
            
            
            Group {
                let flowBottomInset = HomeLayout.bottomSliderReservedHeight + HomeLayout.createFlowBottomGap
                let nextStepHeight: CGFloat = 55
                let nextStepTopGap: CGFloat = 12
                let screenHeight = UIScreen.main.bounds.height
                let createTripViewportHeight = max(
                    0,
                    screenHeight - flowBottomInset - nextStepHeight - nextStepTopGap
                )
                VStack(spacing: nextStepTopGap) {
                    topPanelView
                        .scaleEffect(
                            topPanelScale,
                            anchor: .top
                        )
                        .opacity(topPanelOpacity)
                        .offset(y: topPanelVerticalOffset)
                        .allowsHitTesting(isDynamicBoxExpanded || isTripStatusExpanded)
                        .animation(.spring(response: 0.46, dampingFraction: 0.9), value: isDynamicBoxExpanded)
                        .animation(.spring(response: 0.54, dampingFraction: 0.88), value: isTripStatusExpanded)

                    
                    if selectedTripAction == .create && viewModel.nextStepRequest < 3 {
                        Button {
                            viewModel.nextStepRequest += 1
                        } label: {
                            HStack(spacing: 14) {
                                Text("Next step")
                                    .font(.system(size: 15, weight: .bold, design: .rounded))
                                    .fontWidth(.expanded)
                                
                                Image(systemName: "chevron.right")
                                    .font(.system(size: 15, weight: .bold))
                            }
                            .foregroundStyle(
                                viewModel.isNextStepEnabled
                                ? Color.black
                                : Color.gray.opacity(0.55)
                            )
                            .frame(maxWidth: .infinity)
                            .frame(height: nextStepHeight)
                            .shadow(
                                color: Color.omawePrimary.opacity(viewModel.isNextStepEnabled ? 0.16 : 0),
                                radius: 16,
                                x: 0,
                                y: 7
                            )
                        }
                        .glassEffect(.clear)
                        .overlay {
                            RoundedRectangle(cornerRadius: 37, style: .continuous)
                                .stroke(
                                    Color.omawePrimary.opacity(viewModel.isNextStepEnabled ? 0.95 : 0.35),
                                    lineWidth: 1.5
                                )
                                .allowsHitTesting(false)
                        }
                        .disabled(!viewModel.isNextStepEnabled)
                        .opacity(selectedTripAction == .create && isDynamicBoxExpanded ? 1 : 0)
                        .allowsHitTesting(selectedTripAction == .create && isDynamicBoxExpanded)
                        .padding(.horizontal, 10)
                        .animation(.spring(response: 0.42, dampingFraction: 0.86), value: viewModel.isNextStepEnabled)
                        .animation(.spring(response: 0.5, dampingFraction: 0.88), value: isDynamicBoxExpanded)
                    }
                }
                .frame(
                    maxWidth: .infinity,
                    maxHeight: .infinity,
                    alignment: .top
                )
                .padding(.bottom, flowBottomInset)
            }
            .ignoresSafeArea()
        }
        .contentShape(Rectangle())
        .simultaneousGesture(tripStatusOpenGesture)
        .animation(.spring(response: 0.5, dampingFraction: 0.9), value: selectedTripAction)
        .animation(.spring(response: 0.54, dampingFraction: 0.88), value: isTripStatusExpanded)
        .onChange(of: trips.count) { _, count in
            if count == 0 {
                isTripStatusExpanded = false
                selectedTripIndex = 0
            } else if selectedTripIndex >= count {
                selectedTripIndex = max(0, count - 1)
            }
        }
        .onChange(of: selectedTripAction) { _, action in
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
        .onChange(of: viewModel.isInvitationPresented) { _, isPresented in
            guard !isPresented else { return }

            // When returning from TripInvitationView, restore the final CreateTrip step
            if selectedTripAction == .create {
                isDynamicBoxExpanded = true
                viewModel.isNextStepEnabled = true
                viewModel.nextStepRequest = 2
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background {
            Image(.homeBackground)
                .resizable()
                .scaledToFill()
                .ignoresSafeArea()
        }
        .navigationDestination(isPresented: $viewModel.isInvitationPresented) {
            TripInvitationView(
                draft: $viewModel.createTripDraft,
                creationErrorMessage: viewModel.creationErrorMessage,
                canConfirmTripCreation: viewModel.canConfirmTripCreation,
                isSavingTrip: viewModel.isSavingTrip,
                hasCreatedTrip: viewModel.hasCreatedTrip,
                isCalendarPresented: $viewModel.isCalendarPresented,
                isEditingInvitationDetails: $viewModel.isEditingInvitationDetails,
                isLocationSheetPresented: $viewModel.isLocationPresented,
                onShareLink: {
                    Task {
                        await viewModel.confirmTripCreation(using: modelContext)
                    }
                },
                onTryAgain: {
                    Task {
                        await viewModel.confirmTripCreation(using: modelContext)
                    }
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
    
    @ViewBuilder
    private var topPanelView: some View {
        if isTripStatusPresented && !trips.isEmpty && selectedTripAction == nil {
            TripStatusDetailView(
                trips: trips,
                members: tripMembers,
                userProfiles: userProfiles,
                selectedTripIndex: $selectedTripIndex,
                onClose: closeTripStatusPanel
            )
        } else if selectedTripAction == .join {
            JoinTripView(
                selectedTripAction: $selectedTripAction
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
