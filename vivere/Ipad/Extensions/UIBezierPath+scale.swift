//
//  UIBezierPath+scale.swift
//  vivere
//
//  Created by Reinhart on 14/11/25.
//

import Foundation
import UIKit


extension UIBezierPath {
    func scaled(toFit targetSize: CGSize) -> UIBezierPath {
        let bounds = self.bounds
        
        // How much we need to stretch in each direction
        let scaleX = targetSize.width / bounds.width
        let scaleY = targetSize.height / bounds.height
        
        // 1. Move path to origin
        var transform = CGAffineTransform(translationX: -bounds.minX,
                                          y: -bounds.minY)
        // 2. Stretch horizontally & vertically
        transform = transform.scaledBy(x: scaleX, y: scaleY)
        
        let newPath = UIBezierPath(cgPath: self.cgPath)
        newPath.apply(transform)
        return newPath
        
    }
}








