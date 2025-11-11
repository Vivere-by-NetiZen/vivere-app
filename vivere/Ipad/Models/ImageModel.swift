//
//  ImageModel.swift
//  vivere
//
//  Created by Reinhart on 09/11/25.
//

import Foundation
import SwiftData


@Model
class ImageModel : Identifiable {
    var id: UUID
    var assetId: String
    var context: String?
    
    init(id: UUID = UUID(), assetId: String, context: String? = nil) {
        self.id = id
        self.assetId = assetId
        self.context = context
    }
}
