//
//  HomeView.swift
//  vivere
//
//  Created by Imo Madjid on 11/11/25.
//

import SwiftUI

struct iPadHomeView: View {
    @State private var showPuzzleView = false
    @State private var showPuzzleTutorialSheet = false
    @State private var showPhotoGallery = false
    @State private var showUsageInstructions = false
    @State private var showPairDevice = false
    @Environment(MPCManager.self) private var mpc

    var body: some View {
        NavigationStack {
            ZStack {
                Color.viverePrimary
                    .ignoresSafeArea(edges: .all)

                VStack(spacing: 0) {
                    // Header Section
                    HStack(alignment: .center) {
                        // Logo and Title
                        HStack(spacing: 17) {
                            Image("Logo")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 60, height: 60)

                            Text("Vivere")
                                .font(.system(size: 48, weight: .semibold))
                                .foregroundColor(.white)
                                .tracking(0.192)
                        }

                        Spacer()

                        // Ellipsis Menu Button
                        Menu {
                            Button {
                                showPhotoGallery = true
                            } label: {
                                Label("Kelola Foto", systemImage: "photo.on.rectangle")
                            }

                            Button {
                                showUsageInstructions = true
                            } label: {
                                Label("Instruksi Penggunaan", systemImage: "book")
                            }

                            Button {
                                showPairDevice = true
                            } label: {
                                Label("Koneksi iPhone", systemImage: "iphone")
                            }
                        } label: {
                            ZStack {
                                RoundedRectangle(cornerRadius: 32)
                                    .foregroundColor(.accent)
                                    .shadow(
                                        color: Color(hex: "87622a").opacity(0.5),
                                        radius: 0,
                                        x: 2,
                                        y: 4
                                    )

                                Image(systemName: "ellipsis")
                                    .font(.system(size: 40))
                                    .foregroundColor(.black)
                            }
                            .frame(width: 64, height: 64)
                        }
                        .menuStyle(.borderlessButton)
                    }
                    .padding(.horizontal, 40)
                    .padding(.top, 40)

                    // Title Section
                    VStack(alignment: .center, spacing: 40) {
                        Text("Mau main apa hari ini?")
                            .font(.system(size: 48, weight: .semibold))
                            .foregroundColor(.white)
                            .tracking(0.192)
                            .padding(.top, 40)

                        // Game Cards Section
                        HStack(alignment: .center, spacing: 120) {
                            // Cocokkan Gambar Card
                            CustomIpadButton(
                                color: Color(hex: "F9FAFB"),
                                showDashedBorder: false,
                                shadowColor: Color(hex: "87622a"),
                                shadowOffset: CGSize(width: 3, height: 4),
                                action: {
                                    // Action for Cocokkan Gambar
                                }
                            ) {
                                VStack(spacing: 20) {
                                    Image("cocokkanGambar")
                                        .resizable()
                                        .scaledToFit()
                                        .frame(width: 340, height: 350)

                                    Text("Cocokkan Gambar")
                                        .font(.system(size: 32, weight: .semibold))
                                        .foregroundColor(.black)
                                }
                                .padding(30)
                                .frame(minWidth: 400, minHeight: 470)
                            }

                            // Puzzle Card
                            CustomIpadButton(
                                color: Color(hex: "F9FAFB"),
                                showDashedBorder: false,
                                shadowColor: Color(hex: "87622a"),
                                shadowOffset: CGSize(width: 3, height: 4),
                                action: {
                                    showPuzzleTutorialSheet = true
                                }
                            ) {
                                VStack(spacing: 20) {
                                    Image("puzzle")
                                        .resizable()
                                        .scaledToFit()
                                        .frame(width: 340, height: 350)

                                    Text("Puzzle")
                                        .font(.system(size: 32, weight: .semibold))
                                        .foregroundColor(.black)
                                }
                                .padding(30)
                                .frame(minWidth: 400, minHeight: 470)
                            }
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .padding(.horizontal, 40)

                    Spacer()
                }
                .zIndex(1)

                // Decorative image at bottom left
                VStack {
                    Spacer()
                    HStack {
                        Image("home")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 640, height: 400)
                            .padding(.leading, -50)
                            .padding(.bottom, -120)
                        Spacer()
                    }
                }
                .zIndex(0)
            }
            .navigationBarBackButtonHidden(true)
            .navigationDestination(isPresented: $showPuzzleView) {
                PuzzleView()
            }
            .navigationDestination(isPresented: $showPhotoGallery) {
                PhotoGalleryView()
            }
            .navigationDestination(isPresented: $showUsageInstructions) {
                InstruksiPenggunaanView()
            }
            .sheet(isPresented: $showPairDevice) {
                PairDeviceSheetView()
                    .environment(mpc)
            }
            .sheet(isPresented: $showPuzzleTutorialSheet) {
                PuzzleTutorialSheetView(onComplete: {
                    showPuzzleTutorialSheet = false
                    // Small delay to ensure sheet is dismissed before navigation
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        showPuzzleView = true
                    }
                })
            }
        }
    }
}

// Sheet wrapper for PairDeviceView
struct PairDeviceSheetView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var isNextPressed: Bool = false
    @State private var isPaired: Bool = false
    @Environment(MPCManager.self) private var mpc

    var body: some View {
        NavigationStack {
            ZStack {
                Color.viverePrimary.ignoresSafeArea(edges: .all)

                VStack(spacing: 30) {
                    HStack {
                        Spacer()
                        Button {
                            dismiss()
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .font(.system(size: 32))
                                .foregroundColor(.white)
                        }
                        .padding()
                    }

                    if !isNextPressed {
                        VStack(spacing: 16) {
                            Text("Hubungkan Perangkat Anda")
                                .font(.largeTitle)
                                .fontWeight(.bold)
                                .foregroundColor(.white)

                            Text("Tekan tombol \"hubungkan\" di bawah lalu dekatkan iPad dengan iPhone, perangkat akan otomatis terhubung satu sama lain.")
                                .font(.body)
                                .foregroundColor(.white)
                                .multilineTextAlignment(.center)
                                .lineLimit(nil)
                                .padding(.horizontal, 40)
                        }

                        CustomIpadButton(label: "Mulai Pencarian", color: .accent, style: .large) {
                            isNextPressed = true
                        }
                    } else {
                        PairDeviceView(isNextPressed: $isNextPressed, isPaired: $isPaired)
                            .onChange(of: isPaired) { _, newValue in
                                if newValue {
                                    dismiss()
                                }
                            }
                    }

                    Spacer()
                }
            }
            .navigationBarBackButtonHidden(true)
        }
    }
}

#Preview {
    iPadHomeView()
        .environment(MPCManager())
}
