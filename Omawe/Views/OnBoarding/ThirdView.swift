//
//  ThirdView.swift
//  Omawe
//
//  Created by Nguyen Minh Luat on 6/7/26.
//



import SwiftUI
import Lottie


struct ThirdView: View {
    @State private var appeared = false
    @State private var shimmerX: CGFloat = -1



    var body: some View {
        ZStack {


            
            VStack {
                VStack{

                    Spacer ()
                    
                    VStack{
                        HStack {
                            Circle ()
                                .fill(Color.gray.opacity(0.4))
                                .frame(width: 8, height: 8)

                            Circle ()
                                .fill(Color.gray.opacity(0.4))
                                .frame(width: 8, height: 8)
                            
                            Rectangle ()
                                .fill(Color.cyan.opacity(1))
                                .frame(width: 30, height: 8)
                                .cornerRadius(12)
                            
                        }
                        Text("Create, Share and Go")
                            .font(.title)
                            .fontWidth(.expanded)
                            .fontWeight(.semibold)
                            .multilineTextAlignment(.center)
                            .foregroundStyle(Color(hex:"343434"))
                            .frame(maxWidth: .infinity)
                            .padding(10)
                        Text ("Start a trip in seconds, invite friends with a simple code, and watch everyone arrive together.")
                            .font(.footnote)
                            .fontWeight(.regular)
                            .foregroundColor(.black)
                            .opacity(0.5)
                            .multilineTextAlignment(.center)
                            .frame(maxWidth: .infinity)
                            .padding(.horizontal, 20)
                    }
                }
                Spacer()
                Button(action: {}) {
                    Text("Let's start")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .fontWidth(.expanded)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 22.5)
                        .shadow(color: .blue.opacity(0.5), radius: 4, x: 0, y: 2)
                        .background(
                            Capsule()
                                .fill(
                                    LinearGradient(stops: [
                                        .init(color: Color(hex: "03B9D6"), location: 0.0),
                                        .init(color: Color(hex: "7AE8FF"), location: 1),
                                    ], startPoint: UnitPoint.top, endPoint: .bottom)
                                )
                        )
                        .overlay(
                            Capsule()
                                .strokeBorder(
                                    LinearGradient(stops: [
                                        .init(color: Color(hex: "03B9D6"), location: 0.0),
                                        .init(color: Color(hex: "7AE8FF"), location: 1),
                                    ], startPoint: UnitPoint.trailing, endPoint: .leading),
                                    lineWidth: 1
                                )
                                .shadow(color: Color(red: 0.4, green: 0.85, blue: 0.9).opacity(0.6), radius: 8)
                        )
                        .clipShape(Capsule())
                }
                .shadow(color: .cyan.opacity(0.4), radius: 10, x: 0, y: 0)
                .padding(.horizontal, 16)
                .padding(.vertical, 32)
            }
            .containerRelativeFrame(.horizontal) { width, _ in
                width * 1
            }

        }
        .background {
            Image(.homeBackground)
                .resizable()
                .scaledToFill()
                .ignoresSafeArea()
        }
        .padding(1)
        .ignoresSafeArea()
        
    }
}

#Preview {
    ThirdView()
}
