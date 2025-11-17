//
//  ImageModel.swift
//  vivere
//
//  Created by Reinhart on 09/11/25.
//

import Foundation
import SwiftData


enum Emotion: String, Codable {
    case sad, neutral, happy
}

@Model
class ImageModel : Identifiable {
    var id: UUID
    var assetId: String
    var context: String?
    var jobId: String? // ComfyUI job ID for video generation
    var emotion: Emotion

    init(id: UUID = UUID(), assetId: String, context: String? = nil, jobId: String? = nil, emotion: Emotion = .neutral) {
        self.id = id
        self.assetId = assetId
        self.context = context
        self.jobId = jobId
        self.emotion = emotion
    }
}
