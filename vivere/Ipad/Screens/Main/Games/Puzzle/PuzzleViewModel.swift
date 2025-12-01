//
//  PuzzleViewModel.swift
//  vivere
//
//  Created by Reinhart on 18/11/25.
//

import Foundation
import SwiftUI
import SwiftData
import Combine
import Photos

class PuzzleViewModel: ObservableObject {
    @Published var pieces: [PuzzlePiece] = []
    @Published var normalizedImage: UIImage?
    @Published var triggerSendToIphone: Bool = false
    @Published var selectedImageModel: ImageModel?

    let col = 3
    let row = 2
    let piecesAreaCols = 2 // 2 columns for pieces area
    let piecesAreaSpacing: CGFloat = 24 // Spacing between pieces
    let dentScale: CGFloat = 0.2 // Centralized dent scale
    let trayScale: CGFloat = 0.6 // Scale for pieces in the tray

    @Published var size: CGFloat = 180 // Will be calculated dynamically
    @Published var boardCenter: CGPoint = .zero
    @Published var piecesAreaCenter: CGPoint = .zero

    var images: [ImageModel] = []

    var piecesAreaRows: Int {
        (col * row + piecesAreaCols - 1) / piecesAreaCols // Ceiling division
    }

    // Ensures we have a selected image and pieces prepared
    func preparePuzzleIfNeeded(screenSize: CGSize) async {
        // If already prepared, skip
        if normalizedImage != nil && !pieces.isEmpty { return }

        // Fast path: use prefetch cache if available
        if let cached = await PhotosSelectionService.shared.getLastSelection() {
            selectedImageModel = cached.featuredModel
            setupPuzzle(screenSize: screenSize, using: cached.featuredImage)
            normalizedImage = cached.featuredImage
            ReminiscenceTherapyViewModel.shared.getInitialQuestion(image: cached.featuredImage)
            triggerSendToIphone = true
            return
        }

        // Fallback: pick now (previous behavior)
        guard let result = await PhotosSelectionService.shared.pickImages(from: images, count: 1) else {
            return
        }

        selectedImageModel = result.featuredModel
        setupPuzzle(screenSize: screenSize, using: result.featuredImage)
        normalizedImage = result.featuredImage
        ReminiscenceTherapyViewModel.shared.getInitialQuestion(image: result.featuredImage)
        triggerSendToIphone = true
    }

    // Setup puzzle with two-area layout: puzzle board on left, pieces area on right
    func setupPuzzle(screenSize: CGSize, using uiImg: UIImage) {
        pieces.removeAll()

        // Dynamic Size Calculation: Fit puzzle into the left 70% of the screen (Increased from 60%)
        // This makes the placeholder image larger.
        let availableWidth = screenSize.width * 0.65 - 40
        let availableHeight = screenSize.height - 80
        let maxW = availableWidth / CGFloat(col)
        let maxH = availableHeight / CGFloat(row)
        self.size = min(maxW, maxH)

        // Crop image to match puzzle aspect ratio (object-cover behavior)
        let targetRatio = CGFloat(col) / CGFloat(row)
        let croppedImg = cropImage(uiImg, toAspectRatio: targetRatio)
        self.normalizedImage = croppedImg

        let imgs = splitImageIntoPieces(img: croppedImg, col: col, row: row)
        let dents = getPuzzleDent()

        // Calculate puzzle board position (left side)
        // Center the board in the left section
        let puzzleBoardCenterX = screenSize.width * 0.35 // Center of left 70%
        let puzzleBoardCenterY = screenSize.height / 2

        self.boardCenter = CGPoint(x: puzzleBoardCenterX, y: puzzleBoardCenterY)

        // Calculate pieces area position (right side)
        // The tray is now narrower (30% of screen), so pieces need to be smaller.
        let piecesAreaCenterX = screenSize.width * 0.85 // Center of right 30%
        let piecesAreaCenterY = screenSize.height / 2

        self.piecesAreaCenter = CGPoint(x: piecesAreaCenterX, y: piecesAreaCenterY)

        // Use scaled size for tray calculation
        let trayPieceSize = size * trayScale
        let traySpacing = piecesAreaSpacing * trayScale

        let piecesAreaTotalWidth = CGFloat(piecesAreaCols) * trayPieceSize + CGFloat(piecesAreaCols - 1) * traySpacing
        let piecesAreaTotalHeight = CGFloat(piecesAreaRows) * trayPieceSize + CGFloat(piecesAreaRows - 1) * traySpacing

        let piecesAreaStartX = piecesAreaCenterX - piecesAreaTotalWidth / 2 + trayPieceSize / 2
        let piecesAreaStartY = piecesAreaCenterY - piecesAreaTotalHeight / 2 + trayPieceSize / 2

        // Shuffle pieces indices for random arrangement in pieces area
        var shuffledIndices = Array(0..<(col * row))
        shuffledIndices.shuffle()

        for (idx, originalIndex) in shuffledIndices.enumerated() {
            let r = originalIndex / col
            let c = originalIndex % col

            let xSizeCorrecttion = (CGFloat(dents[r * col + c][1]) * size * dentScale - CGFloat(dents[r * col + c][3]) * size * dentScale)/2
            let ySizeCorrecttion = (CGFloat(dents[r * col + c][2]) * size * dentScale - CGFloat(dents[r * col + c][0]) * size * dentScale)/2

            // Correct position (on puzzle board)
            let correctPos = CGPoint(
                x: (puzzleBoardCenterX - size * CGFloat(col) / 2 + CGFloat(c) * size + size / 2) + xSizeCorrecttion,
                y: (puzzleBoardCenterY - size * CGFloat(row) / 2 + CGFloat(r) * size + size / 2) + ySizeCorrecttion
            )

            // Current position (in pieces area, arranged in grid using scaled sizes)
            let piecesAreaRow = idx / piecesAreaCols
            let piecesAreaCol = idx % piecesAreaCols
            let currPos = CGPoint(
                x: piecesAreaStartX + CGFloat(piecesAreaCol) * (trayPieceSize + traySpacing),
                y: piecesAreaStartY + CGFloat(piecesAreaRow) * (trayPieceSize + traySpacing)
            )

            let piece = PuzzlePiece(img: imgs[originalIndex], dents: dents[originalIndex], currPos: currPos, correctPos: correctPos, isInTray: true)
            pieces.append(piece)
        }
    }

    // Use this to update zIndex so the tapped/dragged piece moves to front
    func markPieceAsActive(_ pieceID: UUID) {
        guard let index = pieces.firstIndex(where: { $0.id == pieceID }) else { return }

        // Mark as out of tray
        if pieces[index].isInTray {
             withAnimation(.spring(response: 0.4, dampingFraction: 0.6)) {
                 pieces[index].isInTray = false
             }
        }

        // Find current max zIndex
        let maxZ = pieces.map(\.zIndex).max() ?? 0
        // Assign a new higher zIndex
        pieces[index].zIndex = maxZ + 1
    }

    func splitImageIntoPieces(img: UIImage, col: Int, row: Int) -> [Image] {
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
                    x: c * width - Int(CGFloat(dent[3]) * CGFloat(width) * dentScale),
                    y: r * height - Int(CGFloat(dent[0]) * CGFloat(height) * dentScale),
                    width: width + Int(CGFloat(dent[1]) * CGFloat(width) * dentScale) + Int(CGFloat(dent[3]) * CGFloat(width) * dentScale),
                    height: height + Int(CGFloat(dent[2]) * CGFloat(height) * dentScale) + Int(CGFloat(dent[0]) * CGFloat(height) * dentScale)
                )

                if let croppedCGImage = cgImage.cropping(to: rect) {
                    let piece = UIImage(cgImage: croppedCGImage).crop(with: path)

                    imgs.append(Image(uiImage: piece))
                }
            }
        }
        return imgs
    }

    private func cropImage(_ image: UIImage, toAspectRatio ratio: CGFloat) -> UIImage {
        let width = image.size.width
        let height = image.size.height
        let currentRatio = width / height

        var newWidth: CGFloat
        var newHeight: CGFloat

        if currentRatio > ratio {
            // Wider than target
            newHeight = height
            newWidth = height * ratio
        } else {
            // Taller than target
            newWidth = width
            newHeight = width / ratio
        }

        let renderer = UIGraphicsImageRenderer(size: CGSize(width: newWidth, height: newHeight))
        return renderer.image { _ in
            // Draw centered
            let x = (newWidth - width) / 2
            let y = (newHeight - height) / 2
            image.draw(in: CGRect(x: x, y: y, width: width, height: height))
        }
    }
}

