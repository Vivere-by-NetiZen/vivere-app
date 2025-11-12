//
//  IphoneView.swift
//  vivere
//
//  Created by Reinhart on 07/11/25.
//

import SwiftUI

struct IphoneView: View {
    @State private var router = Router()
    
    var body: some View {
        NavigationStack(path: $router.path) {
            HomeView()
                .navigationDestination(for: Route.self) { route in
                    switch route {
                    case .home:
                        HomeView()
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
