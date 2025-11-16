//
//  InputContextViewModel.swift
//  vivere
//
//  Created by Reinhart on 10/11/25.
//

import Foundation
import SwiftUI
import Combine
import PhotosUI
import UIKit

class InputContextViewModel: ObservableObject {
    @Published var currentImage: Image?
    @Published var currentContext: String?
    @Published var idx: Int = 0
    @Published var totalImgCount: Int = 0
    @Published var isUploading: Bool = false
    @Published var uploadProgress: Int = 0
    @Published var uploadError: String?

    var selectedImages: [Image] = []
    var selectedUIImage: [UIImage] = [] // Store UIImage for upload
    var imageIdentifiers: [String] = []
    var imageContexts: [String] = []
    var jobIds: [String?] = [] // Store job IDs for each image

    func loadImages(imagesIds: [String]) async {
        idx = 0
        imageIdentifiers = imagesIds
        totalImgCount = imagesIds.count
        imageContexts = Array(repeating: "", count: totalImgCount)
        jobIds = Array(repeating: nil, count: totalImgCount)
        selectedImages.removeAll()
        selectedUIImage.removeAll()

        let assets = PHAsset.fetchAssets(withLocalIdentifiers: imagesIds, options: nil)
        let imageManager = PHImageManager.default()
        let options = PHImageRequestOptions()
        options.version = .original
        options.isNetworkAccessAllowed = true
        options.deliveryMode = .opportunistic
        options.isSynchronous = false
        options.resizeMode = .none
        for i in 0..<totalImgCount {
            let asset = assets.object(at: i)
            if let imgWait = await withCheckedContinuation({ continuation in
                imageManager.requestImageDataAndOrientation(for: asset, options: options) { data, _, _, _ in
                    if let data, let image = UIImage(data: data) {
                        continuation.resume(returning: image)
                    }
                }
            }) {
                self.selectedImages.append(Image(uiImage: imgWait))
                self.selectedUIImage.append(imgWait)
            }
        }
        currentImage = selectedImages[idx]
        currentContext = imageContexts[idx]
    }

    func next(currContext: String) {
        imageContexts[idx] = currContext
        idx += 1
        currentImage = selectedImages[idx]
        currentContext = imageContexts[idx]
    }

    func previous(currContext: String) {
        imageContexts[idx] = currContext
        idx -= 1
        currentImage = selectedImages[idx]
        currentContext = imageContexts[idx]
    }

    func save(currContext: String) {
        imageContexts[idx] = currContext
    }

    /// Upload all images to backend for video generation (in parallel)
    /// Returns array of job IDs (one per image, nil if upload failed)
    /// Note: Backend queues jobs immediately and returns job_id - doesn't wait for video generation (~30 min)
    func uploadImagesForVideoGeneration() async -> [String?] {
        await MainActor.run {
            isUploading = true
            uploadProgress = 0
            uploadError = nil
        }

        var uploadedJobIds: [String?] = Array(repeating: nil, count: totalImgCount)
        let service = VideoGenerationService.shared

        // Upload all images in parallel for faster onboarding
        await withTaskGroup(of: (Int, String?).self) { group in
            for i in 0..<totalImgCount {
                guard i < selectedUIImage.count else {
                    continue
                }

                let image = selectedUIImage[i]
                let context = imageContexts[i]
                let index = i

                group.addTask {
                    do {
                        let response = try await service.generateVideo(from: image, context: context)
                        return (index, response.job_id)
                    } catch {
                        print("Failed to upload image \(index): \(error.localizedDescription)")
                        return (index, nil)
                    }
                }
            }

            // Collect results as they complete
            var completedCount = 0
            for await (index, jobId) in group {
                uploadedJobIds[index] = jobId
                completedCount += 1

                await MainActor.run {
                    uploadProgress = Int((Double(completedCount) / Double(totalImgCount)) * 100)
                    if jobId == nil && uploadError == nil {
                        uploadError = "Failed to upload image \(index + 1)"
                    }
                }
            }
        }

        await MainActor.run {
            jobIds = uploadedJobIds
            isUploading = false
        }

        return uploadedJobIds
    }
}
