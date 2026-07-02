//
//  TripDetailView.swift
//  Omawe
//
//  Created by Gleenryan on 01/07/26.
//

import SwiftUI



struct TripDetailView: View {
    var body: some View {
        ZStack(alignment: .top) {
            Color.white
                .ignoresSafeArea()
            
            VStack {
                VStack {
                    DynamicBox(
                        theme: Theme.themeSecondary,
                        icon: "balloon.2",
                        title: "Ex-Boyfriends\nCelebration!",
                        subtitle: "by @Bintang • 27/06/2026 • 11:30",
                        helperText: "Swipe to see other trips",//curently this is missing symbol
                        footerTitle: "Trip is not starting yet"
                    ) {
                        VStack{
//                            PeopleOrbitView(count: 6)
//                                .frame(height: 200)
                            PeopleOrbit(people: 6)
                                .padding(.bottom, 16)
                            
                            
                            
                            HStack(spacing: 4) {
                                Image(systemName: "location.circle.fill")
                                Text("Toko Kopi Jaya, Kuta")
                            }
                            .font(.caption.bold())
                            .foregroundStyle(Color(uiColor: .tertiarySystemBackground).opacity(0.7))
                            .padding(.bottom, 24)
                            
                            HStack(spacing:12){
                                StartTripButton()
                                
                                Button {

                                } label: {
                                    Image(systemName: "list.bullet.indent")
                                        .font(.largeTitle)
                                        .foregroundStyle(Color.primary)
                                        .frame(width: 55, height: 55)
                            
                                }
                                .buttonStyle(.glass)
                                .clipShape(Circle())
                            }
                            .padding(.horizontal,24)
                            .padding(.bottom, 55)
//                            .border(Color.gray, width: 1)
                        }
                        
                        
                    }
                }
            }
        }
//        .statusBarHidden(true)
        .ignoresSafeArea(edges: .top)
    }
}

struct StartTripButton: View {
    var body: some View {
        Button(action: {}) {
            Text("Start trip now")
                .font(.subheadline)
                .fontWeight(.semibold)
                .fontWidth(.expanded)
                .foregroundColor(.white)
//                .border(Color.red, width: 5)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 22.5)
//                .padding(.horizontal, 60)
                
//                .padding(10)
                .background(
                    Capsule()
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color(red: 0.05, green: 0.25, blue: 0.24),
                                    Color(red: 0.11, green: 0.35, blue: 0.32)
                                ],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                )
                .overlay(
                    Capsule()
                        .strokeBorder(
                            Color(red: 0.4, green: 0.85, blue: 0.9),
                            lineWidth: 2
                        )
                        .shadow(color: Color(red: 0.4, green: 0.85, blue: 0.9).opacity(0.6), radius: 8)
                )
                .clipShape(Capsule())
        }
//        .padding(.horizontal, 10)
    }
}


#Preview {
    TripDetailView()
}
