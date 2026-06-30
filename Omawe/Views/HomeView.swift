//
//  HomeView.swift
//  Omawe
//
//  Created by Muhammad Bintang Al-Fath on 30/06/26.
//

import SwiftUI

struct HomeView: View {
    var body: some View {
        ZStack(alignment: .top) {
            Color.white
                .ignoresSafeArea()
            VStack {
                
                Text("Main Content")
                
                    .font(.title)
                
                    .padding(.top, 150)
                
            }
            
            DynamicContainer {

            }
            
        }
        .statusBarHidden(true)
        .ignoresSafeArea(edges: .top)
        
    }
    
   
}

#Preview {
    HomeView()
}
