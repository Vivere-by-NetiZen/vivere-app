//
//  RoundedCross.swift
//  vivere
//
//  Created by Simon Bachmann on 24.11.20.
//

import SwiftUI

struct RoundedCross: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let width = rect.width
        let height = rect.height
        let cornerRadius: CGFloat = min(width, height) * 0.2

        // Horizontal bar
        path.addRoundedRect(
            in: CGRect(
                x: rect.minX,
                y: center.y - height * 0.15,
                width: width,
                height: height * 0.3
            ),
            cornerSize: CGSize(width: cornerRadius, height: cornerRadius)
        )

        // Vertical bar
        path.addRoundedRect(
            in: CGRect(
                x: center.x - width * 0.15,
                y: rect.minY,
                width: width * 0.3,
                height: height
            ),
            cornerSize: CGSize(width: cornerRadius, height: cornerRadius)
        )

        return path
    }
}

