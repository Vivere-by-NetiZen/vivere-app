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
    var dents: [Int]
    var currPos: CGPoint
    var correctPos: CGPoint
    var zIndex: Double = 0
    var isLocked: Bool = false
    var isInTray: Bool = true
}

func getPuzzleDent() -> [[Int]]{
    // top right bottom left
    var dents: [[Int]] = []

    let topLeft = [0, 1, 1, 0]
    dents.append(topLeft)

    let topMid = [0, 0, 0, 0]
    dents.append(topMid)

    let topRight = [0, 0, 1, 1]
    dents.append(topRight)

    let bottomLeft = [0, 0, 0, 0]
    dents.append(bottomLeft)

    let bottomMid = [1, 1, 0, 1]
    dents.append(bottomMid)

    let bottomRight = [0, 0, 0, 0]
    dents.append(bottomRight)

    return dents
}
