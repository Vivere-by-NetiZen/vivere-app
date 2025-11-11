//
//  IphoneView.swift
//  vivere
//
//  Created by Reinhart on 07/11/25.
//

import SwiftUI

struct IphoneView: View {
    @State private var router = Router()
    @Bindable var mpc: MPCManager
    
    var body: some View {
        NavigationStack(path: $router.path) {
            HomeView(mpc: mpc)
                .navigationDestination(for: Route.self) { route in
                    switch route {
                    case .home:
                        HomeView(mpc: mpc)
                    case .transcribe:
                        SpeechTranscriberView()
                    }
                }
        }
        .environment(router)
    }
}

//#Preview {
//    IphoneView()
//}
