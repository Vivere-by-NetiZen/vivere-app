//
//  Router.swift
//  vivere
//
//  Created by Ahmed Nizhan Haikal on 10/11/25.
//

import Foundation
import SwiftUI
import UIKit

@Observable
final class Router {
    var path = NavigationPath()
    
    func goToTranscribe() {
        path.append(Route.transcribe)
    }
    
    func pop() {
        path.removeLast(1)
    }
    
    func popToRoot() {
        path.removeLast(path.count)
    }
}
