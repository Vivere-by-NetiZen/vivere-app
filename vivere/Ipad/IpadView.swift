//
//  IpadView.swift
//  vivere
//
//  Created by Reinhart on 07/11/25.
//

import SwiftUI

struct IpadView: View {
    @State private var isLandscape: Bool = false
//    @Bindable var mpc: MPCManager
    
    var body: some View {
        ZStack {
            OnboardingView()
            if !isLandscape{
                Color.viverePrimary.ignoresSafeArea(.all)
                Text("Please use landscape mode")
                    .font(Font.largeTitle.bold())
            }
        }
        .background {
            GeometryReader { geo in
                Color.clear
                    .onChange(of: geo.size) {
                        isLandscape = geo.size.height < geo.size.width
                    }
                    .onAppear {
                        isLandscape = geo.size.height < geo.size.width
                    }
            }
        }
    }
}
