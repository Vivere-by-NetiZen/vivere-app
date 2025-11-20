//
//  MatchCardView.swift
//  vivere
//
//  Created by Reinhart on 06/11/25.
//

import SwiftUI
import SwiftData

struct MatchCardView: View {
    @StateObject private var viewModel = MatchCardViewModel()
    
    @State private var isCompleted: Bool = false
    @State var showCompletionView: Bool = false
    @State var isTutorialShown: Bool = false
    
    @Environment(MPCManager.self) private var mpc
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Query private var images: [ImageModel]
    
    let col = 3
    
    var body: some View {
        VStack {
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: col)) {
                ForEach(viewModel.cards) { card in
                    CardView(card: card)
                        .onTapGesture {
                            viewModel.flipCard(card: card)
                        }
                }
            }
        }
        .onAppear {
            Task {
                viewModel.images = self.images
                await viewModel.prepareCardsIfNeeded()
            }
            mpc.send(message: "warm up")
        }
    }
}

//#Preview {
//    MatchCardView()
//}
