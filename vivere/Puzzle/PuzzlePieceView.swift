//
//  PuzzlePieceView.swift
//  vivere
//
//  Created by Reinhart on 05/11/25.
//

import SwiftUI

struct PuzzlePieceView: View {
    @Binding var piece: PuzzlePiece
    let size: CGFloat
    @GestureState var dragOffset: CGSize = .zero
    var body: some View {
        piece.img
            .resizable()
            .frame(width: size, height: size)
            .position(x: piece.currPos.x + dragOffset.width, y: piece.currPos.y + dragOffset.height)
            .gesture(
                DragGesture()
                    .updating($dragOffset) { value, state, _ in
                        state = value.translation
                    }
                    .onEnded { value in
                        piece.currPos.x += value.translation.width
                        piece.currPos.y += value.translation.height
                        checkIfCorrectPosition()
                    }
            )
    }
    
    func checkIfCorrectPosition() {
        if abs(piece.currPos.x - piece.correctPos.x) < size / 2 && abs(piece.currPos.y - piece.correctPos.y) < size / 2 {
            piece.currPos = piece.correctPos
        }
    }
}

//#Preview {
//    PuzzlePieceView()
//}
