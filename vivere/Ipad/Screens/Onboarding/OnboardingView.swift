//
//  OnboardingView.swift
//  vivere
//
//  Created by Reinhart on 07/11/25.
//

import SwiftUI

struct OnboardingView: View {
    @State private var isNextPressed: Bool = false
    @State private var isAccepted: Bool = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.viverePrimary.ignoresSafeArea(edges: .all)
                
                HStack {
                    Image("Logo")
                        .resizable()
                        .frame(width: 42, height: 44)
                    Text("Logo")
                        .font(.largeTitle)
                        .fontWeight(.semibold)
                        .foregroundColor(Color.white)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                .padding()
                
                VStack {
                    //                Image("")
                    //                    .frame(width: 300, height: 300)
                    //                    .clipShape(Circle())
                    
                    //placeholder
                    ZStack {
                        Color.vivereSecondary.frame(width: 300, height: 300)
                            .clipShape(Circle())
                        Text("ASET")
                            .font(.largeTitle)
                            .fontWeight(.semibold)
                            .foregroundColor(Color.red)
                    }
                    
                    Text("Hai, selamat datang")
                        .font(Font.largeTitle.bold())
                        .foregroundColor(.white)
                        .padding(.top, 30)
                    
                    Text("Sebelum memulai, akan ada beberapa langkah ringan yang perlu dilakukan untuk menyiapkan pengalaman terbaik.")
                        .font(Font.title)
                        .foregroundColor(Color.white)
                        .frame(width: 800)
                        .multilineTextAlignment(.center)
                        .padding(.top, 10)
                        .padding(.bottom, 30)
                    
                    CustomIpadButton(label: "Lanjut", color: .accent, style: .large){
                        isNextPressed = true
                    }
                    
                }
                
                if isNextPressed {
                    PrivacyStatementView(isNextPressed: $isNextPressed, isAccepted: $isAccepted)
                }
                
            }
            .navigationDestination(isPresented: $isAccepted) {
                DeviceConnectionView()
            }
        }
    }
}

#Preview {
    OnboardingView()
}
