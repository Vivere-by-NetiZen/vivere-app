//
//  PrivacyPolicyView.swift
//  vivere
//
//  Created by Reinhart on 17/11/25.
//

import SwiftUI

struct PrivacyPolicyView: View {
    @State private var isNextPressed: Bool = false
    @State private var isPrivacyPressed: Bool = false
    
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
                .padding()
                
                VStack {
                    Image("privacyPolicy")
                        .frame(width: 300, height: 300)
                    
                    Text("Kebijakan Privasi")
                        .font(Font.largeTitle.bold())
                        .foregroundColor(.white)
                        .padding(.top, 30)
                        .frame(width: 700)
                        .multilineTextAlignment(TextAlignment.center)
                    
                    Text("Aplikasi ini memerlukan izin untuk mengumpulkan dan menyimpan beberapa foto pribadi untuk digunakan dalam fitur yang tersedia. Data yang dikumpulkan akan dijaga keamanannya agar tidak dibagikan tanpa persetujuan.")
                        .font(Font.title2)
                        .foregroundColor(Color.white)
                        .frame(width: 800)
                        .multilineTextAlignment(.center)
                        .padding(.top, 10)
                        .padding(.bottom, 30)
                    
                    HStack {
                        Text("Dengan melanjutkan, kamu menyetujui ketentuan")
                            .foregroundColor(Color.white)
                        Button("persetujuan pengguna"){
                            isPrivacyPressed = true
                        }
                        .foregroundColor(.accent)
                        Text("dan")
                            .foregroundColor(Color.white)
                        Button("kebijakan privasi"){
                            isPrivacyPressed = true
                        }
                        .foregroundColor(.accent)
                        Text("kami")
                            .foregroundColor(Color.white)
                    }
                    
                    CustomIpadButton(label: "Lanjut", color: .accent, style: .large){
                        isNextPressed = true
                    }
                    
                }
                
                if isPrivacyPressed {
                    PrivacyStatementView(isPresented: $isPrivacyPressed)
                }
                
            }
            .navigationBarBackButtonHidden(true)
            .navigationDestination(isPresented: $isNextPressed) {
                DeviceConnectionView()
            }
        }
    }
}

#Preview {
    PrivacyPolicyView()
}
