//
//  PreviewTicketContent.swift
//  Omawe
//
//  Created by Antigravity on 09/07/26.
//

import SwiftUI
import CloudKit

struct PreviewTicketContent: View {
    let trip: Trip
    let participants: [Participant]
    var bottomRatio: CGFloat = 0.48
    
    private let colors: [Color] = [
        Color(hex: "FFB3BA"), // Pastel Pink
        Color(hex: "BAFFC9"), // Pastel Green
        Color(hex: "BAE1FF"), // Pastel Blue
        Color(hex: "FFFFBA"), // Pastel Yellow
        Color(hex: "FFDFBA")  // Pastel Orange
    ]
    
    private var displayTripName: String {
        trip.title.isEmpty ? "Trip Name" : trip.title
    }
    
    private var displayLocationName: String {
        trip.destination.isEmpty ? "No location selected" : trip.destination
    }
    
    var body: some View {
        GeometryReader { geo in
            let totalHeight = geo.size.height
            let topHeight = totalHeight * (1.0 - bottomRatio)
            let bottomHeight = totalHeight * bottomRatio
            
            VStack(spacing: 0) {
                // Top Section (Title, Owner, Participants, Event details)
                VStack(spacing: 0) {
                    VStack {
                        Text(displayTripName)
                            .font(.title1().weight(.semibold))
                            .fontWidth(.expanded)
                            .foregroundStyle(Color(red: 0.0, green: 0.19, blue: 0.22))
                            .multilineTextAlignment(.center)
                            .lineLimit(2)
                            .padding(.bottom, 4)
                        
                        Text("by @\(trip.ownerDisplayName ?? "Anonymous")")
                            .font(.caption1())
                            .foregroundStyle(Theme.primaryBox.opacity(0.72))
                            .padding(.bottom, 12)
                        
                        if !participants.isEmpty {
                            HStack(spacing: -12) {
                                ForEach(Array(participants.prefix(3).enumerated()), id: \.element.id) { index, participant in
                                    let name = participant.displayName ?? ""
                                    let initials = String(name.trimmingCharacters(in: .whitespacesAndNewlines).first ?? "?").uppercased()
                                    
                                    Group {
                                        if let avatarData = participant.avatarImageData, let uiImage = UIImage(data: avatarData) {
                                            Image(uiImage: uiImage)
                                                .resizable()
                                                .scaledToFill()
                                                .frame(width: 38, height: 38)
                                                .clipShape(Circle())
                                                .overlay {
                                                    Circle()
                                                        .stroke(.black, lineWidth: 3)
                                                }
                                        } else {
                                            Text(initials)
                                                .font(.system(size: 16, weight: .bold))
                                                .foregroundStyle(.black.opacity(0.8))
                                                .frame(width: 38, height: 38)
                                                .background(colors[index % colors.count], in: Circle())
                                                .overlay {
                                                    Circle()
                                                        .stroke(.black, lineWidth: 3)
                                                }
                                        }
                                    }
                                }
                                
                                if participants.count > 3 {
                                    Text("+\(participants.count - 3)")
                                        .font(.title3().weight(.semibold))
                                        .foregroundStyle(Theme.primaryBox.opacity(0.72))
                                        .padding(.leading, 8)
                                }
                            }
                            .padding(.bottom, 12)
                        }
                    }
                    .padding(.bottom, 24)
                    
                    VStack(spacing: 18) {
                        ticketDetail(
                            label: "Event Date",
                            value: trip.startDate.formatted(.dateTime.weekday(.wide).day().month(.wide)),
                            isDark: false
                        )
                        
                        ticketDetail(
                            label: "Meet Time",
                            value: trip.startDate.formatted(date: .omitted, time: .shortened),
                            isDark: false
                        )
                    }
                    
                    Spacer(minLength: 0)
                }
                .frame(height: topHeight)
                
                // Bottom Section (Location details, Code footer)
                VStack(spacing: 0) {
                    Spacer(minLength: 0)
                    
                    VStack {
                        Text("Location")
                            .font(.headline())
                            .foregroundStyle(.white.opacity(0.48))
                            .padding(.bottom, 4)
                        
                        VStack(spacing: 4) {
                            Text(displayLocationName)
                                .font(.title3())
                                .fontWidth(.expanded)
                                .foregroundStyle(.white)
                                .multilineTextAlignment(.center)
                                .lineLimit(2)
                            
                            if let locationAddress = trip.locationAddress, !locationAddress.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                                Text(locationAddress)
                                    .font(.caption2())
                                    .foregroundStyle(.white.opacity(0.86))
                                    .multilineTextAlignment(.center)
                                    .lineSpacing(3)
                                    .lineLimit(3)
                            }
                        }
                        .padding(.bottom, 12)
                        
                        let unit = (trip.apartmentUnitFloor ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
                        let nickname = (trip.locationNickname ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
                        
                        if !unit.isEmpty || !nickname.isEmpty {
                            TripLocationNotePill(
                                apartmentUnitFloor: unit,
                                locationNickname: nickname
                            )
                        }
                    }
                    
                    Spacer(minLength: 0)
                    
                    HStack {
                        Text("#Code")
                            .font(.button().width(.expanded))
                            .foregroundStyle(.white.opacity(0.28))
                        
                        Spacer()
                        
                        Text(trip.invitationCode)
                            .font(.button().width(.expanded))
                            .foregroundStyle(.white)
                    }
                }
                .frame(height: bottomHeight)
            }
        }
        .frame(maxWidth: 320, maxHeight: .infinity, alignment: .top)
        .padding(24)
    }
    
    private func ticketDetail(label: String, value: String, isDark: Bool) -> some View {
        VStack(spacing: 4) {
            Text(label)
                .font(.headline())
                .foregroundStyle(isDark ? .white.opacity(0.46) : .black.opacity(0.46))
            
            Text(value)
                .font(.title3().weight(.semibold))
                .fontWidth(.expanded)
                .foregroundStyle(isDark ? .white.opacity(0.9) : .black.opacity(0.9))
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .minimumScaleFactor(0.65)
        }
    }
}
