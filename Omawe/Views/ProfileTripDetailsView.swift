//
//  ProfileTripDetailsView.swift
//  Omawe
//
//  Created by Syed Israruddin on 06/07/26.
//


import SwiftUI

struct ProfileTripDetailsView: View {
    @Environment(\.dismiss) private var dismiss
    
    let trip: PlaceholderTrip
    
    var body: some View {
        NavigationStack{
            ZStack {
            
                Image(backgroundImage)
                    .resizable()
                    .scaledToFill()
                    .ignoresSafeArea()
                
                VStack {
                    tripDateCapsule
                        .padding(.top, 60)
                    
                    Text(trip.name)
                        .font(.title1())
                        .fontWidth(.expanded)
                        .multilineTextAlignment(.center)
                        .foregroundStyle(.primary)
                        .lineLimit(2)
                        .frame(height: 68, alignment: .center)
                        .padding(.horizontal, 24)
                        .padding(.top, 40)
                    
                    Text("by @\(trip.ownerUsername)")
                        .font(.caption1())
                        .padding(.top, 5)
                    
                    ParticipantAvatarsView(
                        avatars: [
                            .avatar,
                            .avatar,
                            .avatar,
                            .avatar,
                            .avatar
                        ]
                    )
                    .padding(.top, 5)
                    
                    //Spacer()
                    
                    VStack(spacing: 28) {

                        VStack(spacing: 8) {
                            Text("Event Date")
                                .font(.headline())
                                .foregroundStyle(.gray)

                            Text(formattedTripDate)
                                .font(.title3())
                                .fontWidth(.expanded)
                        }

                        VStack(spacing: 8) {
                            Text("Meet Time")
                                .font(.headline())
                                .foregroundStyle(.gray)

                            Text(formattedMeetTime)
                                .font(.title3())
                                .fontWidth(.expanded)
                        }
                    }
                    .padding(.top, 40)
                    
                    VStack(spacing: 6) {

                        Text("Location")
                            .font(.headline())
                            .foregroundStyle(.gray)

                        Text(trip.locationName)
                            .font(.title3())
                            .fontWidth(.expanded)
                            .foregroundStyle(.white)
                            .multilineTextAlignment(.center)

                        Text(trip.locationAddress)
                            .font(.caption2())
                            .foregroundStyle(.white)
                            .multilineTextAlignment(.center)
                            .frame(maxWidth: 270)

                        locationNoteCapsule
                            .padding(.top, 14)
                    }
                    .padding(.top, 80)
                    
                    HStack {
                        Text("#Code")
                            .font(.button())
                            .fontWidth(.expanded)
                            .foregroundStyle(.white)
                            
                        Spacer()
                        Text(trip.invitationCode)
                            .font(.button())
                            .fontWidth(.expanded)
                            .foregroundStyle(.white)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 10)
                    .padding(.bottom, 40)
                    
                    //Spacer()
                }
                
                

                
                
                
            }
        }
    }
    
    private var tripDateCapsule: some View {
        Text(tripDateCapsuleText)
            .font(.subheadline)
            .foregroundStyle(tripDateCapsuleTextColor)
            .padding(.horizontal, 18)
            .frame(height: 36)
            .background(tripDateCapsuleBackground)
            .clipShape(Capsule())
    }
    
    private var formattedTripDate: String {
        trip.startDate.formatted(
            .dateTime
                .weekday(.wide)
                .day()
                .month(.wide)
                .year()
        )
    }
    
    private var formattedMeetTime: String {
        trip.meetTime.formatted(
            .dateTime
                .hour(.twoDigits(amPM: .omitted))
                .minute(.twoDigits)
        )
    }
    
    private var locationNoteCapsule: some View {
        Text(trip.locationNote)
            .font(.subheadline)
            .foregroundStyle(.white)
            .padding(.horizontal, 18)
            .frame(height: 36)
            .frame(maxWidth: 250)
            .background(.white.opacity(0.25))
            .clipShape(Capsule())
    }
    
    // DATE CAPSULE LOGIC
    private var hasTripPassed: Bool {
        trip.startDate < Calendar.current.startOfDay(for: .now)
    }

    private var tripDateCapsuleText: String {
        if hasTripPassed {
            return "This trip took place on \(formattedTripDate)"
        } else {
            return "This trip is scheduled for \(formattedTripDate)"
        }
    }

    private var tripDateCapsuleBackground: Color {
        hasTripPassed
        ? .black.opacity(0.05)
        : .green
    }

    private var tripDateCapsuleTextColor: Color {
        hasTripPassed
        ? .secondary
        : .white
    }
    // DATE CAPSULE LOGIC END
    
    // IMAGE CHANGE LOGIC
    private var backgroundImage: ImageResource {
        hasTripPassed ? .tripDetailsSheetBG : .upcomingTripDetailsSheetBG
    }
}

struct ParticipantAvatarsView: View {
    let avatars: [ImageResource]

    private let avatarSize: CGFloat = 38
    private let overlap: CGFloat = 12

    var body: some View {
        HStack(spacing: -overlap) {
            ForEach(Array(avatars.prefix(3).enumerated()), id: \.offset) { _, avatar in
                Image(avatar)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 30, height: avatarSize)
                    .clipShape(Circle())
                    .overlay {
                        Circle()
                            .stroke(.black, lineWidth: 2)
                    }
            }

            if avatars.count > 3 {
                Text("+\(avatars.count - 3)")
                    .font(.caption1())
                    .fontWeight(.semibold)
                    .foregroundStyle(.secondary)
                    .padding(.leading, 15)
            }
        }
    }
}

struct TripParticipant: Identifiable {
    let id = UUID()
    let name: String
    let avatar: ImageResource
}



#Preview {
    NavigationStack {
        ProfileTripDetailsView(
            trip: .samples.first!
        )
    }
}
