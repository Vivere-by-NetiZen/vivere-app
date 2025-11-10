//
//  HomeView.swift
//  vivere
//
//  Created by Ahmed Nizhan Haikal on 10/11/25.
//

import Foundation
import SwiftUI

struct HomeView: View {
    var body: some View {
        VStack (alignment: .center) {
            Image("Logo")
                .resizable()
                .frame(width: 117, height: 117)
                .padding(.bottom, 22)
            Text("Hai! ini Vivere mu")
                .font(.title)
                .foregroundStyle(Color.white)
                .padding(.bottom, 3)
            Text("Ciptakan obrolan bermakna dengan lansia bersama Vivere!")
                .font(.callout)
                .multilineTextAlignment(.center)
                .foregroundStyle(Color.white)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .ignoresSafeArea()
        .background(Color.viverePrimary)
    }
}

#Preview {
    HomeView()
}
