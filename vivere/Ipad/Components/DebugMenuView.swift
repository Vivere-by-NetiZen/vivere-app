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
        } label: {
            Image(systemName: "ladybug.fill")
                .font(.system(size: 24))
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

#Preview {
    ZStack {
        Color.viverePrimary.ignoresSafeArea()
        DebugMenuView()
    }
}

