//
//  PairDeviceView.swift
//  vivere
//
//  Created by Reinhart on 09/11/25.
//

import SwiftUI

struct PairDeviceView: View {
    @Binding var isNextPressed: Bool
    @Binding var isPaired: Bool
    
    var body: some View {
        ZStack {
            Color.black.opacity(0.4)
                .ignoresSafeArea(.all)
                .onTapGesture {_ in
                    isNextPressed = false
                }
            VStack {
                Text("Pair Device Screen Placeholder")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .padding()
                    .background(Color.white)
                    .cornerRadius(20)
                    .padding()
                    .foregroundColor(.black)
                    
                Button("Lanjutkan") {
                    isPaired = true
                }
                .font(Font.title2)
                .fontWeight(.semibold)
                .cornerRadius(10)
                .buttonStyle(.borderedProminent)
            }
        }
    }
}

#Preview {
    @Previewable @State var isNextPressed: Bool = false
    @Previewable @State var isPaired: Bool = false
    PairDeviceView(isNextPressed: $isNextPressed, isPaired: $isPaired)
}
