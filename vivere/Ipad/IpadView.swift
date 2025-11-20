//
//  IpadView.swift
//  vivere
//
//  Created by Reinhart on 07/11/25.
//

import SwiftUI
import SwiftData

struct IpadView: View {
    @State private var isLandscape: Bool = false
    @AppStorage("hasCompletedIpadOnboarding") private var hasCompletedIpadOnboarding: Bool = false
    @Environment(\.modelContext) private var modelContext

    var body: some View {
        ZStack {
            if hasCompletedIpadOnboarding {
                iPadHomeView()
                    .onAppear {
                        hasCompletedIpadOnboarding = true
                        VideoDownloadService.shared.startMonitoringAll(modelContext: modelContext)
                    }
            } else {
                OnboardingView()
            }

            if !isLandscape {
                Color.viverePrimary.ignoresSafeArea(.all)
                Text("Please use landscape mode")
                    .font(Font.largeTitle.bold())
            }

            DebugMenuView()
                .zIndex(1000)
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
