//
//  PuzzleView.swift
//  vivere
//
//  Created by Reinhart on 05/11/25.
//

import SwiftUI

struct PuzzleView: View {
    @State private var pieces: [PuzzlePiece] = []
    @State private var isCompleted: Bool = false
    
    let col = 3
    let row = 2
    let size: CGFloat = 300
    
    var body: some View {
        GeometryReader { geo in
            VStack {
                Button("Shuffle") {
                    let puzzleAreaWidth = size * CGFloat(col)
                    let puzzleAreaHeight = size * CGFloat(row)
                    let minX = (geo.size.width - puzzleAreaWidth) / 2
                    let minY = (geo.size.height - puzzleAreaHeight) / 2
                    for i in pieces.indices {
                        pieces[i].currPos = CGPoint(x: CGFloat.random(in: minX...(minX + puzzleAreaWidth - size)), y: CGFloat.random(in: minY...(minY + puzzleAreaHeight - size)))
                    }
                }
                ZStack {
                    if let referenceImage = UIImage(named: "puzzleImage") {
                        Image(uiImage: referenceImage)
                            .resizable()
                            .frame(width: size * CGFloat(col), height: size * CGFloat(row))
                            .opacity(0.2)
                            .position(x: geo.size.width / 2, y: geo.size.height / 2)
                    }
                    ForEach($pieces) {$piece in
                        PuzzlePieceView(piece: $piece, size: size)
                            .offset(x: geo.size.width / 2 - size * CGFloat(col) / 2, y: geo.size.height / 2 - size * CGFloat(row) / 2)
                    }
                }
                .onAppear {
                    setupPuzzle(screenSize: geo.size)
                }
                .onChange(of: pieces) {
                    isCompleted = pieces.allSatisfy{$0.currPos == $0.correctPos} ? true : false
                }
                .alert(isPresented: $isCompleted) {
                    Alert(title: Text("Completed!"), message: Text("done"), dismissButton: .default(Text("OK")))
                }
            }
        }
    }
    
    func setupPuzzle(screenSize: CGSize) {
        guard let uiImg = UIImage(named: "puzzleImage") else { return }
        let imgs = splitImageIntoPieces(img: uiImg, col: col, row: row)
        let puzzleAreaWidth = size * CGFloat(col)
        let puzzleAreaHeight = size * CGFloat(row)
        let minX = (screenSize.width - puzzleAreaWidth) / 2
        let minY = (screenSize.height - puzzleAreaHeight) / 2
        for r in 0..<row {
            for c in 0..<col {
                let correctPos = CGPoint(x: CGFloat(c) * size + size / 2, y: CGFloat(r) * size + size / 2)
                let currPos = CGPoint(x: CGFloat.random(in: minX...(minX + puzzleAreaWidth - size)), y: CGFloat.random(in: minY...(minY + puzzleAreaHeight - size)))
                let piece = PuzzlePiece(img: imgs[r * col + c], currPos: currPos, correctPos: correctPos)
                pieces.append(piece)
            }
        }
    }
    
    func splitImageIntoPieces(img: UIImage, col: Int, row: Int) -> [Image] {
        guard let cgImage = img.cgImage else { return [] }
        var imgs: [Image] = []
        let width = cgImage.width / col
        let height = cgImage.height / row
        
        for r in 0..<row {
            for c in 0..<col {
                let rect = CGRect(
                    x: c * width,
                    y: r * height,
                    width: width,
                    height: height
                )
                                
                if let croppedCGImage = cgImage.cropping(to: rect) {
                    let piece = UIImage(cgImage: croppedCGImage)
                    imgs.append(Image(uiImage: piece))
                }
            }
        }
        return imgs
    }
}

//#Preview {
//    PuzzleView()
//}
