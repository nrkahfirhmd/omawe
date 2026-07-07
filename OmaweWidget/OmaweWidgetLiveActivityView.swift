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
            value: context.state.etaMinutes,
            to: Date()
        ) ?? Date()
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: eta)
    }
    
    /// Format distance nicely
    private var distanceString: String {
        let km = context.state.distanceKm
        if km >= 1 {
            return "\(Int(km))km"
        } else {
            return "\(Int(km * 1000))m"
        }
    }
    
    var body: some View {
        VStack() {
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
//            .padding(.horizontal,10)
            
            // ── Route Progress with Mate Markers ──
            RouteProgressView(
                totalMates: context.attributes.totalMates,
                arrivedCount: context.state.arrivedCount
            )
//            .padding(.horizontal,10)
//            .padding(.vertical, 2)
            
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
    let totalMates: Int
    let arrivedCount: Int
    
    /// User's current position along the route (0.0 → 1.0)
    private let userProgress: CGFloat = 0.10
    
    /// Build marker data: positions + labels + cluster flag
    private var markers: [(position: CGFloat, label: String, isCluster: Bool)] {
        let startPos: CGFloat = 0.25
        let endPos: CGFloat = 0.75
        
        guard totalMates > 0 else { return [] }
        
        if totalMates <= 4 {
            // Show each mate individually
            let spacing = totalMates == 1
                ? 0.0
                : (endPos - startPos) / CGFloat(totalMates - 1)
            return (0..<totalMates).map { i in
                (startPos + spacing * CGFloat(i), "L", false)
            }
        } else {
            // Show 2 individual markers + 1 cluster
            let clusterExtra = totalMates - 2  // number of extra mates in cluster
            return [
                (0.25, "L", false),
                (0.50, "L+\(clusterExtra)", true),
                (0.75, "L", false)
            ]
        }
    }
    
    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let midY = geo.size.height / 2
            
            // ── Route line (linear gradient: 0 → full white → 0) ──
            Capsule()
                .fill(
                    LinearGradient(
                        stops: [
                            .init(color: .white.opacity(0), location: 0),
                            .init(color: .white.opacity(0.9), location: 0.5),
                            .init(color: .white.opacity(0), location: 1.0)
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .frame(width: w - 12, height: 5)
                .position(x: w / 2, y: midY)
            
            // ── Start icon ──
            Image(systemName: "location.fill")
                .font(.system(size: 20, weight: .semibold))
                .foregroundStyle(LinearGradient(
                    stops: [
                        .init(color: .white.opacity(0), location: 0),
                        .init(color: .white.opacity(0.9), location: 1)
                    ],
                    startPoint: .bottom,
                    endPoint: .top
                ))
                .position(x: 4, y: midY)
            
            // ── Finish icon ──
            Image(systemName: "flag.fill")
                .font(.system(size: 20, weight: .semibold))
                .foregroundStyle(LinearGradient(
                    stops: [
                        .init(color: .white.opacity(0), location: 0),
                        .init(color: .white.opacity(0.9), location: 1)
                    ],
                    startPoint: .bottom,
                    endPoint: .top
                ))                .position(x: w - 8, y: midY)
            
            // ── Mate markers ──
            ForEach(Array(markers.enumerated()), id: \.offset) { _, marker in
                MateMarkerView(
                    label: marker.label,
                    isCluster: marker.isCluster
                )
                .position(x: w * marker.position, y: midY)
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
    let isCluster: Bool
    
    private var bgColor: Color {
        isCluster ? LATheme.amber : LATheme.green
    }
    
    /// Extract just the letter part (e.g. "B" from "B+3")
    private var letterPart: String {
        if let plusIndex = label.firstIndex(of: "+") {
            return String(label[label.startIndex..<plusIndex])
        }
        return label
    }
    
    /// Extract the "+N" part (e.g. "+3" from "B+3")
    private var clusterPart: String {
        if let plusIndex = label.firstIndex(of: "+") {
            return String(label[plusIndex...])
        }
        return ""
    }
    
    var body: some View {
        if isCluster {
            // Cluster: green capsule with letter + "+N" text beside it
            HStack(spacing: 2) {
                Text(letterPart)
                    .font(.system(size: 10, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 6)
                    .frame(minWidth: 23, minHeight: 28)
                    .background(LATheme.green)
                    .clipShape(Capsule())
                    .overlay(
                        Capsule()
                            .strokeBorder(.white.opacity(0.2), lineWidth: 4)
                            .padding(-4)
                    )
                
                Text(clusterPart)
                    .font(.system(size: 9, weight: .bold, design: .rounded))
                    .foregroundStyle(.black)
                    .frame(width: 22, height: 22)
                    .background(Color.white)
                    .clipShape(Circle())
            }
        } else {
            // Individual: single capsule with letter
            Text(label)
                .font(.system(size: 10, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
                .padding(.horizontal, 6)
                .frame(minWidth: 23, minHeight: 28)
                .background(bgColor)
                .clipShape(Capsule())
                .overlay(
                    Capsule()
                        .strokeBorder(.white.opacity(0.2), lineWidth: 4)
                        .padding(-4)
                )
        }
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
        etaMinutes: 12,
        arrivedCount: 2,
        distanceKm: 15.0
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
        etaMinutes: 15,
        arrivedCount: 4,
        distanceKm: 2.5
    )
}
