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
    @State var isMatchedImageShown: Bool = false
    @State var isExitConfirmationShown: Bool = false
    
    @Environment(MPCManager.self) private var mpc
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Query private var images: [ImageModel]
    
    let col = 3
    
    var body: some View {
        ZStack {
            Color.viverePrimary
                .ignoresSafeArea(.all)
            
            VStack {
                HStack {
                    Image(systemName: "chevron.left")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(.black)
                        .padding()
                        .background(Color.white)
                        .clipShape(Circle())
                        .onTapGesture {
                            isExitConfirmationShown = true
                        }
                        .padding(40)
                    Spacer()
                    Text("Cocokkan 2 kartu dengan gambar yang sama")
                        .font(Font.largeTitle)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                    Spacer()
                    Image(systemName: "questionmark.circle")
                        .font(.system(size: 50))
                        .fontWeight(.semibold)
                        .foregroundColor(.accent)
                        .onTapGesture {
                            isTutorialShown = true
                        }
                        .padding(40)
                }
                .frame(maxWidth: .infinity)
                
                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: col)) {
                    ForEach(viewModel.cards) { card in
                        CardView(card: card)
                            .onTapGesture {
                                viewModel.flipCard(card: card)
                            }
                    }
                }.frame(maxWidth: 260*3 + 10*2) // card width + space in between
                
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            
            ZStack {
                if isMatchedImageShown {
                    ZStack {
                        Color.black.opacity(0.4)
                            .ignoresSafeArea(.all)
                        if let lastMatchedImage = viewModel.lastMatchedImage {
                            Image(uiImage: lastMatchedImage)
                                .resizable()
                                .scaledToFit()
                                .padding(40)
                                .frame(maxWidth: .infinity, maxHeight: .infinity)
                                .background(Color.white)
                                .cornerRadius(20)
                                .padding(80)
                        }
                    }
                    .transition(.asymmetric(insertion: .move(edge: .bottom), removal: .move(edge: .bottom)))
                    .onTapGesture {
                        withAnimation(.easeInOut(duration: 0.5)) {
                            isMatchedImageShown = false
                        }
                    }
                }

            }
                        
            if isTutorialShown {
                MatchCardTutorialSheetView(isPresented: $isTutorialShown)
            }
            
            if isExitConfirmationShown {
                ExitGameConfirmationView(isPresented: $isExitConfirmationShown)
            }
            
        }
        .onAppear {
            Task {
                viewModel.images = self.images
                await viewModel.prepareCardsIfNeeded()
            }
        }
        .onChange(of: viewModel.lastMatchedImage) {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                withAnimation(.easeInOut(duration: 0.5)) {
                    isMatchedImageShown = true
                }
            }
        }
        .onChange(of: isMatchedImageShown) {
            let completed = viewModel.cards.allSatisfy{$0.isMatched == true}
            if completed && !isCompleted && !isMatchedImageShown {
                isCompleted = true
                // Show completion view after a brief delay
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    showCompletionView = true
                }
            }
        }
        .onChange(of: viewModel.lastMatchedImage) {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                withAnimation(.easeInOut(duration: 0.5)) {
                    isMatchedImageShown = true
                }
            }
        }
        .navigationBarBackButtonHidden(true)
        .fullScreenCover(isPresented: $showCompletionView) {
            CompletionView(imageModel: viewModel.completionImage)
        }
    }
    
}

//#Preview {
//    MatchCardView()
//}
