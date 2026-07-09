//
//  CreateJoinButton.swift
//  Omawe
//
//  Created by Muhammad Bintang Al-Fath on 02/07/26.
//

import SwiftUI

struct CreateJoinButton: View {
    let createAction: () -> Void
    let joinAction: () -> Void
    let resetAction: () -> Void
    let createProgressChanged: (CGFloat) -> Void
    
    private enum Selection {
        case none
        case create
        case join
        case view
    }
    
    @State private var selection: Selection = .none
    @State private var lastHapticZone: Selection = .none
    
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
            let createIsDisabled = selection == .join
            let joinIsDisabled = selection == .create
            let activeForeground = Color.black
            let disabledForeground = Color.gray.opacity(0.45)
            
            
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
                            .foregroundStyle(createIsDisabled ? disabledForeground : activeForeground)

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
                            .foregroundStyle(joinIsDisabled ? disabledForeground : activeForeground)
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
                                            lastHapticZone = .none
                                            HapticManager.shared.impact(style: .light)
                                        }
                                        
                                        let proposedOffset = dragStartOffset + value.translation.width
                                        dragOffset = min(max(proposedOffset, -maxOffset), maxOffset)
                                        let progress = min(max(-dragOffset / max(maxOffset, 1), 0), 1)
                                        createProgressChanged(progress)
                                        
                                        let dragNormalizedOffset = maxOffset == 0 ? 0 : dragOffset / maxOffset
                                        let currentZone: Selection
                                        if dragNormalizedOffset <= -activationThreshold {
                                            currentZone = .create
                                        } else if dragNormalizedOffset >= activationThreshold {
                                            currentZone = .join
                                        } else {
                                            currentZone = .none
                                        }
                                        
                                        if currentZone != lastHapticZone {
                                            if currentZone != .none {
                                                HapticManager.shared.impact(style: .medium)
                                            } else {
                                                HapticManager.shared.impact(style: .light)
                                            }
                                            lastHapticZone = currentZone
                                        }
                                        
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
                                            createProgressChanged(destination < 0 ? 1 : 0)
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
        createProgressChanged(0)
        resetAction()
        HapticManager.shared.impact(style: .light)
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
        createProgressChanged(target == .create ? 1 : 0)

        if target == .create {
            createAction()
        } else {
            joinAction()
        }
        HapticManager.shared.success()

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
            createProgressChanged(target == .create ? 1 : 0)
        }
        dragStartOffset = destination

        if target == .create {
            createAction()
        } else {
            joinAction()
        }
        HapticManager.shared.success()

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.12) {
            withAnimation(.interactiveSpring(response: 0.24, dampingFraction: 0.9, blendDuration: 0.05)) {
                dragOffset = 0
            }
            dragStartOffset = 0
        }
    }
    
    private var shouldShowOmaweCircle: Bool {
        return isCenterControlPressed || isCenterControlPopping
    }

    private func centerControl(spinAngle: Double) -> some View {
        Button {
            triggerResetSelection()
        } label: {
            ZStack {
                Image(.sliderButton)
                
                Image(selection != .none ? .homeCircleSlide : .tapCircleSlide)
                    .resizable()
                    .scaledToFit()
                    .frame(width: shouldShowOmaweCircle ? 50 : 80)

                Image(.omaweCircle)
                    .rotationEffect(.degrees(spinAngle))
                    .scaleEffect(shouldShowOmaweCircle ? 1 : 0.72)
                    .opacity(shouldShowOmaweCircle ? 1 : 0)
                    .animation(
                        .spring(response: 0.28, dampingFraction: 0.72),
                        value: shouldShowOmaweCircle
                    )
            }
        }
        .shadow(color: .init(hex: "#00C3FF").opacity(0.5), radius: 21, x: 0, y: 0)
        .buttonStyle(.plain)
    }
    
}

#Preview {
    ZStack {
        LinearGradient(
            colors: [
                Color.white,
                Color.white
            ],
            startPoint: .top,
            endPoint: .bottom
        )
        .ignoresSafeArea()

        VStack {
            Spacer()

            CreateJoinButton(
                createAction: {},
                joinAction: {},
                resetAction: {},
                createProgressChanged: { _ in }
            )
            .frame(height: 180)
            .padding(.horizontal, 16)
            .padding(.bottom, 32)
        }
    }
}
