//
//  DebugMenuView.swift
//  vivere
//
//  Created for debug purposes
//

import SwiftUI

struct DebugMenuView: View {
    @AppStorage("debugSkipDeviceConnection") private var skipDeviceConnection: Bool = false

    var body: some View {
        Menu {
            Toggle("Skip Device Connection", isOn: $skipDeviceConnection)

            Divider()

            Button(action: {
                NotificationCenter.default.post(name: .navigateToHome, object: nil)
            }) {
                Label("Go to Home", systemImage: "house.fill")
            }
        } label: {
            Image(systemName: "ladybug.fill")
                .font(.title3)
                .foregroundColor(.white)
                .frame(width: 44, height: 44)
                .background(
                    Circle()
                        .fill(Color.black.opacity(0.7))
                )
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomLeading)
        .padding(20)
    }
}

extension Notification.Name {
    static let navigateToHome = Notification.Name("navigateToHome")
}

#Preview {
    ZStack {
        Color.viverePrimary.ignoresSafeArea()
        DebugMenuView()
    }
}

