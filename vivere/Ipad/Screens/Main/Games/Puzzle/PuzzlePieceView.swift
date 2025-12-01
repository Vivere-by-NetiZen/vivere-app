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
    let dentScale: CGFloat
    var trayScale: CGFloat = 0.6 // Default tray scale
    var onDragStart: () -> Void = {}

    @GestureState var dragOffset: CGSize = .zero
    @GestureState var isDragging: Bool = false

    @State private var rotation: Double = 0
    @State private var previousDragTranslation: CGSize = .zero
    @State private var resetRotationTask: DispatchWorkItem?

    var body: some View {
        piece.img
            .resizable()
            .frame(width: (size + CGFloat(piece.dents[1]) * size * dentScale + CGFloat(piece.dents[3]) * size * dentScale), height: size + CGFloat(piece.dents[0]) * size * dentScale + CGFloat(piece.dents[2]) * size * dentScale)
            // Scale logic: If in tray, use trayScale. If dragging or moved out, use 1.0 (true scale).
            // Also apply lift effect (1.1) when dragging.
            .scaleEffect((piece.isInTray ? trayScale : 1.0) * (isDragging ? 1.1 : 1.0))
            .rotationEffect(.degrees(rotation))
            .shadow(radius: isDragging ? 10 : 0)
            .position(x: piece.currPos.x + dragOffset.width, y: piece.currPos.y + dragOffset.height)
            .zIndex(isDragging ? 100 : piece.zIndex)
            .gesture(
                // Only allow dragging if not locked
                piece.isLocked ? nil : DragGesture()
                    .updating($isDragging) { _, state, _ in
                        state = true
                    }
                    .updating($dragOffset) { value, state, _ in
                        if state == .zero {
                            // Initial drag start
                            DispatchQueue.main.async {
                                onDragStart()
                            }
                        }
                        state = value.translation
                    }
                    .onChanged { value in
                        // Calculate delta for physics-like rotation
                        let delta = value.translation.width - previousDragTranslation.width
                        previousDragTranslation = value.translation

                        let targetRotation = -delta * 0.5
                        withAnimation(.interactiveSpring(response: 0.3, dampingFraction: 0.5)) {
                            rotation = targetRotation
                        }

                        // Reset rotation when movement stops (decay)
                        resetRotationTask?.cancel()
                        let task = DispatchWorkItem {
                            withAnimation(.spring(response: 0.4, dampingFraction: 0.6)) {
                                rotation = 0
                            }
                        }
                        resetRotationTask = task
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1, execute: task)
                    }
                    .onEnded { value in
                        piece.currPos.x += value.translation.width
                        piece.currPos.y += value.translation.height
                        checkIfCorrectPosition()

                        // Reset physics state
                        previousDragTranslation = .zero
                        withAnimation(.spring()) {
                            rotation = 0
                        }
                    }
            )
            .animation(.spring(), value: isDragging)
    }

    func checkIfCorrectPosition() {
        // Increased snapping threshold from size/2 to size*0.8 for easier snapping
        if abs(piece.currPos.x - piece.correctPos.x) < size * 0.8 && abs(piece.currPos.y - piece.correctPos.y) < size * 0.8 {
            piece.currPos = piece.correctPos
            piece.isLocked = true
        }
    }
}

//#Preview {
//    PuzzlePieceView()
//}
