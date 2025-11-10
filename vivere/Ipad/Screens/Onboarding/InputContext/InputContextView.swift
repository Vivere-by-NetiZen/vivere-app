//
//  InputContextView.swift
//  vivere
//
//  Created by Reinhart on 10/11/25.
//

import SwiftUI

struct InputContextView: View {
    let imgId: [String]
    
    var body: some View {
        ZStack {
            Color.viverePrimary.ignoresSafeArea(edges: .all)
            
            VStack {
                HStack {
                    Image("progressStepper1")
                    Line()
                        .stroke(style: StrokeStyle(lineWidth: 4, dash: [15]))
                        .frame(height: 1)
                    Image("progressStepper2")
                    Line()
                        .stroke(style: StrokeStyle(lineWidth: 4, dash: [15]))
                        .frame(height: 1)
                    Image("progressStepper3")
                }
                .frame(maxWidth: 400)
                .padding()
                
                Text("WIP!")
                    .font(.largeTitle)
                    .fontWeight(.black)
            }
        }
        .navigationBarBackButtonHidden(true)
//        .navigationDestination(isPresented: $isPaired) {
//            MediaCollectionView()
//        }
    }
}

//#Preview {
//    InputContextView()
//}
