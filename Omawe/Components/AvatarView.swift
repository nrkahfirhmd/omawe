import SwiftUI

struct AvatarView: View {
    let profile: UserProfile?
    let selectedAvatarFrame: AvatarFrameStyle
    var size: CGFloat = 60
    var initialsSize: CGFloat? = nil
    var showBackgroundCircle: Bool = true

    var body: some View {
        let displayName = ProfileHelper.displayName(for: profile)
        let initials = ProfileHelper.initials(for: displayName)
        
        let backgroundSize = size * 2.0
        let computedInitialsSize = initialsSize ?? (size * (44.0 / 60.0))
        let shadowRadius = size * (21.0 / 60.0)

        ZStack {
            if showBackgroundCircle {
                Circle()
                    .frame(width: backgroundSize, height: backgroundSize)
                    .foregroundColor(.white)
                    .shadow(color: .init(hex: "#00C3FF").opacity(0.5),
                            radius: shadowRadius)
            }

            Image(selectedAvatarFrame.image)
                .resizable()
                .scaledToFit()
                .frame(width: backgroundSize, height: backgroundSize)

            if let imageData = profile?.avatarImageData, let uiImage = UIImage(data: imageData) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFill()
                    .frame(width: size, height: size)
                    .clipShape(Circle())
            } else if let initials {
                Text(initials.uppercased())
                    .font(.system(size: computedInitialsSize, weight: .bold, design: .rounded))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Color(hex: "03B9D6"), Color(hex: "7AE8FF")],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .frame(width: size, height: size)
                    .glassEffect(.clear, in: .circle)
            } else {
                Image(.avatar)
                    .resizable()
                    .scaledToFit()
                    .frame(width: size, height: size)
            }
        }
    }
}
