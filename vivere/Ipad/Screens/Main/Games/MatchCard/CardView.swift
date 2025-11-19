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
                    .border(Color.white)
                    .frame(width: 180, height: 320)
                    .cornerRadius(10)
            } else {
                if let uiImg = UIImage(named: "cardBack") {
                    Image(uiImage: uiImg)
                        .frame(width: 180, height: 320)
                        .cornerRadius(10)
                }
            }
        }
    }
}

//#Preview {
//    CardView()
//}
