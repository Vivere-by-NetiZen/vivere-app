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
    @Published var normalizedImage: UIImage?
    @Published var triggerSendToIphone: Bool = false

    var firstSelectedCard: Int?
    var images: [ImageModel] = []
    var selectedImageModels: [ImageModel] = []
    var selectedImages: [UIImage] = []

    func prepareCardsIfNeeded() async {
        // If already prepared, skip
        if normalizedImage != nil && !cards.isEmpty { return }

        // Require at least 3 images for the match game
        guard images.count >= 3 else {
            print("ImageModel in SwiftData not enough.")
            return
        }

        // Ask the singleton to pick 3 images and choose a featured one among them
        guard let result = await PhotosSelectionService.shared.pickImages(from: images, count: 3) else {
            return
        }

        // Save the chosen set for building cards
        selectedImageModels = result.selectedModels
        selectedImages = result.selectedImages

        // Build the cards
        setupCards()

        // Use the featured image as normalizedImage (if you still need to trigger sending, keep the flag)
        normalizedImage = result.featuredImage
        triggerSendToIphone = true
    }

    func setupCards() {
        cards.removeAll()

        var temp_cards: [MatchCard] = []
        for (idx, data) in selectedImageModels.enumerated() {
            temp_cards.append(MatchCard(imgName: data.assetId, img: selectedImages[idx]))
        }

        for item in temp_cards {
            cards.append(MatchCard(imgName: item.imgName, img: item.img))
            cards.append(MatchCard(imgName: item.imgName, img: item.img))
        }
    }

    func flipCard(card: MatchCard) {
        // BUG: after first match
        // TODO: add flip animation
        guard let idx = cards.firstIndex(where: { $0.id == card.id }), !cards[idx].isMatched else { return }

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
        } else {
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                self.cards[firstCardIdx].isFaceUp = false
                self.cards[secondCardIdx].isFaceUp = false
            }
        }
    }
}

