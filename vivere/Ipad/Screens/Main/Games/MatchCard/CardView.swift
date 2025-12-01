//
//  CardView.swift
//  vivere
//
//  Created by Reinhart on 06/11/25.
//

import SwiftUI

struct CardView: View {
    var card: MatchCard
    
    var body: some View {
        ZStack {
            if card.isFaceUp || card.isMatched {
                Image(uiImage: card.img)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 240, height: 270)
                    .cornerRadius(20)
                    .padding()
                    .background(Color.white)
                    .padding()
                    .frame(width: 260, height: 290)
                    .cornerRadius(20)
            } else {
                if let uiImg = UIImage(named: "cardBack") {
                    Image(uiImage: uiImg)
                        .frame(width: 260, height: 290)
                        .cornerRadius(20)
                }
            }
        }
        .rotation3DEffect(
            .degrees(card.isFaceUp ? 0 : 180),
            axis: (x: 0, y: 1, z: 0)
        )
        .animation(.linear(duration: 0.35), value: card.isFaceUp)
    }
}

//#Preview {
//    CardView()
//}
