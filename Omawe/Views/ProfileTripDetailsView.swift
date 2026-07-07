//
//  ProfileTripDetailsView.swift
//  Omawe
//
//  Created by Syed Israruddin on 06/07/26.
//


import SwiftUI

struct ProfileTripDetailsView: View {
    @Environment(\.dismiss) private var dismiss
    
    let trip: TripModel
    
    var body: some View {
        NavigationStack{
            ZStack {
            
                Image(.tripDetailsSheetBG)
                    .resizable()
                    .scaledToFill()
                    .ignoresSafeArea()
                
                VStack {
                    tripDateCapsule
                        .padding(.top, 40)
                    
                    Text(trip.name)
                        .font(.title1())
                        .fontWidth(.expanded)
                        .multilineTextAlignment(.center)
                        .foregroundStyle(.primary)
                        .padding(.horizontal, 24)
                        .padding(.top, 40)
                    
                    Text("by @\(trip.ownerUserID)")
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
                    
                    Text("Event Date")
                        .font(.headline())
                        .padding(.top, 40)
                        .foregroundStyle(.gray)
                    Text(formattedTripDate)
                        .font(.title3())
                        .fontWidth(.expanded)
                        

                        //.padding(.top, 5)

                    Text("Meet Time")
                        .font(.headline())
                        .padding(.top, 40)
                        .foregroundStyle(.gray)
                    Text(formattedMeetTime)
                        .font(.title3())
                        .fontWidth(.expanded)
                    
                    Text("Location")
                        .font(.headline())
                        .padding(.top, 110)
                        .foregroundStyle(.gray)
                    Text(trip.locationName)
                        .font(.title3())
                        .fontWidth(.expanded)
                        .foregroundStyle(.white)
                        .lineLimit(2)
                        .frame(maxWidth: 270)
                        .multilineTextAlignment(.center)
                        .padding(.bottom, 3)
                    Text(trip.locationAddress ?? "")
                        .font(.caption2)
                        .foregroundStyle(.white)
                        .lineLimit(2)
                        .frame(maxWidth: 270)
                        .multilineTextAlignment(.center)
                    
                    locationNoteCapsule
                        .padding(.top, 20)
                    
                    HStack {
                        Text("#Code")
                            .font(.button())
                            .fontWidth(.expanded)
                            .foregroundStyle(.white)
                            
                        Spacer()
                        Text(trip.invitationCode ?? "")
                            .font(.button())
                            .fontWidth(.expanded)
                            .foregroundStyle(.white)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
                    
                    Spacer()
                }
                
                

                
                
                
            }
        }
    }
    
    private var tripDateCapsule: some View {
        Text("The trip took place on \(formattedTripDate)")
            .font(.subheadline)
            .foregroundStyle(.secondary)
            .padding(.horizontal, 18)
            .frame(height: 36)
            .background(.black.opacity(0.05))
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
        Text(trip.locationNote ?? "No note provided.")
            .font(.subheadline)
            .foregroundStyle(.white)
            .padding(.horizontal, 18)
            .frame(height: 36)
            .frame(maxWidth: 250)
            .background(.white.opacity(0.25))
            .clipShape(Capsule())
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



#Preview("Trip details") {
    NavigationStack {
        ProfileTripDetailsView(
            trip: TripModel(
                name: "Kuta Sunset Surf and Chill",
                startDate: Calendar.current.date(
                    from: DateComponents(year: 2026, month: 6, day: 30)
                ) ?? .now,
                meetTime: Calendar.current.date(
                    from: DateComponents(hour: 17, minute: 0)
                ) ?? .now,
                locationName: "Toko Kopi Jaya, Kuta",
                locationAddress: "Jl. Dewi Sri No. 99X, Legian, Kec. Kuta, Kabupaten Badung, Bali 80361",
                locationNote: "Luat's House • Room 222",
                locationDisplayName: "Toko Kopi Jaya, Kuta",
                ownerUserID: "Bintang",
                memberIdentifiers: [
                    "user-1",
                    "user-2",
                    "user-3",
                    "user-4",
                    "user-5",
                    "user-6"
                ],
                invitationCode: "1A6B7K"
            )
        )
    }
}
