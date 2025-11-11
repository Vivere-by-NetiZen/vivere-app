//
//  ImageModel.swift
//  vivere
//
//  Created by Reinhart on 09/11/25.
//

import Foundation


struct ImageModel : Codable {
    var id = UUID()
    let url: String
    var context: String?
}
