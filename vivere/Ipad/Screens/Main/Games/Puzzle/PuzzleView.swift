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

                    HStack(spacing: 60) {
                        // Left side: Puzzle board
                        ZStack {
                            // Puzzle board background
                            RoundedRectangle(cornerRadius: 0)
                                .fill(Color.white)
                                .frame(width: viewModel.size * CGFloat(viewModel.col) + 40, height: viewModel.size * CGFloat(viewModel.row) + 40)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 0)
                                        .stroke(Color.black, lineWidth: 4)
                                )
                                .offset(x: -25, y: -17)

                            // Reference image (faded)
                            if let referenceImage = viewModel.normalizedImage {
                                Image(uiImage: referenceImage)
                                    .resizable()
                                    .frame(width: viewModel.size * CGFloat(viewModel.col), height: viewModel.size * CGFloat(viewModel.row))
                                    .opacity(0.5)
                                    .offset(x: -25, y: -17)
                            }
                        }
                        .frame(width: viewModel.size * CGFloat(viewModel.col) + 40, height: viewModel.size * CGFloat(viewModel.row) + 40)

                        // Right side: Pieces area placeholder (visual guide)
                        VStack(spacing: viewModel.piecesAreaSpacing) {
                            ForEach(0..<viewModel.piecesAreaRows, id: \.self) { r in
                                HStack(spacing: viewModel.piecesAreaSpacing) {
                                    ForEach(0..<viewModel.piecesAreaCols, id: \.self) { c in
                                        // Empty placeholder
                                        Color.clear
                                            .frame(width: viewModel.size, height: viewModel.size)
                                    }
                                }
                            }
                        }
                        .frame(width: CGFloat(viewModel.piecesAreaCols) * viewModel.size + CGFloat(viewModel.piecesAreaCols - 1) * viewModel.piecesAreaSpacing)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .padding(.horizontal, 60)
                    .padding(.vertical, 40)
                }

                // All puzzle pieces (positioned absolutely)
                ForEach($viewModel.pieces) { $piece in
                    PuzzlePieceView(piece: $piece, size: viewModel.size)
                }

                if isTutorialShown {
                    PuzzleTutorialView(isPresented: $isTutorialShown)
                }
                
                if isExitConfirmationShown {
                    ExitGameConfirmationView(isPresented: $isExitConfirmationShown)
                }
            }
            .onAppear {
                Task {
                    viewModel.images = images
                    await viewModel.preparePuzzleIfNeeded(screenSize: geo.size)
                }
                mpc.send(message: "warm up")
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
            .onChange(of: viewModel.triggerSendToIphone) {
                if viewModel.triggerSendToIphone {
                    if let normalizedImage = viewModel.normalizedImage {
                        sendImageForInitialQuestion(normalizedImage)
                    }
                    viewModel.triggerSendToIphone = false
                }
            }
            .navigationBarBackButtonHidden(true)
            .fullScreenCover(isPresented: $showCompletionView) {
                CompletionView(imageModel: viewModel.selectedImageModel)
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

