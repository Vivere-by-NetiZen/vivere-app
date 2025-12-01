//
//  SlimRectangle.swift
//  vivere
//
//  Created by Simon Bachmann on 24.11.20.
//

import SwiftUI

struct SlimRectangle: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.addRoundedRect(in: rect, cornerSize: CGSize(width: 2, height: 2))
        return path
    }
}

