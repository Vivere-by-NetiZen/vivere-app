//
//  PuzzleView.swift
//  vivere
//
//  Created by Reinhart on 05/11/25.
//

import SwiftUI
import SwiftData
import Photos

struct PuzzleView: View {
    @ObservedObject var viewModel = PuzzleViewModel()

    @State var isCompleted: Bool = false
    @State var showCompletionView: Bool = false
    @State var isTutorialShown: Bool = false
    @State var isExitConfirmationShown: Bool = false

    @Environment(MPCManager.self) private var mpc
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Query private var images: [ImageModel]

    var body: some View {
        GeometryReader { geo in
            ZStack {
                Color.viverePrimary
                    .ignoresSafeArea()

                // 1) The Game Board & Elements (Absolute Positioning)
                // We use a Group so we can use .position() which relies on the GeometryReader's coordinate space (which matches the screen size if we ignore safe area or if geo fills screen)
                // However, GeometryReader in this context is the root view, so coordinates should match.
                Group {
                    // Puzzle Board Background & Reference Image
                    ZStack {
                        // Puzzle board background
                        RoundedRectangle(cornerRadius: 0)
                            .fill(Color.white)
                            .frame(width: viewModel.size * CGFloat(viewModel.col) + 40, height: viewModel.size * CGFloat(viewModel.row) + 40)
                            .overlay(
                                RoundedRectangle(cornerRadius: 0)
                                    .stroke(Color.black, lineWidth: 4)
                            )

                        // Reference image (faded)
                        if let referenceImage = viewModel.normalizedImage {
                            Image(uiImage: referenceImage)
                                .resizable()
                                .frame(width: viewModel.size * CGFloat(viewModel.col), height: viewModel.size * CGFloat(viewModel.row))
                                .opacity(0.5)
                        }
                        Image("puzzleOutline")
                            .resizable()
                            .frame(width: viewModel.size * CGFloat(viewModel.col), height: viewModel.size * CGFloat(viewModel.row))
                            .opacity(0.5)
                    }
                    .position(viewModel.boardCenter) // <--- Aligns perfectly with logic
                }

                // 2) Puzzle Pieces (Absolute Positioning)
                ForEach($viewModel.pieces) { $piece in
                    PuzzlePieceView(piece: $piece, size: viewModel.size, dentScale: viewModel.dentScale, trayScale: viewModel.trayScale) {
                        viewModel.markPieceAsActive(piece.id)
                    }
                }

                // 3) UI Overlays (Header, etc.)
                VStack {
                    HStack {
                        Image(systemName: "chevron.left")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .foregroundColor(.black)
                            .padding()
                            .background(Color.white)
                            .clipShape(Circle())
                            .onTapGesture {
                                isExitConfirmationShown = true
                            }
                            .padding(40)
                        Spacer()
                        Text("Rangkai kepingan puzzle sesuai gambarnya ya")
                            .font(Font.largeTitle)
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                        Spacer()
                        Image(systemName: "questionmark.circle")
                            .font(.system(size: 50))
                            .fontWeight(.semibold)
                            .foregroundColor(.accent)
                            .onTapGesture {
                                isTutorialShown = true
                            }
                            .padding(40)
                    }
                    .frame(maxWidth: .infinity)
                    Spacer()
                }

                if isTutorialShown {
                    PuzzleTutorialView(isPresented: $isTutorialShown)
                        .zIndex(2000)
                }

                if isExitConfirmationShown {
                    ExitGameConfirmationView(isPresented: $isExitConfirmationShown)
                        .zIndex(2000)
                }
            }
            .onAppear {
                Task {
                    viewModel.images = images
                    await viewModel.preparePuzzleIfNeeded(screenSize: geo.size)
                }
            }
            .onChange(of: viewModel.pieces) {
                let completed = viewModel.pieces.allSatisfy{$0.currPos == $0.correctPos}
                if completed && !isCompleted {
                    isCompleted = true
                    // Show completion view after a brief delay
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        showCompletionView = true
                    }
                }
            }
//            .onChange(of: viewModel.triggerSendToIphone) {
//                if viewModel.triggerSendToIphone {
//                    if let normalizedImage = viewModel.normalizedImage {
//                        sendImageForInitialQuestion(normalizedImage)
//                    }
//                    viewModel.triggerSendToIphone = false
//                }
//            }
            .navigationBarBackButtonHidden(true)
            .fullScreenCover(isPresented: $showCompletionView) {
                CompletionView(imageModel: viewModel.selectedImageModel, image: viewModel.normalizedImage)
            }
        }
    }

    // MARK: - MPC send
    func sendImageForInitialQuestion(_ image: UIImage) {
        // Prefer JPEG to keep payload smaller; adjust quality as needed
        guard let data = image.jpegData(compressionQuality: 0.8) ?? image.pngData() else {
            return
        }
        // Simple envelope: 4 bytes length of "type" + utf8 type + payload
        let type = "initial_question_image"
        guard let typeData = type.data(using: .utf8) else { return }

            var envelope = Data()
            var typeLen = UInt32(typeData.count).bigEndian
            withUnsafeBytes(of: &typeLen) { envelope.append(contentsOf: $0) }
            envelope.append(typeData)
            envelope.append(data)

            mpc.send(data: envelope)
            print("Sent image to iphone")
        }
}

#Preview {
    PuzzleView()
}

