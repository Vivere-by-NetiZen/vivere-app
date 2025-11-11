//
//  HomeView.swift
//  vivere
//
//  Created by Imo Madjid on 11/11/25.
//

import SwiftUI

struct iPadHomeView: View {
    var body: some View {
        ZStack {
            Color.viverePrimary
                .ignoresSafeArea(edges: .all)

            VStack(spacing: 0) {
                // Header Section
                HStack {
                    Spacer()
                    // Question mark button using CustomIpadButton
                    CustomIpadButton(
                        label: "",
                        icon: Image(systemName: "questionmark"),
                        color: .accent,
                        style: .icon
                    ) {
                        // Action
                    }
                    .frame(width: 88, height: 56)
                }
                .padding(.horizontal, 80)
                .padding(.top, 60)
                .overlay(
                    // Logo centered in header
                    Image("Logo")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 60, height: 60)
                )

                // Middle Section
                HStack(spacing: 160) {
                    // Polaroid Photo Section
                    PolaroidPhotoView()

                    // Buttons Section
                    VStack(spacing: 24) {
                        // Mulai Bercerita Button
                        CustomIpadButton(color: .darkBlue) {
                            // Action
                        } label: {
                            VStack(spacing: 10) {
                                HStack(spacing: 24) {
                                    Image(systemName: "bubble.left.and.bubble.right.fill")
                                        .resizable()
                                        .scaledToFit()
                                        .frame(width: 42, height: 42)
                                        .foregroundColor(.white)

                                    Text("Mulai Bercerita")
                                        .font(.system(size: 28, weight: .bold))
                                        .foregroundColor(.white)
                                }

                                Text("Ajak eyangmu bercerita dengan foto pilihan kami")
                                    .font(.system(size: 17))
                                    .foregroundColor(.white)
                                    .multilineTextAlignment(.center)
                                    .frame(maxWidth: 320)
                            }
                            .padding(20)
                            .frame(width: 420, height: 200)
                        }

                        // Kelola Foto Button
                        CustomIpadButton(color: .vivereSecondary) {
                            // Action
                        } label: {
                            VStack(spacing: 10) {
                                Text("Kelola Foto")
                                    .font(.system(size: 28, weight: .bold))
                                    .foregroundColor(.black)

                                Text("Tambahkan, ubah, atau hapus foto pilihanmu beserta cerita di dalamnya")
                                    .font(.system(size: 17))
                                    .foregroundColor(.black)
                                    .multilineTextAlignment(.center)
                                    .frame(maxWidth: 320)
                            }
                            .padding(20)
                            .frame(width: 420, height: 160)
                        }
                    }
                    .frame(width: 420)
                }
                .padding(.horizontal, 80)
                .padding(.top, 80)

                Spacer()
            }

            // Decorative stitching element at bottom
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    // Decorative element - simplified representation
                    Path { path in
                        path.move(to: CGPoint(x: 0, y: 0))
                        path.addCurve(
                            to: CGPoint(x: 600, y: -200),
                            control1: CGPoint(x: 200, y: -100),
                            control2: CGPoint(x: 400, y: -150)
                        )
                    }
                    .stroke(style: StrokeStyle(lineWidth: 2, dash: [10, 5]))
                    .foregroundColor(.accent)
                    .opacity(0.6)
                    .offset(x: -54, y: -70)
                }
            }
        }
    }
}

// Polaroid Photo Component
struct PolaroidPhotoView: View {
    var body: some View {
        VStack {
            ZStack {
                // Polaroid frame
                RoundedRectangle(cornerRadius: 0)
                    .fill(.white)
                    .frame(width: 400, height: 500)
                    .overlay(
                        RoundedRectangle(cornerRadius: 0)
                            .stroke(.black, lineWidth: 1)
                    )

                VStack(spacing: 20) {
                    // Photo - using placeholder for now
                    Image("card1")
                        .resizable()
                        .scaledToFill()
                        .frame(width: 360, height: 352)
                        .clipped()

                    // Text below photo
                    Text("Kami di RSUI bersama TSC")
                        .font(.system(size: 17))
                        .foregroundColor(.black)
                        .multilineTextAlignment(.center)
                        .padding(.bottom, 30)
                }
                .padding(.top, 20)
                .padding(.horizontal, 20)
            }
        }
        .rotationEffect(.degrees(-3.4))
    }
}

#Preview {
    iPadHomeView()
}
