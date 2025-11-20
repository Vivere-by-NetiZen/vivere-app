//
//  OnboardingView.swift
//  vivere
//
//  Created by Reinhart on 07/11/25.
//

import SwiftUI

struct OnboardingView: View {
    @State private var isNextPressed: Bool = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.viverePrimary.ignoresSafeArea(edges: .all)
                
                HStack {
                    Image("Logo")
                        .resizable()
                        .frame(width: 42, height: 44)
                    Text("Vivere")
                        .font(.largeTitle)
                        .fontWeight(.semibold)
                        .foregroundColor(Color.white)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                .padding(.top, 40)
                .padding(.leading, 40)
                
                VStack(spacing: 48) {
                    Image("welcomeToVivere")
                        .frame(width: 300, height: 300)
                    
                    Text("Hai, selamat datang. Sebelum mulai, akan ada beberapa langkah setup dulu ya")
                        .font(Font.largeTitle.bold())
                        .foregroundColor(.white)
//                        .padding(.top, 30)
                        .frame(width: 700)
                        .multilineTextAlignment(TextAlignment.center)
                    
                    CustomIpadButton(label: "Lanjut", color: .accent, style: .large){
                        isNextPressed = true
                    }
                    
                }
                
            }
            .navigationDestination(isPresented: $isNextPressed) {
                PrivacyPolicyView()
            }
        }
    }
}

#Preview {
    OnboardingView()
}
