//
//  OmaweWidgetLiveActivityView.swift
//  OmaweWidgetExtension
//
//  Created by Muhammad Bintang Al-Fath on 07/07/26.
//

import SwiftUI
import ActivityKit
import WidgetKit

// MARK: - Theme Colors
private enum LATheme {
    static let teal = Color(red: 0.01, green: 0.78, blue: 0.70)
    static let orange = Color(red: 1.0, green: 0.62, blue: 0.04)
    static let green = Color(red: 0.20, green: 0.78, blue: 0.35)
    static let amber = Color(red: 0.92, green: 0.68, blue: 0.12)
    static let bgDark = Color(white: 0.05)
    static let subtleWhite = Color.white.opacity(0.45)
}

// MARK: - Live Activity Lock Screen View
struct LiveActivityLockScreenView: View {
    let context: ActivityViewContext<OmaweWidgetAttributes>
    
    /// Compute ETA as a formatted clock time string (e.g. "11:00")
    private var etaTimeString: String {
        let eta = Calendar.current.date(
            byAdding: .minute,
            value: context.state.myEtaMinutes,
            to: Date()
        ) ?? Date()
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: eta)
    }
    
    /// Format distance nicely
    private var distanceString: String {
        let km = context.state.myDistanceKm
        if km >= 1 {
            return "\(Int(km))km"
        } else {
            return "\(Int(km * 1000))m"
        }
    }
    
    var body: some View {
//            .padding(.horizontal,10)
            
            // ── Route Progress with Mate Markers ──
        VStack() {
            ZStack{
                PolkaDotBackground(
                    dotSize: 3,
                    spacing: 10,
                    color: LATheme.teal.opacity(1)
                )
                .mask {
                    Ellipse()
                        
                        .padding(.horizontal, 30)
                        .blur(radius: 40)
                        .scaleEffect(x: 1, y: 0.4)
                        
                }
                .padding(.top, 45)
                .frame(width: .infinity, height: 100)
                
                VStack{
                    // ── Top Row: ETA & Distance ──
                    HStack(alignment: .top) {
                        // ETA (left)
                        VStack(alignment: .leading) {
                            Text("ETA")
                                .font(.caption2)
                                .opacity(0.8)
                                .bold()
                                .foregroundStyle(.gray)
                            Text(etaTimeString)
                                .font(.subheadline)
                                .fontWidth(.expanded)
                                .fontWeight(.semibold)
                                .foregroundStyle(.yellow)
                        }
                        
                        Spacer()
                        
                        // Distance (right)
                        VStack(alignment: .leading, spacing: 1) {
                            Text("Distance")
                                .font(.caption2)
                                .bold()
                                .opacity(0.8)
                                .foregroundStyle(.gray)
                            Text(distanceString)
                                .font(.subheadline)
                                .fontWidth(.expanded)
                                .fontWeight(.semibold)
                                .foregroundStyle(.yellow)
                        }
                    }
                    .padding(.top,20)
                    
                    RouteProgressView(
                        mates: context.state.mates
                    )
                    
                }
            }
//            .padding(.horizontal,10)
//            .padding(.vertical, 10)
            
            // ── Bottom Row: Alert Icon + Report Button ──
            HStack(spacing: 10) {
                // Alert / Warning icon
                ZStack {
                    Circle()
                        .fill(Color.red)
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.subheadline)
                        .foregroundStyle(.white)
                }
                .frame(width: 44, height: 44)
                
                // Report button
                Link(destination: URL(string: "omawe://report")!) {
                    HStack(spacing: 7) {
                        Image(systemName: "bubble.left.and.exclamationmark.bubble.right.fill")
                            .font(.subheadline)
                            .foregroundStyle(.white)
                        Text("Report")
                            .font(.subheadline)
                            .fontWeight(.bold)
                            .fontWidth(.expanded)
                            .foregroundStyle(.white)
                    }
                    .foregroundStyle(.black)
                    .frame(maxWidth: .infinity)
                    .frame(height: 44)
                    .background(.orange)
                    .clipShape(RoundedRectangle(cornerRadius: 23, style: .continuous))
                }
            }
        }
        .padding(.horizontal,14)
//        .padding(.top,10)
        .padding(.bottom,14)
        .background(
            ZStack {
                LATheme.bgDark
                // Subtle warm glow at bottom-right
                RadialGradient(
                    colors: [
                        LATheme.orange.opacity(0.06),
                        Color.clear
                    ],
                    center: .bottomTrailing,
                    startRadius: 10,
                    endRadius: 200
                )
            }
        )
    }
}

// MARK: - Route Progress View
/// Displays a dashed route line with an orange arrow for the user's
/// current position and green/amber markers for each mate along the route.
struct RouteProgressView: View {
    let mates: [OmaweWidgetAttributes.MateProgress]
    
    private var markers: [(position: CGFloat, label: String, isMe: Bool, distanceKm: Double, isLate: Bool)] {
        // Sort by progress from lowest (left) to highest (right)
        let sorted = mates.sorted { $0.progress < $1.progress }
        
        var placed: [(position: CGFloat, label: String, isMe: Bool, distanceKm: Double, isLate: Bool)] = []
        
        for mate in sorted {
            var pos = CGFloat(mate.progress)
            let clampedPos = max(0.05, min(0.95, pos))
            pos = clampedPos
            
            // Shift slightly if there is a collision
            var shiftCount = 0
            while placed.contains(where: { abs($0.position - pos) < 0.07 }) && shiftCount < 5 {
                pos += 0.07
                if pos > 0.95 { 
                    pos = clampedPos - (0.07 * CGFloat(shiftCount + 1)) 
                }
                shiftCount += 1
            }
            
            placed.append((pos, mate.label, mate.isMe, mate.distanceKm, mate.isLate))
        }
        return placed
    }
    
    private func curveY(t: CGFloat, midY: CGFloat) -> CGFloat {
        let controlY = midY - 24
        let mt = 1 - t
        return (mt * mt * midY) + (2 * mt * t * controlY) + (t * t * midY)
    }
    
    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let midY = geo.size.height / 2
            
            // ── Route line (Curved) ──
            Path { path in
                path.move(to: CGPoint(x: 0, y: midY))
                path.addQuadCurve(
                    to: CGPoint(x: w, y: midY),
                    control: CGPoint(x: w / 2, y: midY - 24)
                )
            }
            .stroke(
                LinearGradient(
                    stops: [
                        .init(color: .white.opacity(0), location: 0),
                        .init(color: .white.opacity(0.9), location: 0.5),
                        .init(color: .white.opacity(0), location: 1.0)
                    ],
                    startPoint: .leading,
                    endPoint: .trailing
                ),
                style: StrokeStyle(lineWidth: 4, lineCap: .round)
            )
            .shadow(color: .black.opacity(0.8), radius: 3, x: 0, y: 3)
            
            // ── Start icon ──
            Image(systemName: "location.fill")
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(LinearGradient(
                    stops: [
                        .init(color: .white.opacity(0.3), location: 0),
                        .init(color: .white.opacity(0.9), location: 1)
                    ],
                    startPoint: .leading,
                    endPoint: .trailing
                ))
                .rotationEffect(.degrees(45))
                .position(x: w * 0.05, y: curveY(t: 0.05, midY: midY))
            
            // ── Finish icon ──
            Image(systemName: "flag.fill")
                .font(.system(size: 20, weight: .semibold))
                .foregroundStyle(LinearGradient(
                    stops: [
                        .init(color: .white.opacity(0.4), location: 0),
                        .init(color: .white.opacity(0.9), location: 1)
                    ],
                    startPoint: .bottom,
                    endPoint: .top
                ))
                .position(x: w * 0.95, y: curveY(t: 0.95, midY: midY))
            
            // ── Mate markers ──
            ForEach(Array(markers.enumerated()), id: \.offset) { _, marker in
                MateMarkerView(
                    label: marker.label,
                    isMe: marker.isMe,
                    distanceKm: marker.distanceKm,
                    isLate: marker.isLate
                )
                .position(
                    x: w * marker.position,
                    y: curveY(t: marker.position, midY: midY)
                )
            }
        }
        .frame(height: 30)
    }
}

// MARK: - Mate Marker View
/// A circular (or capsule-shaped for clusters) badge showing a mate's
/// initial letter, or "L+N" for clustered mates.
struct MateMarkerView: View {
    let label: String
    let isMe: Bool
    let distanceKm: Double
    let isLate: Bool
    
    private var bgColor: Color {
        if isLate {
            return .yellow
        }
        // Green if arrived or very close (<= 0.5km), otherwise native Orange (on the way)
        return distanceKm <= 0.5 ? LATheme.green : Color.orange
    }
    
    @ViewBuilder
    private var markerView: some View {
        if isMe {
            ZStack {
                Circle()
                    .fill(bgColor)
                    .overlay(Circle().strokeBorder(.white, lineWidth: 2.5))
                    .frame(width: 32, height: 32)
                
                Image(systemName: "location.north.fill")
                    .font(.caption)
                    .bold()
                    .foregroundStyle(.white)
                    .rotationEffect(.degrees(90))
            }
        } else {
            Text(label)
                .font(.system(size: 10, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
                .padding(.horizontal, 6)
                .frame(minWidth: 23, minHeight: 28)
                .background(bgColor)
                .clipShape(Capsule())
        }
    }
    
    var body: some View {
        markerView
    }
}

struct PolkaDotBackground: View {
    var dotSize: CGFloat = 3
    var spacing: CGFloat = 12
    var color: Color = .white.opacity(0.15)

    var body: some View {
        Canvas { context, size in
            for x in stride(from: 0, through: size.width, by: spacing) {
                for y in stride(from: 0, through: size.height, by: spacing) {
                    let rect = CGRect(
                        x: x,
                        y: y,
                        width: dotSize,
                        height: dotSize
                    )

                    context.fill(
                        Circle().path(in: rect),
                        with: .color(color)
                    )
                }
            }
        }
        .allowsHitTesting(false)
    }
}

// MARK: - Previews
#Preview("Lock Screen - On The Way", as: .content, using: OmaweWidgetAttributes(
    tripName: "Ex-Boyfriends Celebration!",
    destinationName: "Toko Kopi Jaya, Kuta",
    totalMates: 6
)) {
    OmaweWidgetLiveActivity()
} contentStates: {
    OmaweWidgetAttributes.ContentState(
        statusMessage: "Bintang is 5 mins away",
        myEtaMinutes: 12,
        myDistanceKm: 15.0,
        arrivedCount: 2,
        mates: [
            OmaweWidgetAttributes.MateProgress(label: "B", distanceKm: 15.0, progress: 0.25, isMe: false),
            OmaweWidgetAttributes.MateProgress(label: "G", distanceKm: 10.0, progress: 0.5, isMe: true)
        ],
        trackScaleKm: 20.0
    )
}

#Preview("Lock Screen - Almost There", as: .content, using: OmaweWidgetAttributes(
    tripName: "Ex-Boyfriends Celebration!",
    destinationName: "Toko Kopi Jaya, Kuta",
    totalMates: 6
)) {
    OmaweWidgetLiveActivity()
} contentStates: {
    OmaweWidgetAttributes.ContentState(
        statusMessage: "Kahfi is arriving now!",
        myEtaMinutes: 2,
        myDistanceKm: 2.5,
        arrivedCount: 4,
        mates: [
            OmaweWidgetAttributes.MateProgress(label: "K", distanceKm: 0.5, progress: 0.95, isMe: false),
            OmaweWidgetAttributes.MateProgress(label: "G", distanceKm: 2.5, progress: 0.75, isMe: true)
        ],
        trackScaleKm: 10.0
    )
}

#Preview("Lock Screen - 6 Mates (Clustered)", as: .content, using: OmaweWidgetAttributes(
    tripName: "Bali Road Trip",
    destinationName: "Uluwatu Temple",
    totalMates: 6
)) {
    OmaweWidgetLiveActivity()
} contentStates: {
    OmaweWidgetAttributes.ContentState(
        statusMessage: "Everyone is on the move",
        myEtaMinutes: 20,
        myDistanceKm: 10.0,
        arrivedCount: 0,
        mates: [
            // Max distance = 15.0 (0.0 on curve)
            OmaweWidgetAttributes.MateProgress(label: "B", distanceKm: 15.0, progress: 0.0, isMe: false),
            // Close to B, should cluster
            OmaweWidgetAttributes.MateProgress(label: "K", distanceKm: 14.8, progress: 0.02, isMe: false),
            // Middle
            OmaweWidgetAttributes.MateProgress(label: "G", distanceKm: 10.0, progress: 0.33, isMe: true),
            // Close to G, should cluster with G
            OmaweWidgetAttributes.MateProgress(label: "A", distanceKm: 9, progress: 0.4, isMe: false),
            // Arrived / Very Close (Green)
            OmaweWidgetAttributes.MateProgress(label: "C", distanceKm: 0.2, progress: 0.98, isMe: false),
            OmaweWidgetAttributes.MateProgress(label: "D", distanceKm: 0.1, progress: 0.99, isMe: false)
        ],
        trackScaleKm: 15.0
    )
}

