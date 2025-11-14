//
//  IpadView.swift
//  vivere
//
//  Created by Reinhart on 07/11/25.
//

import SwiftUI

struct IpadView: View {
    @State private var isLandscape: Bool = false
    @AppStorage("hasCompletedIpadOnboarding") private var hasCompletedIpadOnboarding: Bool = false

    var body: some View {
        ZStack {
            if hasCompletedIpadOnboarding {
                iPadHomeView()
                    .onAppear {
                        hasCompletedIpadOnboarding = true
                    }
            } else {
                OnboardingView()
            }

            if !isLandscape {
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
        // Mark onboarding as completed once the home screen is visible for the first time.
        .onChange(of: hasCompletedIpadOnboarding) { _, newValue in
            // no-op; kept to make intent explicit
        }
        .onReceive(NotificationCenter.default.publisher(for: .didReachIpadHome)) { _ in
            hasCompletedIpadOnboarding = true
        }
    }
}

extension Notification.Name {
    static let didReachIpadHome = Notification.Name("didReachIpadHome")
}
