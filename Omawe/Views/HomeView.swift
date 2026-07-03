//
//  HomeView.swift
//  Omawe
//
//  Created by Muhammad Bintang Al-Fath on 30/06/26.
//

import SwiftUI

enum TripAction {
    case create
    case join
}

struct HomeView: View {
    @State private var selectedTripAction: TripAction?
    @State private var nextStepRequest = 0
    @State private var isNextStepEnabled = false
    @Namespace private var dynamicIslandNamespace
    @State private var createSlideProgress: CGFloat = 0
    @State private var dynamicBoxSize: CGSize = .zero
    @State private var isDynamicBoxExpanded = false
    private let collapsedIslandWidth: CGFloat = 125
    private let expandedIslandWidth: CGFloat = 360
    private let dynamicIslandHeight: CGFloat = 35
    private let bottomSliderHeight: CGFloat = 120
    private let bottomSliderBottomPadding: CGFloat = 30
    private let createFlowBottomGap: CGFloat = 8

    private let dynamicIslandWidth: CGFloat = 125

    private var bottomSliderReservedHeight: CGFloat {
        bottomSliderHeight + bottomSliderBottomPadding
    }

    private var dynamicIslandDisplayWidth: CGFloat {
        collapsedIslandWidth
    }
    
    var body: some View {
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
            .opacity(selectedTripAction != .none ? 0 : 1)
            VStack {
                ZStack {
                    Image(.tripStatusBar)
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("You have no trip yet")
                                .font(.headline)
                            
                            Text("Let's create or join a trip now")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                .padding(.top, 64)
                
                Spacer()
                
                VStack {
                    ZStack {
                        Circle()
                            .frame(width: 120)
                            .foregroundColor(.white)
                            .shadow(color: .init(hex: "#00C3FF").opacity(0.5), radius: 21, x: 0, y: 0)
                        Image(.frame74)
                        Image(.avatar)
                    }
                    
                    Text("Hi Beani!")
                        .font(.largeTitle)
                        .fontWidth(.expanded)
                        .fontWeight(.semibold)
                        .foregroundColor(.cyan)
                    
                    
                    Text("Let's make your\nfirst Omawe")
                        .multilineTextAlignment(.center)
                }
                
                Spacer()
                
                CreateJoinButton(
                    createAction: {
                        selectedTripAction = .create
                        isDynamicBoxExpanded = false

                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.03) {
                            withAnimation(.spring(response: 0.46, dampingFraction: 0.9)) {
                                isDynamicBoxExpanded = true
                            }
                        }
                    },
                    joinAction: {
                        withAnimation(.spring(response: 0.82, dampingFraction: 0.86)) {
                            isDynamicBoxExpanded = false
                            selectedTripAction = .join
                        }
                    },
                    resetAction: {
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
                .frame(height: bottomSliderHeight)
                .padding(.bottom, bottomSliderBottomPadding)
            }
            .padding(.horizontal, 10)
            .padding(.top, 12)
            
            GeometryReader { proxy in
                let flowBottomInset = bottomSliderReservedHeight + createFlowBottomGap
                let nextStepHeight: CGFloat = 55
                let nextStepTopGap: CGFloat = 12
                let createTripViewportHeight = max(
                    0,
                    proxy.size.height - flowBottomInset - nextStepHeight - nextStepTopGap
                )

                VStack(spacing: nextStepTopGap) {
                    CreateTripView(
                        selectedTripAction: $selectedTripAction,
                        nextStepRequest: $nextStepRequest,
                        isNextStepEnabled: $isNextStepEnabled
                    )
                    .scaleEffect(
                        isDynamicBoxExpanded ? 1 : 0.18,
                        anchor: .top
                    )
                    .opacity(isDynamicBoxExpanded ? 1 : 0)
                    .offset(y: isDynamicBoxExpanded ? 0 : -8)
                    .allowsHitTesting(isDynamicBoxExpanded)
                    .animation(.spring(response: 0.46, dampingFraction: 0.9), value: isDynamicBoxExpanded)
                    .frame(
                        maxWidth: .infinity,
                        minHeight: 0,
                        maxHeight: createTripViewportHeight,
                        alignment: .top
                    )
                    
                    if nextStepRequest < 3 {
                        Button {
                            nextStepRequest += 1
                        } label: {
                            HStack(spacing: 14) {
                                Text("Next step")
                                    .font(.system(size: 15, weight: .bold, design: .rounded))
                                    .fontWidth(.expanded)

                                Image(systemName: "chevron.right")
                                    .font(.system(size: 15, weight: .bold))
                            }
                            .foregroundStyle(
                                isNextStepEnabled
                                    ? Color(red: 0.02, green: 0.05, blue: 0.18)
                                    : Color.gray.opacity(0.55)
                            )
                            .frame(maxWidth: .infinity)
                            .frame(height: nextStepHeight)
                            .shadow(
                                color: Color.omawePrimary.opacity(isNextStepEnabled ? 0.16 : 0),
                                radius: 16,
                                x: 0,
                                y: 7
                            )
                        }
                        .buttonStyle(.glass)
                        .overlay {
                            RoundedRectangle(cornerRadius: 37, style: .continuous)
                                .stroke(
                                    Color.omawePrimary.opacity(isNextStepEnabled ? 0.95 : 0.35),
                                    lineWidth: 1.5
                                )
                                .allowsHitTesting(false)
                        }
                        .disabled(!isNextStepEnabled)
                        .opacity(selectedTripAction == .create && isDynamicBoxExpanded ? 1 : 0)
                        .allowsHitTesting(selectedTripAction == .create && isDynamicBoxExpanded)
                        .padding(.horizontal, 10)
                        .animation(.spring(response: 0.42, dampingFraction: 0.86), value: isNextStepEnabled)
                        .animation(.spring(response: 0.5, dampingFraction: 0.88), value: isDynamicBoxExpanded)
                        .frame(height: 55)
                    }
                }
                .frame(
                    width: proxy.size.width,
                    height: proxy.size.height - flowBottomInset,
                    alignment: .top
                )
            }
            .ignoresSafeArea(.keyboard, edges: .bottom)
            
            
            
            
        }
        .animation(.spring(response: 0.5, dampingFraction: 0.9), value: selectedTripAction)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background {
            Image(.homeBackground)
                .resizable()
                .scaledToFill()
                .ignoresSafeArea()
        }
        .ignoresSafeArea()
    }
    private var dynamicBoxExpansionProgress: CGFloat {
        selectedTripAction == .create ? 1 : createSlideProgress
    }

    private var dynamicBoxCollapsedScaleX: CGFloat {
        guard dynamicBoxSize.width > 0 else { return 0.35 }
        return min(1, dynamicIslandWidth / dynamicBoxSize.width)
    }

    private var dynamicBoxCollapsedScaleY: CGFloat {
        guard dynamicBoxSize.height > 0 else { return 0.12 }
        return min(1, dynamicIslandHeight / dynamicBoxSize.height)
    }

    private var dynamicBoxScaleX: CGFloat {
        dynamicBoxCollapsedScaleX
            + ((1 - dynamicBoxCollapsedScaleX) * dynamicBoxExpansionProgress)
    }

    private var dynamicBoxScaleY: CGFloat {
        dynamicBoxCollapsedScaleY
            + ((1 - dynamicBoxCollapsedScaleY) * dynamicBoxExpansionProgress)
    }
}



#Preview {
    HomeView()
}
