//
//  UIImage+resize.swift
//  vivere
//
//  Created by Assistant on 24/11/25.
//

import UIKit

extension UIImage {
    /// Resize image to max dimension while maintaining aspect ratio
    func resized(toMaxDimension maxDimension: CGFloat) -> UIImage {
        let width = size.width
        let height = size.height

        // If image is smaller than max dimension, return original
        if width <= maxDimension && height <= maxDimension {
            return self
        }

        let aspectRatio = width / height
        var newWidth: CGFloat
        var newHeight: CGFloat

        if width > height {
            newWidth = maxDimension
            newHeight = maxDimension / aspectRatio
        } else {
            newHeight = maxDimension
            newWidth = maxDimension * aspectRatio
        }

        let newSize = CGSize(width: newWidth, height: newHeight)

        let renderer = UIGraphicsImageRenderer(size: newSize)
        return renderer.image { _ in
            self.draw(in: CGRect(origin: .zero, size: newSize))
        }
    }
}

