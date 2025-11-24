//
//  View+ConfettiCannon.swift
//  vivere
//
//  Created by Simon Bachmann on 24.11.20.
//

import SwiftUI

@available(iOS 14.0, macOS 11.0, watchOS 7, tvOS 14.0, *)
extension View {
    public func confettiCannon<T: Equatable>(
        trigger: Binding<T>,
        num: Int = 20,
        confettis: [ConfettiType] = ConfettiType.allCases,
        colors: [Color] = [.blue, .red, .green, .yellow, .pink, .purple, .orange],
        confettiSize: CGFloat = 10.0,
        rainHeight: CGFloat = 600.0,
        fadesOut: Bool = true,
        opacity: Double = 1.0,
        openingAngle: Angle = .degrees(60),
        closingAngle: Angle = .degrees(120),
        radius: CGFloat = 300,
        repetitions: Int = 1,
        repetitionInterval: Double = 1.0,
        hapticFeedback: Bool = true
    ) -> some View {
        self.overlay(
            ConfettiCannon(
                trigger: trigger,
                num: num,
                confettis: confettis,
                colors: colors,
                confettiSize: confettiSize,
                rainHeight: rainHeight,
                fadesOut: fadesOut,
                opacity: opacity,
                openingAngle: openingAngle,
                closingAngle: closingAngle,
                radius: radius,
                repetitions: repetitions,
                repetitionInterval: repetitionInterval,
                hapticFeedback: hapticFeedback
            )
        )
    }
}

