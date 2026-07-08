import SwiftUI

struct InvitationTicketContainer<Content: View>: View {
    var isEditing: Bool = false
    @ViewBuilder var content: () -> Content
    
    var body: some View {
        ZStack {
            InvitationTicketBackground(isEditing: isEditing)
            content()
        }
        .clipShape(RoundedRectangle(cornerRadius: isEditing ? 0 : 48, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 48, style: .continuous)
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
    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .bottom) {
                Image(.moire)
                    .resizable()
                    .scaledToFill()
                
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
                .frame(height: isEditing ? geo.size.height * 0.3 : geo.size.height * 0.48)
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
