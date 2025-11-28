////
////  OnBoardingSheetView.swift
////  vivere
////
////  Created by Ahmed Nizhan Haikal on 11/11/25.
////
//
//import Foundation
//import SwiftUI
//
//struct OnBoardingSheetView: View {
//    let onStart: () -> Void
//    
//    var body: some View {
//        ZStack {
//            Color.white.ignoresSafeArea()
//            
//            VStack(spacing: 0) {
//                // Top content
//                ScrollView {
//                    VStack(spacing: 16) {
//                        VStack(alignment: .leading, spacing: 8) {
//                            Text("Sebelum dimulai!")
//                                .font(.title2).bold()
//                                .foregroundStyle(.black)
//                            
//                            Text("Sebelum memulai terapi dengan demensia, pastikan kamu sudah menyiapkan hal-hal berikut agar sesi berjalan dengan nyaman:")
//                                .font(.callout)
//                                .foregroundStyle(.black)
//                        }
//                        
//                        VStack(alignment: .leading, spacing: 24) {
//                            InfoRow(icon: "ipad", title: "Unduh Vivere pada iPad-mu", text: "Pastikan aplikasi Vivere terpasang di iPad-mu agar sesi terapi berjalan dengan lancar.")
//                            InfoRow(icon: "person.2.fill", title: "Pastikan siap untuk terapi", text: "Pastikan kamu dan ODD (Orang Dengan Demensia) siap untuk memulai sesi terapi.")
//                            InfoRow(icon: "ipad.landscape.and.iphone", title: "Pastikan iPad dalam jangkauan", text: "Pastikan iPad berada di dekatmu agar sesi tetap terhubung dengan baik.")
//                        }
//                    }
//                    .frame(maxWidth: .infinity, alignment: .leading)
//                    .padding(.horizontal, 34)
//                    .padding(.top, 24)
//                    .padding(.bottom, 16)
//                }
//                
//                // Bottom button pinned
//                VStack(spacing: 0) {
//                    Button(action: onStart) {
//                        Text("Mulai")
//                            .font(.headline)
//                            .frame(maxWidth: .infinity)
//                            .padding()
//                            .background(Color.darkBlue)
//                            .foregroundColor(.white)
//                            .cornerRadius(12)
//                    }
//                    .padding(.horizontal, 20)
//                    .padding(.top, 8)
//                    .padding(.bottom, 20)
//                }
//                .background(Color.white.opacity(0.001)) // keep tap area/visual separation if needed
//            }
//        }
//    }
//}
//
//struct InfoRow: View {
//    let icon: String
//    let title: String
//    let text: String
//    
//    var body: some View {
//        HStack(alignment: .top, spacing: 12) {
//            Image(systemName: icon)
//                .frame(width: 32, height: 32)
//                .background(.black.opacity(0.04))
//                .foregroundStyle(.black)
//                .clipShape(Circle())
//            
//            VStack(alignment: .leading, spacing: 4) {
//                Text(title)
//                    .font(.callout.bold())
//                    .foregroundStyle(.black)
//                Text(text)
//                    .font(.caption)
//                    .foregroundStyle(.black)
//            }
//        }
//    }
//}
//
//#Preview {
//    OnBoardingSheetView(onStart: { print("Ya") })
//}
