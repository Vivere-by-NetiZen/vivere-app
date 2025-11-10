//
//  CardModel.swift
//  vivere
//
//  Created by Reinhart on 06/11/25.
//

import Foundation

struct MatchCard: Identifiable, Equatable {
    var id: UUID = UUID()
    var imgName: String
    var isFaceUp: Bool = false
    var isMatched: Bool = false
}
