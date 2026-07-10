import SwiftUI

// MARK: - Trip Data
struct TripData: Identifiable {
    let id = UUID()
    var theme: AppTheme
    var icon: String
    var title: String
    var subtitle: String
    var people: Int
    var location: String
    var footerTitle: String
}

// MARK: - Trip Detail View
struct TripNotStarted: View {
    var trips: [TripData]
    @State private var currentPage = 0
    
    private var currentTrip: TripData { trips[currentPage] }
    
    var body: some View {
        ZStack(alignment: .top) {
            Color.white
                .ignoresSafeArea()
            
            VStack {
                VStack {
                    DynamicBox(
                        theme: currentTrip.theme,
                        icon: currentTrip.icon,
                        title: currentTrip.title,
                        subtitle: currentTrip.subtitle,
                        helperText: "Swipe to see other trips",
                        footerTitle: currentTrip.footerTitle
                    ) {
                        VStack {
                            PeopleOrbit(people: currentTrip.people)
                                .padding(.bottom, 16)
                            
                            HStack(spacing: 4) {
                                Image(systemName: "location.circle.fill")
                                Text(currentTrip.location)
                                    .contentTransition(.numericText())
                            }
                            .font(.caption.bold())
                            .foregroundStyle(Color(uiColor: .tertiarySystemBackground).opacity(0.7))
                            .padding(.bottom, 24)
                            
                            HStack(spacing: 12) {
                                StartTripButton()
                                
                                Button {
                                    
                                } label: {
                                    Image(systemName: "list.bullet.indent")
                                        .font(.largeTitle)
                                        .foregroundStyle(Color.primary)
                                        .frame(width: 55, height: 55)
                                }
                                .buttonStyle(.glass)
                                .clipShape(Circle())
                            }
                            .padding(.horizontal, 24)
                            .padding(.bottom, 16)
                            
                            // Page dots
                            TripPageIndicator(totalPages: trips.count, currentPage: currentPage)
                                .padding(.bottom, 40)
                        }
                    }
                    .animation(.smooth(duration: 0.4), value: currentPage)
                }
                .gesture(
                    DragGesture()
                        .onEnded { value in
                            let threshold: CGFloat = 50
                            withAnimation(.smooth(duration: 0.4)) {
                                if value.translation.width < -threshold && currentPage < trips.count - 1 {
                                    currentPage += 1
                                } else if value.translation.width > threshold && currentPage > 0 {
                                    currentPage -= 1
                                }
                            }
                        }
                )
            }
        }
        .ignoresSafeArea(edges: .top)
    }
}

// MARK: - Trip Page Indicator
struct TripPageIndicator: View {
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
            }
        }
    }
}

// MARK: - Start Trip Button
struct StartTripButton: View {
    var isDisabled: Bool = false
    var action: () -> Void = {}

    var body: some View {
        Button(action: action) {
            Text("Start trip now")
                .font(.subheadline)
                .fontWeight(.semibold)
                .fontWidth(.expanded)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 22.5)
                .background(
                    Capsule()
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color(red: 0.05, green: 0.25, blue: 0.24),
                                    Color(red: 0.11, green: 0.35, blue: 0.32)
                                ],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                )
                .overlay(
                    Capsule()
                        .strokeBorder(
                            Color(red: 0.4, green: 0.85, blue: 0.9),
                            lineWidth: 2
                        )
                        .shadow(color: Color(red: 0.4, green: 0.85, blue: 0.9).opacity(0.6), radius: 8)
                )
                .clipShape(Capsule())
                .opacity(isDisabled ? 0.5 : 1)
        }
        .disabled(isDisabled)
    }
}
