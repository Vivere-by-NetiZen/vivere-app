//
//  UIImage+crop.swift
//  vivere
//
//  Created by Reinhart on 14/11/25.
//

import Foundation
import UIKit


extension UIImage {
    var pixelSize: CGSize {
        CGSize(width: size.width * scale, height: size.height * scale)
    }
    
    func crop(with path: UIBezierPath) -> UIImage {
        let pixelSize = self.pixelSize
        
        // Important: create a renderer *in pixel space*
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1   // Do NOT downscale!
        format.opaque = false
        
        let renderer = UIGraphicsImageRenderer(size: pixelSize, format: format)
        
        let scaledPath = path.scaled(toFit: pixelSize)
        
        return renderer.image { ctx in
            scaledPath.addClip()
            self.draw(in: CGRect(origin: .zero, size: pixelSize))
        }
        
    }
    
}
