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
    @State private var pieces: [PuzzlePiece] = []
    @State private var isCompleted: Bool = false
    @State private var showCompletionView: Bool = false
    @State private var referenceUIImage: UIImage?

    @Environment(\.modelContext) private var modelContext
    @Environment(MPCManager.self) private var mpc
    @Query private var images: [ImageModel]

    let col = 3
    let row = 2
    let size: CGFloat = 180

    // Pieces area configuration (right side)
    let piecesAreaCols = 2 // 2 columns for pieces area
    let piecesAreaSpacing: CGFloat = 24 // Spacing between pieces

    var piecesAreaRows: Int {
        (col * row + piecesAreaCols - 1) / piecesAreaCols // Ceiling division
    }

    var body: some View {
        GeometryReader { geo in
            ZStack {
                Color.viverePrimary
                    .ignoresSafeArea()

                HStack(spacing: 60) {
                    // Left side: Puzzle board
                    ZStack {
                        // Puzzle board background
                        RoundedRectangle(cornerRadius: 0)
                            .fill(Color.white)
                            .frame(width: size * CGFloat(col) + 40, height: size * CGFloat(row) + 40)
                            .overlay(
                                RoundedRectangle(cornerRadius: 0)
                                    .stroke(Color.black, lineWidth: 4)
                            )
                            .offset(x: -25, y: 0)

                        // Reference image (faded)
                        if let referenceImage = referenceUIImage {
                            Image(uiImage: referenceImage)
                                .resizable()
                                .frame(width: size * CGFloat(col), height: size * CGFloat(row))
                                .opacity(0.5)
                                .offset(x: -25, y: 0)
                        }
                    }
                    .frame(width: size * CGFloat(col) + 40, height: size * CGFloat(row) + 40)

                    // Right side: Pieces area placeholder (visual guide)
                    VStack(spacing: piecesAreaSpacing) {
                        ForEach(0..<piecesAreaRows, id: \.self) { r in
                            HStack(spacing: piecesAreaSpacing) {
                                ForEach(0..<piecesAreaCols, id: \.self) { c in
                                    // Empty placeholder
                                    Color.clear
                                        .frame(width: size, height: size)
                                }
                            }
                        }
                    }
                    .frame(width: CGFloat(piecesAreaCols) * size + CGFloat(piecesAreaCols - 1) * piecesAreaSpacing)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .padding(.horizontal, 60)
                .padding(.vertical, 40)

                // All puzzle pieces (positioned absolutely)
                ForEach($pieces) { $piece in
                    PuzzlePieceView(piece: $piece, size: size)
                }
            }
            .onAppear {
                Task {
                    await preparePuzzleIfNeeded(screenSize: geo.size)
                }
            }
            .onChange(of: pieces) {
                let completed = pieces.allSatisfy{$0.currPos == $0.correctPos}
                if completed && !isCompleted {
                    isCompleted = true
                    // Show completion view after a brief delay
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        showCompletionView = true
                    }
                }
            }
            .fullScreenCover(isPresented: $showCompletionView) {
                PuzzleCompletionView()
            }
        }
    }
    
    // Ensures we have a selected image and pieces prepared
    private func preparePuzzleIfNeeded(screenSize: CGSize) async {
        // If already prepared, skip
        if referenceUIImage != nil && !pieces.isEmpty { return }

        // Ensure Photos authorization
        let status = PHPhotoLibrary.authorizationStatus(for: .readWrite)
        if status == .notDetermined {
            _ = await PHPhotoLibrary.requestAuthorization(for: .readWrite)
        }
        guard PHPhotoLibrary.authorizationStatus(for: .readWrite) == .authorized ||
              PHPhotoLibrary.authorizationStatus(for: .readWrite) == .limited else {
            print("Photos access not granted.")
            return
        }

        // Pick a random ImageModel
        guard let randomItem = images.randomElement() else {
            print("No ImageModel items found in SwiftData.")
            return
        }

        // Resolve UIImage from Photos assetId
        if let uiImg = await loadUIImage(fromLocalIdentifier: randomItem.assetId) {
            // Normalize orientation once so cropping uses correctly oriented pixels
            let normalized = normalize(image: uiImg)
            referenceUIImage = normalized
            setupPuzzle(screenSize: screenSize, using: normalized)
            // Send to iPhone via MPC
            sendImageForInitialQuestion(normalized)
        } else {
            print("Failed to load UIImage for assetId: \(randomItem.assetId)")
        }
    }

    // Load UIImage from Photos using local identifier
    private func loadUIImage(fromLocalIdentifier id: String) async -> UIImage? {
        let assets = PHAsset.fetchAssets(withLocalIdentifiers: [id], options: nil)
        guard let asset = assets.firstObject else { return nil }

        let options = PHImageRequestOptions()
        options.version = .original
        options.isNetworkAccessAllowed = true
        options.deliveryMode = .highQualityFormat
        options.isSynchronous = false

        return await withCheckedContinuation { continuation in
            PHImageManager.default().requestImageDataAndOrientation(for: asset, options: options) { data, _, _, _ in
                if let data, let image = UIImage(data: data) {
                    continuation.resume(returning: image)
                } else {
                    continuation.resume(returning: nil)
                }
            }
        }
    }

    // Normalize UIImage orientation to .up so cgImage cropping is correct
    private func normalize(image: UIImage) -> UIImage {
        if image.imageOrientation == .up {
            return image
        }
        let format = UIGraphicsImageRendererFormat.default()
        format.scale = image.scale
        format.opaque = false
        let renderer = UIGraphicsImageRenderer(size: image.size, format: format)
        return renderer.image { _ in
            image.draw(in: CGRect(origin: .zero, size: image.size))
        }
    }

    // Setup puzzle with two-area layout: puzzle board on left, pieces area on right
    private func setupPuzzle(screenSize: CGSize, using uiImg: UIImage) {
        pieces.removeAll()
        let imgs = splitImageIntoPieces(img: uiImg, col: col, row: row)
        let dents = getPuzzleDent()

        // Calculate puzzle board position (left side)
        let puzzleBoardX = 60 + (size * CGFloat(col) + 40) / 2 // Left side center X
        let puzzleBoardY = screenSize.height / 2 // Center Y

        // Calculate pieces area position (right side)
        let piecesAreaX = screenSize.width - 60 - (CGFloat(piecesAreaCols) * size + CGFloat(piecesAreaCols - 1) * piecesAreaSpacing) / 2 // Right side center X
        let piecesAreaY = screenSize.height / 2 // Center Y
        let piecesAreaStartX = piecesAreaX - (CGFloat(piecesAreaCols) * size + CGFloat(piecesAreaCols - 1) * piecesAreaSpacing) / 2 + size / 2
        let piecesAreaStartY = piecesAreaY - (CGFloat(piecesAreaRows) * size + CGFloat(piecesAreaRows - 1) * piecesAreaSpacing) / 2 + size / 2

        // Shuffle pieces indices for random arrangement in pieces area
        var shuffledIndices = Array(0..<(col * row))
        shuffledIndices.shuffle()

        for (idx, originalIndex) in shuffledIndices.enumerated() {
            let r = originalIndex / col
            let c = originalIndex % col
            
            let xSizeCorrecttion = (CGFloat(dents[r * col + c][1]) * size * 0.2 - CGFloat(dents[r * col + c][3]) * size * 0.2)/2
            let ySizeCorrecttion = (CGFloat(dents[r * col + c][2]) * size * 0.2 - CGFloat(dents[r * col + c][0]) * size * 0.2)/2

            // Correct position (on puzzle board)
            let correctPos = CGPoint(
                x: (puzzleBoardX - size * CGFloat(col) / 2 + CGFloat(c) * size + size / 2) + xSizeCorrecttion,
                y: (puzzleBoardY - size * CGFloat(row) / 2 + CGFloat(r) * size + size / 2) + ySizeCorrecttion
            )

            // Current position (in pieces area, arranged in grid)
            let piecesAreaRow = idx / piecesAreaCols
            let piecesAreaCol = idx % piecesAreaCols
            let currPos = CGPoint(
                x: piecesAreaStartX + CGFloat(piecesAreaCol) * (size + piecesAreaSpacing),
                y: piecesAreaStartY + CGFloat(piecesAreaRow) * (size + piecesAreaSpacing)
            )

            let piece = PuzzlePiece(img: imgs[originalIndex], dents: dents[originalIndex], currPos: currPos, correctPos: correctPos)
            pieces.append(piece)
        }
    }

    private func splitImageIntoPieces(img: UIImage, col: Int, row: Int) -> [Image] {
        guard let cgImage = img.cgImage else { return [] }
        var imgs: [Image] = []
        let width = cgImage.width / col
        let height = cgImage.height / row
        let paths = getCropPath()
        let dents = getPuzzleDent()
        
        for r in 0..<row {
            for c in 0..<col {
                let path = paths[r * col + c]
                let dent = dents[r * col + c]
                
                let rect = CGRect(
                    x: c * width - Int(CGFloat(dent[3]) * CGFloat(width) * 0.2),
                    y: r * height - Int(CGFloat(dent[0]) * CGFloat(height) * 0.2),
                    width: width + Int(CGFloat(dent[1]) * CGFloat(width) * 0.2) + Int(CGFloat(dent[3]) * CGFloat(width) * 0.2),
                    height: height + Int(CGFloat(dent[2]) * CGFloat(height) * 0.2) + Int(CGFloat(dent[0]) * CGFloat(height) * 0.2)
                )
                
                if let croppedCGImage = cgImage.cropping(to: rect) {
                    let piece = UIImage(cgImage: croppedCGImage).crop(with: path)
                    
                    imgs.append(Image(uiImage: piece))
                }
            }
        }
        return imgs
    }

    // MARK: - MPC send
    private func sendImageForInitialQuestion(_ image: UIImage) {
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
