//
//  PrivacyStatement.swift
//  vivere
//
//  Created by Reinhart on 09/11/25.
//

import SwiftUI

struct PrivacyStatementView: View {
    @Binding var isNextPressed: Bool
    @Binding var isAccepted: Bool
    
    @State var isAgree: Bool = false
    
    var body: some View {
        ZStack {
            Color.black.opacity(0.4)
                .ignoresSafeArea(.all)
                .onTapGesture {_ in
                    isNextPressed = false
                }
            
            HStack {
                VStack(alignment: .leading) {
                    Image("buttonLeft")
                        .padding()
                    Spacer()
                    Image("buttonLeft")
                        .padding()
                }
                .padding()
                
                VStack {
                    Text("Baca ini dulu ya")
                        .font(Font.largeTitle.bold())
                    
                    Line()
                        .stroke(style: .init(dash: [20]))
                        .frame(height: 1)
                    
                    ScrollView {
                        Text("Kebijakan Privasi")
                            .font(Font.title2.bold())
                            .padding(.bottom, 10)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        Text(privacyStatement)
                            .font(Font.title2)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .padding(.vertical, 20)
                    
                    HStack {
                        Button("\(Image(systemName: isAgree ? "checkmark.square.fill" : "square"))"){
                            isAgree.toggle()
                        }
                        .foregroundColor(.black)
                        
                        
                        Text("Saya telah membaca dan setuju pada persetujuan pengguna dan kebijakan privasi")
                    }
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    
                    HStack {
                        CustomIpadButton(label: "Tolak", color: .deny, style: .large) {
                            isNextPressed = false
                        }
                        Spacer()
                        CustomIpadButton(label: "Terima", color: isAgree ? .darkBlue : .gray300, style: .large) {
                            if isAgree {
                                isAccepted = true
                            }
                        }
                    }
                }
                .padding()
                .padding(.vertical, 30)
                
                VStack(alignment: .trailing) {
                    Image("buttonRight")
                        .padding()
                    Spacer()
                    Image("buttonRight")
                        .padding()
                }
                .padding()
            }
            .frame(maxWidth: 1000, maxHeight: 600)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .foregroundColor(.accent)
            )
        }
    }
    
    private var privacyStatement: String {
        "Untuk dapat berfungsi dengan baik dan memberikan hasil yang sesuai kebutuhan, aplikasi ini memerlukan izin untuk mengumpulkan dan menyimpan beberapa data pribadi, seperti foto pribadi. Data yang dikumpulkan hanya akan digunakan untuk melakukan sesi terapi, dan dijaga keamanannya agar tidak dibagikan tanpa persetujuan. ....."
    }
}

#Preview {
    @Previewable @State var isNextPressed: Bool = true
    @Previewable @State var isAccepted: Bool = false
    PrivacyStatementView(isNextPressed: $isNextPressed, isAccepted: $isAccepted)
}
