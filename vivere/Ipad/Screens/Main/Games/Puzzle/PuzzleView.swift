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
    @State private var referenceUIImage: UIImage?

    @Environment(\.modelContext) private var modelContext
    @Environment(MPCManager.self) private var mpc
    @Query private var images: [ImageModel]

    let col = 3
    let row = 2
    let size: CGFloat = 300

    var body: some View {
        GeometryReader { geo in
            VStack {
                Button("Shuffle") {
                    let puzzleAreaWidth = size * CGFloat(col)
                    let puzzleAreaHeight = size * CGFloat(row)
                    let minX = (geo.size.width - puzzleAreaWidth) / 2
                    let minY = (geo.size.height - puzzleAreaHeight) / 2
                    for i in pieces.indices {
                        pieces[i].currPos = CGPoint(
                            x: CGFloat.random(in: minX...(minX + puzzleAreaWidth - size)),
                            y: CGFloat.random(in: minY...(minY + puzzleAreaHeight - size))
                        )
                    }
                }
                ZStack {
                    if let referenceImage = referenceUIImage {
                        Image(uiImage: referenceImage)
                            .resizable()
                            .frame(width: size * CGFloat(col), height: size * CGFloat(row))
                            .opacity(0.2)
                            .position(x: geo.size.width / 2, y: geo.size.height / 2)
                    }
                    ForEach($pieces) { $piece in
                        PuzzlePieceView(piece: $piece, size: size)
                            .offset(
                                x: geo.size.width / 2 - size * CGFloat(col) / 2,
                                y: geo.size.height / 2 - size * CGFloat(row) / 2
                            )
                    }
                }
                .onAppear {
                    Task {
                        await preparePuzzleIfNeeded(screenSize: geo.size)
                    }
                }
                .onChange(of: pieces) {
                    isCompleted = pieces.allSatisfy { $0.currPos == $0.correctPos }
                }
                .alert(isPresented: $isCompleted) {
                    Alert(
                        title: Text("Completed!"),
                        message: Text("done"),
                        dismissButton: .default(Text("OK")) {
                            // Send a simple command to iPhone to switch to SpeechTranscriberView
                            mpc.send(message: "show_transcriber")
                        }
                    )
                }
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

    // Slightly adjusted to take a UIImage instead of loading by name
    private func setupPuzzle(screenSize: CGSize, using uiImg: UIImage) {
        pieces.removeAll()

        let imgs = splitImageIntoPieces(img: uiImg, col: col, row: row)
        let puzzleAreaWidth = size * CGFloat(col)
        let puzzleAreaHeight = size * CGFloat(row)
        let minX = (screenSize.width - puzzleAreaWidth) / 2
        let minY = (screenSize.height - puzzleAreaHeight) / 2
        for r in 0..<row {
            for c in 0..<col {
                let correctPos = CGPoint(x: CGFloat(c) * size + size / 2, y: CGFloat(r) * size + size / 2)
                let currPos = CGPoint(
                    x: CGFloat.random(in: minX...(minX + puzzleAreaWidth - size)),
                    y: CGFloat.random(in: minY...(minY + puzzleAreaHeight - size))
                )
                let piece = PuzzlePiece(img: imgs[r * col + c], currPos: currPos, correctPos: correctPos)
                pieces.append(piece)
            }
        }
    }

    private func splitImageIntoPieces(img: UIImage, col: Int, row: Int) -> [Image] {
        guard let cgImage = img.cgImage else { return [] }
        var imgs: [Image] = []
        let width = cgImage.width / col
        let height = cgImage.height / row

        for r in 0..<row {
            for c in 0..<col {
                let rect = CGRect(
                    x: c * width,
                    y: r * height,
                    width: width,
                    height: height
                )

                if let croppedCGImage = cgImage.cropping(to: rect) {
                    let piece = UIImage(cgImage: croppedCGImage, scale: img.scale, orientation: .up)
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
