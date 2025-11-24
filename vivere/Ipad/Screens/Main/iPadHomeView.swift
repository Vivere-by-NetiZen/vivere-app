//
//  HomeView.swift
//  vivere
//
//  Created by Imo Madjid on 11/11/25.
//

import SwiftUI
import SwiftData

enum HomeDestination: Hashable, Codable {
    case puzzle
    case photoGallery
    case instructions
    case matchCard
}

struct iPadHomeView: View {
    @State private var path = NavigationPath()
    @State private var showPairDevice = false
    @State private var showInstructionsSheet = false
    @State private var showUploadImageSheet = false
    @State private var addNewImagesDetailTrigger = false
    @State private var imageIds = [String]()

    @AppStorage("hasShownInstructionsAutomatically") private var hasShownInstructionsAutomatically: Bool = false
    @AppStorage("debugAlwaysShowInstructions") private var debugAlwaysShowInstructions: Bool = false

    @Environment(MPCManager.self) private var mpc
    @Environment(\.modelContext) private var modelContext
    @Query private var images: [ImageModel]

    var body: some View {
        NavigationStack(path: $path) {
            ZStack {
                Color.viverePrimary
                    .ignoresSafeArea(edges: .all)

                VStack(spacing: 0) {
                    HStack(alignment: .center) {
                        HStack(spacing: 17) {
                            Image("Logo")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 60, height: 60)

                            Text("Vivere")
                                .font(.largeTitle)
                                .fontWeight(.semibold)
                                .foregroundColor(.white)
                                .tracking(0.192)
                        }

                        Spacer()

                        Menu {
                            Button {
                                path.append(HomeDestination.photoGallery)
                            } label: {
                                Label("Kelola Foto", systemImage: "photo.on.rectangle")
                            }

                            Button {
                                showInstructionsSheet = true
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
                                    .font(.title)
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
                            .font(.largeTitle)
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                            .tracking(0.192)
                            .padding(.top, 40)

                        // Game Cards Section
                        HStack(alignment: .center, spacing: 120) {
                            // Cocokkan Gambar Card
                            Button(action: {
                                if images.count < 3 {
                                    print("test img not enough")
                                    showUploadImageSheet = true
                                } else {
                                    print("test img enough")
                                    path.append(HomeDestination.matchCard)
                                }
                            }) {
                                CustomIpadButton(
                                    color: .gray50,
                                    showDashedBorder: false,
                                    shadowColor: Color(hex: "87622a"),
                                    shadowOffset: CGSize(width: 3, height: 4),
                                    action: {}
                                ) {
                                    VStack(spacing: 20) {
                                        Image("cocokkanGambar")
                                            .resizable()
                                            .scaledToFit()
                                            .frame(width: 340, height: 350)

                                        Text("Cocokkan Gambar")
                                            .font(.title2)
                                            .fontWeight(.semibold)
                                            .foregroundColor(.black)
                                    }
                                    .padding(30)
                                    .frame(minWidth: 400, minHeight: 470)
                                }
                                .styledContent
                            }

                            // Puzzle Card
                            NavigationLink(value: HomeDestination.puzzle) {
                                CustomIpadButton(
                                    color: Color(hex: "F9FAFB"),
                                    showDashedBorder: false,
                                    shadowColor: Color(hex: "87622a"),
                                    shadowOffset: CGSize(width: 3, height: 4),
                                    action: {}
                                ) {
                                    VStack(spacing: 20) {
                                        Image("puzzle")
                                            .resizable()
                                            .scaledToFit()
                                            .frame(width: 340, height: 350)

                                        Text("Puzzle")
                                            .font(.title2)
                                            .fontWeight(.semibold)
                                            .foregroundColor(.black)
                                    }
                                    .padding(30)
                                    .frame(minWidth: 400, minHeight: 470)
                                }
                                .styledContent
                            }
                            .buttonStyle(.plain)
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .padding(.horizontal, 40)

                    Spacer()
                }
                .zIndex(1)

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
            .navigationDestination(for: HomeDestination.self) { destination in
                switch destination {
                case .puzzle:
                    PuzzleView()
                case .photoGallery:
                    PhotoGalleryView()
                case .instructions:
                    EmptyView() // No longer used - InstructionSheetView is now a sheet
                case .matchCard:
                    MatchCardView()
                }
            }
            .navigationDestination(isPresented: $addNewImagesDetailTrigger) {
                InputContextView(imagesIds: imageIds, isOnboarding: false)
            }
            .sheet(isPresented: $showPairDevice) {
                PairDeviceSheetView()
                    .environment(mpc)
            }
            .sheet(isPresented: $showInstructionsSheet) {
                InstructionSheetView()
                    .onDisappear {
                        // Mark as shown automatically only if debug mode is off
                        if !debugAlwaysShowInstructions {
                            hasShownInstructionsAutomatically = true
                        }
                    }
            }
            .onAppear {
                // Show instructions automatically on first launch or if debug mode is enabled
                if !hasShownInstructionsAutomatically || debugAlwaysShowInstructions {
                    showInstructionsSheet = true
                }
            }
            .sheet(isPresented: $showUploadImageSheet) {
                UploadImageSheetView(isPresented: $showUploadImageSheet, inputDetailTrigger: $addNewImagesDetailTrigger, localIdentifier: $imageIds)
            }
            .onReceive(NotificationCenter.default.publisher(for: .navigateToHome)) { _ in
                path.removeLast(path.count)
            }
            .onReceive(NotificationCenter.default.publisher(for: .navigateToOnboarding)) { _ in
                path.append(Teleporter.onboarding)
            }
            .navigationDestination(for: Teleporter.self) { destination in
                switch destination {
                case .onboarding:
                    OnboardingView()
                }
            }
            .onReceive(NotificationCenter.default.publisher(for: .moodUpdate)) { notification in
                if let value = notification.userInfo?["value"] as? String {
                    Task { @MainActor in
                        try? await MoodProcessingService.updateFeaturedModelEmotion(to: value, in: modelContext)
                    }
                } else if
                    let userInfo = notification.userInfo,
                    let id = userInfo["id"] as? UUID,
                    let emotion = userInfo["emotion"] as? Emotion {
                    do {
                        let descriptor = FetchDescriptor<ImageModel>()
                        if let images = try? modelContext.fetch(descriptor),
                           let model = images.first(where: { $0.id == id }) {
                            model.emotion = emotion
                            try? modelContext.save()
                            #if DEBUG
                            print("✅ Updated emotion for featured ImageModel \(id) to \(emotion)")
                            #endif
                        } else {
                            #if DEBUG
                            print("⚠️ Featured ImageModel with id \(id) not found")
                            #endif
                        }
                    }
                }
            }
        }
    }
}

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
                                .font(.title2)
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

