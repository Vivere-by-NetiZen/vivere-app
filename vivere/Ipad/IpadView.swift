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
    @AppStorage("hasShownInstructionsAutomatically") private var hasShownInstructionsAutomatically: Bool = false
    @AppStorage("debugAlwaysShowInstructions") private var debugAlwaysShowInstructions: Bool = false
    @State private var hasShownInstructionsThisSession: Bool = false
    @Environment(\.modelContext) private var modelContext
    @Environment(\.scenePhase) private var scenePhase

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
        .onChange(of: scenePhase) { _, newPhase in
            if newPhase == .active {
                // Refresh monitoring when app comes to foreground
                if hasCompletedIpadOnboarding {
                    VideoDownloadService.shared.startMonitoringAll(modelContext: modelContext)

                    // Show instructions on app launch (first install or debug mode)
                    if !hasShownInstructionsThisSession {
                        if !hasShownInstructionsAutomatically || debugAlwaysShowInstructions {
                            NotificationCenter.default.post(name: .showInstructionsOnLaunch, object: nil)
                            hasShownInstructionsThisSession = true
                        }
                    }
                }
            } else if newPhase == .background || newPhase == .inactive {
                // Reset session flag when app goes to background so it shows again on next launch
                hasShownInstructionsThisSession = false
            }
        }
        .onAppear {
            // Show instructions on first app launch after onboarding
            if hasCompletedIpadOnboarding && !hasShownInstructionsThisSession {
                if !hasShownInstructionsAutomatically || debugAlwaysShowInstructions {
                    NotificationCenter.default.post(name: .showInstructionsOnLaunch, object: nil)
                    hasShownInstructionsThisSession = true
                }
            }
        }
    }
}

extension Notification.Name {
    static let didReachIpadHome = Notification.Name("didReachIpadHome")
}
