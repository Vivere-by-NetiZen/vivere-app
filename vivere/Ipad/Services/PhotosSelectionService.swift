import Foundation
import UIKit
import Photos

struct PhotosSelectionResult {
    let selectedModels: [ImageModel]
    let selectedImages: [UIImage]
    let featuredModel: ImageModel
    let featuredImage: UIImage
}

// Actor singleton to keep last selection safely across threads.
actor PhotosSelectionService {
    static let shared = PhotosSelectionService()

    // Stored state for last selection
    private(set) var lastSelectedModels: [ImageModel] = []
    private(set) var lastSelectedImages: [UIImage] = []
    private(set) var lastFeaturedModel: ImageModel?
    private(set) var lastFeaturedImage: UIImage?

    private init() {}

    // Public entry point used by both VMs
    func pickImages(from allModels: [ImageModel], count: Int) async -> PhotosSelectionResult? {
        // Ensure authorization
        guard await ensureAuthorization() else {
            print("Photos access not granted.")
            return nil
        }

        guard !allModels.isEmpty else {
            print("No ImageModel items found in SwiftData.")
            return nil
        }

        // Choose N models uniformly (or as many as available)
        let chosenModels = Array(allModels.shuffled().prefix(max(1, count)))
        var images: [UIImage] = []
        images.reserveCapacity(chosenModels.count)

        for model in chosenModels {
            if let uiImg = await loadUIImage(fromLocalIdentifier: model.assetId) {
                images.append(normalize(image: uiImg))
            } else {
                print("Failed to load UIImage for assetId: \(model.assetId)")
                return nil
            }
        }

        // Pick a featured one from the chosen set using emotion weights
        guard let featuredIndex = weightedIndex(in: chosenModels) else { return nil }
        let featuredModel = chosenModels[featuredIndex]
        let featuredImage = images[featuredIndex]
        print("picked image")

        let result = PhotosSelectionResult(
            selectedModels: chosenModels,
            selectedImages: images,
            featuredModel: featuredModel,
            featuredImage: featuredImage
        )

        // Persist last selection inside the singleton
        self.lastSelectedModels = chosenModels
        self.lastSelectedImages = images
        self.lastFeaturedModel = featuredModel
        self.lastFeaturedImage = featuredImage

        return result
    }

    // Convenience async getters for other parts of the app
    func getLastSelection() -> PhotosSelectionResult? {
        guard let featuredModel = lastFeaturedModel,
              let featuredImage = lastFeaturedImage else {
            return nil
        }
        return PhotosSelectionResult(
            selectedModels: lastSelectedModels,
            selectedImages: lastSelectedImages,
            featuredModel: featuredModel,
            featuredImage: featuredImage
        )
    }

    func getLastFeaturedModel() -> ImageModel? {
        lastFeaturedModel
    }

    func getLastFeaturedImage() -> UIImage? {
        lastFeaturedImage
    }

    // MARK: - Helpers

    private func ensureAuthorization() async -> Bool {
        let status = PHPhotoLibrary.authorizationStatus(for: .readWrite)
        if status == .notDetermined {
            _ = await PHPhotoLibrary.requestAuthorization(for: .readWrite)
        }
        let final = PHPhotoLibrary.authorizationStatus(for: .readWrite)
        return final == .authorized || final == .limited
    }

    private func loadUIImage(fromLocalIdentifier id: String) async -> UIImage? {
        let assets = PHAsset.fetchAssets(withLocalIdentifiers: [id], options: nil)
        guard let asset = assets.firstObject else { return nil }

        let options = PHImageRequestOptions()
        options.version = .original
        options.isNetworkAccessAllowed = true
        options.deliveryMode = .highQualityFormat
        options.isSynchronous = false

        return await withCheckedContinuation { continuation in
            PHImageManager.default().requestImageDataAndOrientation(for: asset, options: options) { data, _, _, _ in
                if let data, let image = UIImage(data: data) {
                    continuation.resume(returning: image)
                } else {
                    continuation.resume(returning: nil)
                }
            }
        }
    }

    private func normalize(image: UIImage) -> UIImage {
        if image.imageOrientation == .up { return image }
        let format = UIGraphicsImageRendererFormat.default()
        format.scale = image.scale
        format.opaque = false
        let renderer = UIGraphicsImageRenderer(size: image.size, format: format)
        return renderer.image { _ in
            image.draw(in: CGRect(origin: .zero, size: image.size))
        }
    }

    // MARK: - Emotion weighting (for featured selection)

    // Tune these weights as you like (happy > neutral > sad)
    private func weight(for emotion: Emotion) -> Int {
        switch emotion {
        case .happy: return 10
        case .neutral: return 3
        case .sad: return 1
        }
    }

    // Returns an index into models chosen by weights. Nil if empty or all weights zero.
    private func weightedIndex(in models: [ImageModel]) -> Int? {
        guard !models.isEmpty else { return nil }
        let weights = models.map { weight(for: $0.emotion) }
        let total = weights.reduce(0, +)
        guard total > 0 else { return nil }

        var pick = Int.random(in: 1...total)
        for (idx, w) in weights.enumerated() {
            pick -= w
            if pick <= 0 { return idx }
        }
        // Fallback (should not happen)
        return models.indices.randomElement()
    }
}
