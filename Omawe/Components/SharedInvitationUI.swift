import SwiftUI
import SwiftData

struct InvitationTicketContainer<Content: View>: View {
    var isEditing: Bool = false
    var isJoined: Bool = false
    @ViewBuilder var content: () -> Content
    
    var body: some View {
        let shape = UnevenRoundedRectangle(
            topLeadingRadius: isEditing ? 0 : 48,
            bottomLeadingRadius: 48,
            bottomTrailingRadius: 48,
            topTrailingRadius: isEditing ? 0 : 48,
            style: .continuous
        )
        
        return ZStack {
            InvitationTicketBackground(isEditing: isEditing, isJoined: isJoined)
            content()
        }
        .clipShape(shape)
        .overlay {
            shape
                .stroke(
                    LinearGradient(
                        stops: [
                            .init(color: Color(hex: "#1C1C1C"), location: 0),
                            .init(color: Color(hex: "#3F3F3F"), location: 0.51),
                            .init(color: Color(hex: "#1C1C1C"), location: 1),
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    ),
                    lineWidth: 1
                )
        }
        .shadow(color: .black.opacity(0.38), radius: 28, x: 0, y: 18)
    }
}

struct InvitationTicketBackground: View {
    var isEditing: Bool = false
    var isJoined: Bool = false
    @Query(sort: \UserProfile.createdAt, order: .forward) private var userProfiles: [UserProfile]
    @AppStorage("selectedAvatarFrame") private var selectedAvatarFrame: AvatarFrameStyle = .dark
    private var cardHeight: CGFloat {
        if isEditing {
            return 0.35
        } else if isJoined {
            return 0.80
        } else {
            return 0.48
        }
    }
    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .bottom) {
                Image(.moire)
                    .resizable()
                    .scaledToFill()
                
                if isJoined {
                    VStack {
                        AvatarView(
                            profile: ProfileHelper.currentUserProfile(from: userProfiles),
                            selectedAvatarFrame: selectedAvatarFrame,
                            size: 100,
                        )
                        .padding(.top, 20)
                        
                        Spacer()
                    }
                }
                
                ZStack {
                    LinearGradient(
                        colors: [
                            .black,
                            Theme.primaryBox,
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    
                    PlusPattern()
                        .mask(
                            LinearGradient(
                                colors: [.clear, .white],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                }
                .clipShape(BottomWave())
                .frame(height: geo.size.height * cardHeight)
            }
        }
    }
}

struct BottomWave: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        
        let amplitude: CGFloat = 10
        let wavelength: CGFloat = 42
        
        path.move(to: .zero)
        
        var x: CGFloat = 0
        
        while x <= rect.width {
            path.addQuadCurve(
                to: CGPoint(x: x + wavelength / 2, y: amplitude),
                control: CGPoint(x: x + wavelength / 4, y: 0)
            )
            
            path.addQuadCurve(
                to: CGPoint(x: x + wavelength, y: 10),
                control: CGPoint(x: x + wavelength * 0.75, y: amplitude * 2)
            )
            
            x += wavelength
        }
        
        path.addLine(to: CGPoint(x: rect.width, y: rect.height))
        path.addLine(to: CGPoint(x: 0, y: rect.height))
        path.closeSubpath()
        
        return path
    }
}

struct SpotlightShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.midX - 65, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.midX + 65, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX + 700, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX - 700, y: rect.maxY))
        path.closeSubpath()
        return path
    }
}

#Preview {
    InvitationTicketBackground(isEditing: false , isJoined: true)
}
