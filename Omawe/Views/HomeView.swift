//
//  HomeView.swift
//  Omawe
//
//  Created by Muhammad Bintang Al-Fath on 30/06/26.
//

import SwiftUI

struct HomeView: View {
    var body: some View {
        ZStack {
            Image(.homeBackground)
            VStack {
                CustomDynamicIsland(
                    color: LinearGradient(stops: [
                        .init(color: Color.omawePrimary, location: 0),
                        .init(color: Color.omawePrimarySoft, location: 0.51),
                        .init(color: Color.omawePrimary, location: 1),
                    ], startPoint: .top, endPoint: UnitPoint.bottom),
                    borderWidth: 1,
                    width: 125,
                    height: 35
                )
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
                .padding(.top, 12)
                
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
                        print("Create tapped")
                    },
                    joinAction: {
                        print("Join tapped")
                    }
                )
                .frame(height: 160)
                .padding(.bottom, 30)
            }
            .padding(.horizontal, 10)
            .padding(.top, 10)
        }
        .ignoresSafeArea(edges: .top)
    }
}

private struct CreateJoinButton: View {
    let createAction: () -> Void
    let joinAction: () -> Void
    
    private enum Selection {
        case none
        case create
        case join
    }
    
    @State private var selection: Selection = .none
    
    @State private var dragOffset: CGFloat = 0
    @State private var dragStartOffset: CGFloat = 0
    @State private var isCenterControlPressed = false
    @State private var centerControlPressStartedAt: Date?
    @State private var centerControlSpinStoppedAt: Date?
    @State private var tapSpinAngle: Double = 0
    @State private var isCenterControlPopping = false
    
    private let controlSize: CGFloat = 100
    private let barHeight: CGFloat = 61
    private let horizontalInset: CGFloat = 18
    private let activationThreshold: CGFloat = 0.55
    
    var body: some View {
        GeometryReader { proxy in
            let maxOffset = max(
                0,
                (proxy.size.width - (horizontalInset * 2) - controlSize) / 2
            )
            let createDragProgress = min(max(-dragOffset / max(maxOffset, 1), 0), 1)
            let joinDragProgress = min(max(dragOffset / max(maxOffset, 1), 0), 1)
            let createProgress: CGFloat = selection == .create ? 1 : createDragProgress
            let joinProgress: CGFloat = selection == .join ? 1 : joinDragProgress
            let inactiveForeground = Color(red: 0.02, green: 0.05, blue: 0.18)
            
            
            VStack {
                Spacer()
                ZStack {
                    ZStack {
                        HStack(spacing: 0) {
                            RoundedRectangle(cornerRadius: 100)
                                .fill(
                                    LinearGradient(
                                        colors: [
                                            Color.omawePrimarySoft,
                                            Color.clear
                                            
                                        ],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .opacity(createProgress)
                            
                            RoundedRectangle(cornerRadius: 100)
                                .fill(
                                    LinearGradient(
                                        colors: [
                                            Color.clear,
                                            Color.omawePrimarySoft,
                                        ],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .opacity(joinProgress)
                        }
                        .animation(.easeOut(duration: 0.16), value: createProgress)
                        .animation(.easeOut(duration: 0.16), value: joinProgress)
                        
                        HStack(spacing: 0) {
                            Button {
                                triggerButtonSelection(.create)
                            } label: {
                                HStack {
                                    Text("Create")
                                        .font(.system(size: 15))
                                        .fontWeight(.semibold)
                                        .fontWidth(.expanded)
                                    Spacer()
                                    Image(systemName: "chevron.left.2")
                                }
                                .padding(.horizontal, 6)
                                .frame(maxWidth: .infinity, maxHeight: .infinity)
                                .contentShape(Rectangle())
                            }
                            .buttonStyle(.plain)
                            .foregroundStyle(Color.black)

                            Spacer()
                                .frame(width: controlSize)

                            Button {
                                triggerButtonSelection(.join)
                            } label: {
                                HStack {
                                    Image(systemName: "chevron.right.2")
                                    Spacer()
                                    Text("Join")
                                        .font(.system(size: 15))
                                        .fontWeight(.semibold)
                                        .fontWidth(.expanded)
                                }
                                .padding(.horizontal, 6)
                                .frame(maxWidth: .infinity, maxHeight: .infinity)
                                .contentShape(Rectangle())
                            }
                            .buttonStyle(.plain)
                            .foregroundStyle(Color.black)
                        }
                        .padding(.horizontal, 24)
                    }
                    .frame(height: barHeight)
                    .glassEffect(.clear)
                    .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                    
                    TimelineView(
                        .animation(
                            minimumInterval: 1.0 / 60.0,
                            paused: !isCenterControlPressed || centerControlSpinStoppedAt != nil
                        )
                    ) { timeline in
                        let spinEndDate = centerControlSpinStoppedAt ?? timeline.date
                        let elapsed = centerControlPressStartedAt.map {
                            spinEndDate.timeIntervalSince($0)
                        } ?? 0
                        let spinAngle = isCenterControlPressed
                        ? elapsed * 360.0 / 6
                        : 0
                        
                        centerControl(spinAngle: spinAngle + tapSpinAngle)
                            .offset(x: dragOffset)
                            .highPriorityGesture(
                                DragGesture(minimumDistance: 0)
                                    .onChanged { value in
                                        if !isCenterControlPressed {
                                            centerControlPressStartedAt = Date()
                                            centerControlSpinStoppedAt = nil
                                            isCenterControlPressed = true
                                        }
                                        
                                        let proposedOffset = dragStartOffset + value.translation.width
                                        dragOffset = min(max(proposedOffset, -maxOffset), maxOffset)
                                        
                                        if abs(dragOffset) >= maxOffset - 0.5,
                                           centerControlSpinStoppedAt == nil {
                                            centerControlSpinStoppedAt = Date()
                                        }
                                    }
                                    .onEnded { value in
                                        isCenterControlPressed = false
                                        centerControlPressStartedAt = nil
                                        centerControlSpinStoppedAt = nil
                                        
                                        let isTap = abs(value.translation.width) < 10 && abs(value.translation.height) < 10
                                        if isTap {
                                            triggerResetSelection()
                                        }
                                        
                                        let predictedOffset = dragStartOffset + value.predictedEndTranslation.width
                                        let projectedOffset = min(max(predictedOffset, -maxOffset), maxOffset)
                                        let normalizedOffset = maxOffset == 0 ? 0 : projectedOffset / maxOffset
                                        
                                        let reachedEdge: Bool
                                        let destination: CGFloat
                                        
                                        if normalizedOffset <= -activationThreshold {
                                            destination = -maxOffset
                                            reachedEdge = true
                                        } else if normalizedOffset >= activationThreshold {
                                            destination = maxOffset
                                            reachedEdge = true
                                        } else {
                                            destination = 0
                                            reachedEdge = false
                                        }
                                        
                                        withAnimation(.interactiveSpring(response: 0.22, dampingFraction: 0.88, blendDuration: 0.06)) {
                                            dragOffset = destination
                                        }
                                        dragStartOffset = destination
                                        
                                        guard reachedEdge else { return }
                                        triggerSelection(destination < 0 ? .create : .join, maxOffset: maxOffset)
                                    }
                            )
                            .scaleEffect(isCenterControlPressed || isCenterControlPopping ? 1.12 : 1)
                            .animation(.interactiveSpring(response: 0.28, dampingFraction: 0.78), value: dragOffset)
                            .animation(.easeOut(duration: 0.16), value: isCenterControlPressed)
                    }
                }
                .frame(width: proxy.size.width, height: controlSize)
                .onAppear {
                    dragStartOffset = dragOffset
                }
            }
            
        }
    }
    
    private func triggerResetSelection() {
        selection = .none

        withAnimation(.spring(response: 0.24, dampingFraction: 0.62)) {
            isCenterControlPopping = true
        }

        withAnimation(.easeInOut(duration: 0.42)) {
            tapSpinAngle += 360
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.22) {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.74)) {
                isCenterControlPopping = false
            }
        }
    }

    private func triggerButtonSelection(_ target: Selection) {
        selection = target

        if target == .create {
            createAction()
        } else {
            joinAction()
        }

        withAnimation(.spring(response: 0.24, dampingFraction: 0.62)) {
            isCenterControlPopping = true
        }

        withAnimation(.easeInOut(duration: 0.42)) {
            tapSpinAngle += 360
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.22) {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.74)) {
                isCenterControlPopping = false
            }
        }
    }

    private func triggerSelection(_ target: Selection, maxOffset: CGFloat) {
        let destination = target == .create ? -maxOffset : maxOffset

        withAnimation(.interactiveSpring(response: 0.22, dampingFraction: 0.88, blendDuration: 0.06)) {
            dragOffset = destination
            selection = target
        }
        dragStartOffset = destination

        if target == .create {
            createAction()
        } else {
            joinAction()
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.12) {
            withAnimation(.interactiveSpring(response: 0.24, dampingFraction: 0.9, blendDuration: 0.05)) {
                dragOffset = 0
            }
            dragStartOffset = 0
        }
    }
    
    private func centerControl(spinAngle: Double) -> some View {
        Button {
            triggerResetSelection()
        } label: {
            ZStack {
                Image(selection != .none ? .homeCircleSlide : .tapCircleSlide)
                    .shadow(color: .init(hex: "#00C3FF").opacity(0.5), radius: 21, x: 0, y: 0)
                
                Image(.omaweCircle)
                    .rotationEffect(.degrees(spinAngle))
            }
        }
        .buttonStyle(.plain)
    }
    
}

#Preview {
    HomeView()
}
