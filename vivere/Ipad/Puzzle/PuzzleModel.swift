//
//  PuzzleModel.swift
//  vivere
//
//  Created by Reinhart on 05/11/25.
//

import Foundation
import SwiftUI

struct PuzzlePiece: Identifiable, Equatable {
    var id = UUID()
    var img: Image
    var currPos: CGPoint
    var correctPos: CGPoint
}
