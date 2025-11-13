//
//  ReminiscenceTherapyView.swift
//  vivere
//
//  Created by Imo Madjid on 11/12/25.
//

import Foundation
import SwiftUI

struct ReminiscenceTherapyView: View {
    var body: some View {
        ZStack {
            // Frame image centered
            Image("frame")
                .resizable()
                .scaledToFit()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .padding()
                .shadow(radius: 10, y: 10)
        }
        .navigationBarBackButtonHidden(true)
        .background(.viverePrimary)
    }
}

#Preview {
    ReminiscenceTherapyView()
}
