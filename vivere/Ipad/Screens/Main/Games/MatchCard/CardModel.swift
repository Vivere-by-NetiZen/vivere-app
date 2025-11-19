//
//  CardModel.swift
//  vivere
//
//  Created by Reinhart on 06/11/25.
//

import Foundation
import SwiftUI

struct MatchCard: Identifiable, Equatable {
    var id: UUID = UUID()
    var imgName: String
    var img: UIImage
    var isFaceUp: Bool = false
    var isMatched: Bool = false
}
