//
//  ProfileTripDetailsView.swift
//  Omawe
//
//  Created by Syed Israruddin on 06/07/26.
//


import SwiftUI
import CloudKit

struct ProfileTripDetailsView: View {
    @Environment(\.dismiss) private var dismiss

    let trip: Trip
    
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
                    
                    Text(trip.title)
                        .font(.title1())
                        .fontWidth(.expanded)
                        .multilineTextAlignment(.center)
                        .foregroundStyle(.primary)
                        .lineLimit(2)
                        .frame(height: 68, alignment: .center)
                        .padding(.horizontal, 24)
                        .padding(.top, 40)

                    Text("by @\(trip.ownerID.recordName)")
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

                    Text("Location")
                        .font(.headline())
                        .padding(.top, 110)
                        .foregroundStyle(.gray)
                    Text(trip.destination)
                        .font(.title3())
                        .fontWidth(.expanded)
                        .foregroundStyle(.white)
                        .lineLimit(2)
                        .frame(maxWidth: 270)
                        .multilineTextAlignment(.center)
                        .padding(.bottom, 3)

                    locationNoteCapsule
                        .padding(.top, 20)

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
    
    private var locationNoteCapsule: some View {
        Text("No note provided.")
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
            trip: Trip(
                id: nil,
                title: "Kuta Sunset Surf and Chill",
                destination: "Toko Kopi Jaya, Kuta",
                startDate: Calendar.current.date(
                    from: DateComponents(year: 2026, month: 6, day: 30)
                ) ?? .now,
                endDate: Calendar.current.date(
                    from: DateComponents(year: 2026, month: 6, day: 30)
                ) ?? .now,
                ownerID: CKRecord.ID(recordName: "Bintang"),
                invitationCode: "1A6B7K",
                createdAt: .now,
                updatedAt: .now
            )
        )
    }
}
