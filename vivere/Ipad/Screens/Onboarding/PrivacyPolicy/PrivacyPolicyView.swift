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
                        .foregroundColor(.white)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                .padding(.vertical, 40)
                .padding(.horizontal, 40)
                
                VStack {
                    Image("privacyPolicy")
                        .frame(width: 300, height: 300)
                    
                    VStack(spacing: 16){
                        Text("Kebijakan Privasi")
                            .font(Font.largeTitle.bold())
                            .foregroundColor(.white)
//                            .padding(.top, 30)
                            .frame(width: 700)
                            .multilineTextAlignment(.center)
                        
                        Text("Aplikasi ini memerlukan izin untuk mengumpulkan dan menyimpan beberapa foto pribadi untuk digunakan dalam fitur yang tersedia. Data yang dikumpulkan akan dijaga keamanannya agar tidak dibagikan tanpa persetujuan.")
                            .font(.title2)
                            .foregroundColor(.white)
                            .frame(width: 800)
                            .multilineTextAlignment(.center)
//                            .padding(.top, 10)
                            .padding(.bottom, 40)
                    }
                    
                    HStack {
                        Text("Dengan melanjutkan, kamu menyetujui ketentuan")
                            .foregroundColor(.white)
                        Button(action: {
                            isPrivacyPressed = true
                        }){
                            Text("persetujuan pengguna")
                                .foregroundColor(.white)
                                .fontWeight(.semibold)
                                .underline()
                        }
                        Text("dan")
                            .foregroundColor(Color.white)
                        Button(action: {
                            isPrivacyPressed = true
                        }){
                            Text("kebijakan privasi")
                                .foregroundColor(.white)
                                .fontWeight(.semibold)
                                .underline()
                            
                        }
                        Text("kami")
                            .foregroundColor(.white)
                    }
                    .padding(.bottom, 8)
                    
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
                MediaCollectionView()
            }
        }
    }
}

#Preview {
    PrivacyPolicyView()
}
