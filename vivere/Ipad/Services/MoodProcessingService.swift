// MoodProcessingService.swift
import Foundation
import SwiftData

enum MoodProcessingError: Error {
    case noFeaturedModel
    case invalidEmotion
}

struct MoodProcessingService {
    // Update the featured model’s emotion using the string after "mood_"
    static func updateFeaturedModelEmotion(to value: String, in context: ModelContext) async throws {
        // Map string to Emotion enum
        guard let emotion = Emotion(rawValue: value.lowercased()) else {
            throw MoodProcessingError.invalidEmotion
        }

        // Get last featured model from the singleton (actor) asynchronously
        guard let featuredModel = await PhotosSelectionService.shared.getLastFeaturedModel() else {
            throw MoodProcessingError.noFeaturedModel
        }

        // Fetch the actual managed model instance from SwiftData context and update it
        let descriptor = FetchDescriptor<ImageModel>()
        if let items = try? context.fetch(descriptor),
           let managed = items.first(where: { $0.id == featuredModel.id }) {
            managed.emotion = emotion
            try? context.save()
        }
    }

    private static func awaitGetFeaturedModel() -> ImageModel? {
        var model: ImageModel?
        let semaphore = DispatchSemaphore(value: 0)
        Task {
            model = await PhotosSelectionService.shared.getLastFeaturedModel()
            semaphore.signal()
        }
        semaphore.wait()
        return model
    }

    private static func fetchImageModel(by id: UUID, in context: ModelContext) -> ImageModel? {
        let descriptor = FetchDescriptor<ImageModel>()
        if let items = try? context.fetch(descriptor) {
            return items.first(where: { $0.id == id })
        }
        return nil
    }
}
