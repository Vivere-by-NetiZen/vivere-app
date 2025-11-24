//
//  Color+tint.swift
//  vivere
//
//  Created by Reinhart on 09/11/25.
//

import Foundation
import SwiftUI


extension Color {
    func tint(_ opacity: Double = 0.3) -> Color {
        Color(
            red:   Double(self.resolve(in: .init()).red) * (1 - opacity),
            green: Double(self.resolve(in: .init()).green) * (1 - opacity),
            blue:  Double(self.resolve(in: .init()).blue) * (1 - opacity)
        )
    }
}
