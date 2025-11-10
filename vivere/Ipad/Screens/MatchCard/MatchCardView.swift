//
//  MatchCardView.swift
//  vivere
//
//  Created by Reinhart on 06/11/25.
//

import SwiftUI

struct MatchCardView: View {
    @State private var cards: [MatchCard] = []
    @State private var isCompleted: Bool = false
    @State private var firstSelectedCard: Int?
    
    let col = 3
    
    var body: some View {
        VStack {
            Button("Restart"){
                setupCards()
            }
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: col)) {
                ForEach(cards) { card in
                    CardView(card: card)
                        .onTapGesture {
                            flipCard(card: card)
                        }
                }
            }
        }
        .onAppear {
            setupCards()
        }
    }
    
    func setupCards() {
        cards = []
        let images = ["card1", "card2", "card3"]
        let shuffled = (images + images).shuffled()
        
        cards = shuffled.map { MatchCard(imgName: $0, isFaceUp: false, isMatched: false) }
    }
    
    func flipCard(card: MatchCard) {
        //BUG: after first match
        //TODO: add flip animation
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
        } else {
            cards[firstCardIdx].isFaceUp = false
            cards[secondCardIdx].isFaceUp = false
        }
    }
}

//#Preview {
//    MatchCardView()
//}
