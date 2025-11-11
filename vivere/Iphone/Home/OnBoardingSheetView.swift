//
//  OnBoardingSheetView.swift
//  vivere
//
//  Created by Ahmed Nizhan Haikal on 11/11/25.
//

import Foundation
import SwiftUI

struct OnBoardingSheetView: View {
    let onStart: () -> Void
    
    var body: some View {
        VStack(spacing: 20) {
            Capsule()
                .frame(width: 40, height: 4)
                .foregroundStyle(.gray.opacity(0.4))
                .padding(.top, 8)
            
            VStack(alignment: .leading, spacing: 8) {
                Text("Sebelum dimulai!")
                    .font(.title2).bold()
                    .foregroundStyle(.black)
                
                Text("""
Sebelum memulai terapi dengan demensia, pastikan kamu sudah menyiapkan hal-hal berikut agar sesi berjalan dengan nyaman:
""")
                .font(.callout)
                .foregroundStyle(.black)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            
            VStack(alignment: .leading, spacing: 16) {
                InfoRow(icon: "ipad.fill", title: "Unduh Vivere pada iPad-mu", text: "Pastikan aplikasi Vivere terpasang di iPad-mu agar sesi terapi berjalan dengan lancar.")
                
                InfoRow(icon: "person.2.fill", title: "Pastikan siap untuk terapi", text: "Pastikan kamu dan ODD (Orang Dengan Demensia) siap untuk memulai sesi terapi.")
                
                InfoRow(icon: "ipad.landscape.and.iphone", title: "Pastikan iPad dalam jangkauan", text: "Pastikan iPad berada di dekatmu agar sesi tetap terhubung dengan baik.")
            }
            
            Button(action: onStart) {
                Text("Mulai")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.darkBlue)
                    .foregroundColor(.white)
                    .cornerRadius(12)
            }
            .padding(.top, 8)
        }
//        .padding(.horizontal, 24)
//        .padding(.bottom, 32)
//        .padding(.horizontal, 0)
    }
}

struct InfoRow: View {
    let icon: String
    let title: String
    let text: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
//                .font(.title3)
                .frame(width: 32, height: 32)
                .background(.black.opacity(0.04))
                .foregroundStyle(.black)
                .clipShape(Circle())
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.callout.bold())
                    .foregroundStyle(.black)
                Text(text)
                    .font(.caption)
                    .foregroundStyle(.black)
            }
        }
    }
}

#Preview {
    OnBoardingSheetView(onStart: { print("Ya") })
}
