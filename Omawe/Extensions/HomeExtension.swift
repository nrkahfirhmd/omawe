import SwiftUI

// MARK: - Layout
enum HomeLayout {
    static let collapsedIslandWidth: CGFloat = 125
    static let expandedIslandWidth: CGFloat = 360
    static let dynamicIslandHeight: CGFloat = 35
    static let dynamicIslandWidth: CGFloat = 125
    static let bottomSliderHeight: CGFloat = 120
    static let bottomSliderBottomPadding: CGFloat = 30
    static let createFlowBottomGap: CGFloat = 8

    static var bottomSliderReservedHeight: CGFloat {
        bottomSliderHeight + bottomSliderBottomPadding
    }

    static var dynamicIslandDisplayWidth: CGFloat {
        collapsedIslandWidth
    }
}

// MARK: - Animation
extension HomeView {
    var topPanelScale: CGFloat {
        // TripStatus uses presented and expanded states for animation, CreateTrip uses dynamicBox
        if isTripStatusPresented && !isTripStatusExpanded {
            return 0.18
        } else if isTripStatusPresented && isTripStatusExpanded {
            return 1
        } else if isDynamicBoxExpanded {
            return 1
        } else {
            return 0.18
        }
    }

    var topPanelOpacity: Double {
        // Opacity is 1 whenever TripStatus is presented (even if not expanded), or CreateTrip is expanded
        if isTripStatusPresented {
            return 1
        } else if isDynamicBoxExpanded {
            return 1
        } else {
            return 0
        }
    }

    var topPanelVerticalOffset: CGFloat {
        // Offset is -8 while TripStatus is presented but not expanded, 0 when expanded
        if isTripStatusPresented && !isTripStatusExpanded {
            return -8
        } else if isTripStatusPresented && isTripStatusExpanded {
            return 0
        } else if isDynamicBoxExpanded {
            return 0
        } else {
            return -8
        }
    }
}

// MARK: - Gesture
extension HomeView {
    var tripStatusOpenGesture: some Gesture {
        DragGesture(minimumDistance: 18)
            .onEnded { value in
                guard !isTransitioningTopPanel else { return }
                guard viewModel.trips.isEmpty == false else { return }
                guard selectedTripAction == nil else { return }
                guard isTripStatusPresented == false else { return }
                guard value.translation.height > 48 else { return }
                guard abs(value.translation.width) < 72 else { return }

                isTransitioningTopPanel = true
                
                Task {
                    await viewModel.loadTrips()
                }
                
                // Show panel in collapsed state, then animate to expanded (mirroring CreateTrip)
                selectedTripIndex = min(selectedTripIndex, viewModel.trips.count - 1)
                isTripStatusPresented = true
                isTripStatusExpanded = false
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.03) {
                    withAnimation(.spring(response: 0.54, dampingFraction: 0.88)) {
                        isTripStatusExpanded = true
                    }
                    // After expansion, allow transitions again
                    isTransitioningTopPanel = false
                }
            }
    }
}

// MARK: - Dynamic Box
extension HomeView {
    var dynamicBoxExpansionProgress: CGFloat {
        selectedTripAction == .create ? 1 : createSlideProgress
    }

    var dynamicBoxCollapsedScaleX: CGFloat {
        guard dynamicBoxSize.width > 0 else { return 0.35 }
        return min(1, HomeLayout.dynamicIslandWidth / dynamicBoxSize.width)
    }

    var dynamicBoxCollapsedScaleY: CGFloat {
        guard dynamicBoxSize.height > 0 else { return 0.12 }
        return min(1, HomeLayout.dynamicIslandHeight / dynamicBoxSize.height)
    }

    var dynamicBoxScaleX: CGFloat {
        dynamicBoxCollapsedScaleX
        + ((1 - dynamicBoxCollapsedScaleX) * dynamicBoxExpansionProgress)
    }

    var dynamicBoxScaleY: CGFloat {
        dynamicBoxCollapsedScaleY
        + ((1 - dynamicBoxCollapsedScaleY) * dynamicBoxExpansionProgress)
    }
}