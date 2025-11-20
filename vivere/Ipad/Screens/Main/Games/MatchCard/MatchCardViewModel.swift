//
//  MatchCardViewModel.swift
//  vivere
//
//  Created by Reinhart on 18/11/25.
//

import Foundation
import SwiftUI
import Combine
import Photos


class MatchCardViewModel: ObservableObject {
    @Published var cards: [MatchCard] = []
    @Published var completionImage: ImageModel?
    @Published var normalizedImage: UIImage?
    @Published var triggerSendToIphone: Bool = false
    @Published var lastMatchedImage: UIImage?
    
    var firstSelectedCard: Int?
    var images: [ImageModel] = []
    var selectedImageModels: [ImageModel] = []
    var selectedImages: [UIImage] = []
    
    
    func prepareCardsIfNeeded() async {
        // If already prepared, skip
        if normalizedImage != nil && !cards.isEmpty { return }
        
        selectedImageModels.removeAll()
        selectedImages.removeAll()
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
        
        guard images.count >= 3 else {
            print("ImageModel in SwiftData not enough.")
            return
        }
        
        // pick 3 random images
        selectedImageModels = Array(images.shuffled().prefix(3))
        
        for img in selectedImageModels {
            if let uiImg = await loadUIImage(fromLocalIdentifier: img.assetId) {
                let normalized = normalize(image: uiImg)
                selectedImages.append(normalized)
            } else {
                print("Failed to load UIImage for assetId: \(img.assetId)")
            }
        }
        
        let randomItem = selectedImageModels.randomElement()!
        if let uiImg = await loadUIImage(fromLocalIdentifier: randomItem.assetId) {
            // Normalize orientation once so cropping uses correctly oriented pixels
            let normalized = normalize(image: uiImg)
            setupCards()
            // Send to iPhone via MPC
            normalizedImage = normalized
            triggerSendToIphone = true
        } else {
            print("Failed to load UIImage for assetId: \(randomItem.assetId)")
        }
    }
    
    // Load UIImage from Photos using local identifier
    func loadUIImage(fromLocalIdentifier id: String) async -> UIImage? {
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
    func normalize(image: UIImage) -> UIImage {
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
    
    func setupCards() {
        cards.removeAll()
        
        var temp_cards: [MatchCard] = []
        for (idx, data) in selectedImageModels.enumerated() {
            temp_cards.append(MatchCard(imgName: data.assetId, img: selectedImages[idx]))
        }
        
        for item in temp_cards {
            temp_cards.append(MatchCard(imgName: item.imgName, img: item.img))
        }
        
        for item in temp_cards.shuffled() {
            cards.append(MatchCard(imgName: item.imgName, img: item.img))
        }
    }
    
    func flipCard(card: MatchCard) {
        guard let idx = cards.firstIndex(where: {$0.id == card.id}), !cards[idx].isMatched else { return }
        
        cards[idx].isFaceUp.toggle()
        
        if let firstSelectedCardIdx = firstSelectedCard {
            checkMatch(firstCardIdx: firstSelectedCardIdx, secondCardIdx: idx)
            self.firstSelectedCard = nil
        } else {
            self.firstSelectedCard = idx
        }
    }
    
    func checkMatch(firstCardIdx: Int, secondCardIdx: Int){
        if cards[firstCardIdx].imgName == cards[secondCardIdx].imgName {
            cards[firstCardIdx].isMatched = true
            cards[secondCardIdx].isMatched = true
            lastMatchedImage = cards[firstCardIdx].img
        } else {
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                self.cards[firstCardIdx].isFaceUp = false
                self.cards[secondCardIdx].isFaceUp = false
            }
        }
    }
}
