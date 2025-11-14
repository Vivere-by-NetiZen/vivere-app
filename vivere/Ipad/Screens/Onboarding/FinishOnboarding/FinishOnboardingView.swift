//
//  FinishOnboardingView.swift
//  vivere
//
//  Created by Reinhart on 11/11/25.
//

import SwiftUI

struct FinishOnboardingView: View {
    @State private var isNextPressed: Bool = false
    @AppStorage("hasCompletedIpadOnboarding") private var hasCompletedIpadOnboarding: Bool = false

    var body: some View {
        ZStack {
            Color.viverePrimary.ignoresSafeArea(edges: .all)

            VStack {
                //placeholder
                ZStack {
                    Color.vivereSecondary.frame(width: 300, height: 300)
                        .clipShape(Circle())
                    Text("ASET")
                        .font(.largeTitle)
                        .fontWeight(.semibold)
                        .foregroundColor(Color.red)
                }

                Text("Semua sudah siap ⭐️")
                    .font(Font.largeTitle.bold())
                    .foregroundColor(.white)
                    .padding(.top, 30)

                Text("Pengaturan telah selesai, sekarang Anda bisa memulai percakapan hangat dengan Eyang.")
                    .font(Font.title)
                    .foregroundColor(Color.white)
                    .frame(width: 800)
                    .multilineTextAlignment(.center)
                    .padding(.top, 10)
                    .padding(.bottom, 30)

                CustomIpadButton(label: "Mulai", color: .accent, style: .large){
                    hasCompletedIpadOnboarding = true
                    NotificationCenter.default.post(name: .didReachIpadHome, object: nil)

                    isNextPressed = true
                }
            }
        }
        .navigationBarBackButtonHidden(true)
        .navigationDestination(isPresented: $isNextPressed) {
            iPadHomeView()
                .navigationBarBackButtonHidden(true)
        }
    }
}

#Preview {
    FinishOnboardingView()
}
