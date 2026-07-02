//
//  DynamicBox.swift
//  Omawe
//
//  Created by Gleenryan on 01/07/26.
//
import SwiftUI

struct DynamicBox<Content: View>: View {
    var theme: AppTheme
    var icon: String?
    var title: String?
    var subtitle: String?
    var helperText: String?
    var footerTitle: String
    private let content: Content

    init(
        theme: AppTheme,
        icon: String? = nil,
        title: String? = nil,
        subtitle: String? = nil,
        helperText: String? = nil,
        footerTitle: String,
        @ViewBuilder content: () -> Content
    ) {
        self.theme = theme
        self.icon = icon
        self.title = title
        self.subtitle = subtitle
        self.helperText = helperText
        self.footerTitle = footerTitle
        self.content = content()
    }

    var body: some View {
        DynamicBoxContent(theme: theme, footerTitle: footerTitle) {
            VStack(spacing: 0) {
                if let icon {
                    Image(systemName: icon)
                        .font(.largeTitle.weight(.semibold))
                        .foregroundStyle(theme.gradientSoft)
                        
                        .padding(.bottom, 10)
                        .fontWidth(.expanded)
                }

                if let title {
                    Text(title)
                        .font(.title2.weight(.semibold))
                        .multilineTextAlignment(.center)
                        .foregroundStyle(theme.gradientSoft)
                        .fontWidth(.expanded)
                        .padding(.bottom, 4)
                }

                if let subtitle {
                    Text(subtitle)
                        .font(.caption)
                        .foregroundStyle(Color(uiColor: .tertiarySystemBackground).opacity(0.7))
                        .padding(.bottom, 48)
                }
            }
            .padding(.top, 80)

            content
            
            Spacer()

            if let helperText {
                Text(helperText)
                    .font(.caption)
                    .foregroundStyle(Color(uiColor: .tertiarySystemBackground).opacity(0.5))
                    .padding(.bottom, 18)
            }
        }
    }
}

struct DynamicBoxContent<Content: View>: View {
    var theme: AppTheme
    var footerTitle: String
    private let content: Content
    @State private var isContentVisible = false

    init(theme: AppTheme, footerTitle: String, @ViewBuilder content: () -> Content) {
        self.theme = theme
        self.footerTitle = footerTitle
        self.content = content()
    }

    var body: some View {
        ZStack {
            VStack(spacing: 0) {
                ZStack {
                    VStack(spacing: 0) {
                        content
                    }
                    .opacity(isContentVisible ? 1 : 0)
                    .offset(y: isContentVisible ? 0 : 14)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
                    .background(GridGradientBackground(color: theme.boxColor))
                    .clipShape(RoundedRectangle(cornerRadius: 55, style: .continuous))
                    .foregroundStyle(.white)
                    .shadow(color: .black.opacity(0.25), radius: 14, y: 8)
                    .padding(.top, 4)
                    .padding(.horizontal, 4)
                }
                .frame(maxHeight: .infinity, alignment: .top)

                Text(footerTitle)
                    .fontWidth(.expanded)
                    .foregroundStyle(.white)
                    .font(.subheadline.weight(.semibold))
                    .padding(5)
            }
            .frame(maxHeight: .infinity)
            .background(theme.gradientSoft)
            .clipShape(RoundedRectangle(cornerRadius: 56, style: .continuous))
            .onAppear {
                isContentVisible = false

                DispatchQueue.main.asyncAfter(deadline: .now() + 0.42) {
                    withAnimation(.spring(response: 0.42, dampingFraction: 0.86)) {
                        isContentVisible = true
                    }
                }
            }
        }
        .padding(10)
    }
}

struct GridGradientBackground: View {
    var color: Color = Theme.primaryBox
    var body: some View {
        ZStack {
            LinearGradient(
                colors: [.black, color],
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
        .clipShape(RoundedRectangle(cornerRadius: 54, style: .continuous))
    }
}

struct PlusPattern: View {
    let spacing: CGFloat = 30
    let lineLength: CGFloat = 12
    let lineWidth: CGFloat = 2
    let color: Color = .black.opacity(0.2)
    
    var body: some View {
        Canvas { context, size in
            let columns = Int(size.width / spacing) + 1
            let rows = Int(size.height / spacing) + 1
            
            var path = Path()
            
            for row in 0..<rows {
                for col in 0..<columns {
                    let center = CGPoint(
                        x: CGFloat(col) * spacing,
                        y: CGFloat(row) * spacing
                    )
                    
                    path.move(to: CGPoint(x: center.x - lineLength/2, y: center.y))
                    path.addLine(to: CGPoint(x: center.x + lineLength/2, y: center.y))
                    
                    path.move(to: CGPoint(x: center.x, y: center.y - lineLength/2))
                    path.addLine(to: CGPoint(x: center.x, y: center.y + lineLength/2))
                }
            }
            
            context.stroke(path, with: .color(color), lineWidth: lineWidth)
        }
    }
}

#Preview {
        ZStack(alignment: .top) {
            Color.white
                .ignoresSafeArea()
            
            VStack {
                VStack {
                    DynamicBox(
                        theme: Theme.themePrimary,
                        icon: "motorcycle",
                        title: "Text will go here",
                        subtitle: "What should we call this adventure?",
                        helperText: "Hello, World!",
                        footerTitle: "Creating a trip"
                    ) {
                        
                    }
                }
            }
        }
//        .statusBarHidden(true)
        .ignoresSafeArea(edges: .top)
    
}
