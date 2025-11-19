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
    var operationIds: [String?] = [] // Store operation IDs for each image

    func loadImages(imagesIds: [String]) async {
        idx = 0
        imageIdentifiers.removeAll()
        selectedImages.removeAll()
        selectedUIImage.removeAll()
        imageContexts.removeAll()
        operationIds.removeAll()

        let assets = PHAsset.fetchAssets(withLocalIdentifiers: imagesIds, options: nil)
        let imageManager = PHImageManager.default()
        let options = PHImageRequestOptions()
        options.version = .original
        options.isNetworkAccessAllowed = true
        options.deliveryMode = .opportunistic
        options.isSynchronous = false
        options.resizeMode = .none

        for i in 0..<imagesIds.count {
            let assetId = imagesIds[i]
            let asset = assets.object(at: i)
            let loadStartTime = CFAbsoluteTimeGetCurrent()
            if let imgWait = await withCheckedContinuation({ continuation in
                imageManager.requestImageDataAndOrientation(for: asset, options: options) { data, _, _, _ in
                    if let data, let image = UIImage(data: data) {
                        continuation.resume(returning: image)
                    } else {
                        continuation.resume(returning: nil)
                    }
                }
            }) {
                let loadDuration = CFAbsoluteTimeGetCurrent() - loadStartTime
                #if DEBUG
                let imageSizeMB = Double(imgWait.size.width * imgWait.size.height * 4) / (1024 * 1024) // Rough estimate
                print("📷 Loaded image \(i + 1): \(String(format: "%.0f", imgWait.size.width))x\(String(format: "%.0f", imgWait.size.height)) (~\(String(format: "%.2f", imageSizeMB)) MB) in \(String(format: "%.3f", loadDuration))s")
                #endif
                // Only append to arrays if image loaded successfully
                self.imageIdentifiers.append(assetId)
                self.selectedImages.append(Image(uiImage: imgWait))
                self.selectedUIImage.append(imgWait)
                self.imageContexts.append("")
                self.operationIds.append(nil)
            }
        }

        // Update total count based on successfully loaded images
        totalImgCount = selectedImages.count

        // Only set current image if we have images loaded
        if !selectedImages.isEmpty && idx < selectedImages.count {
            currentImage = selectedImages[idx]
            currentContext = imageContexts[idx]
        } else {
            currentImage = nil
            currentContext = nil
        }
    }

    func next(currContext: String) {
        guard idx < imageContexts.count else { return }
        imageContexts[idx] = currContext
        idx += 1
        guard idx < selectedImages.count && idx < imageContexts.count else { return }
        currentImage = selectedImages[idx]
        currentContext = imageContexts[idx]
    }

    func previous(currContext: String) {
        guard idx < imageContexts.count else { return }
        imageContexts[idx] = currContext
        idx -= 1
        guard idx >= 0 && idx < selectedImages.count && idx < imageContexts.count else { return }
        currentImage = selectedImages[idx]
        currentContext = imageContexts[idx]
    }

    func save(currContext: String) {
        guard idx < imageContexts.count else { return }
        imageContexts[idx] = currContext
    }

    /// Upload all images to backend for video generation (in parallel)
    /// Returns array of operation IDs (one per image, nil if upload failed)
    /// Note: Backend queues jobs immediately and returns operation_id - doesn't wait for video generation (~30 min)
    func uploadImagesForVideoGeneration() async -> [String?] {
        let uploadStartTime = CFAbsoluteTimeGetCurrent()
        await MainActor.run {
            isUploading = true
            uploadProgress = 0
            uploadError = nil
        }

        var uploadedOperationIds: [String?] = Array(repeating: nil, count: totalImgCount)
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
                let totalCount = totalImgCount

                group.addTask {
                    let uploadStartTime = CFAbsoluteTimeGetCurrent()
                    do {
                        #if DEBUG
                        print("📤 Starting upload for image \(index + 1)/\(totalCount)...")
                        #endif
                        let response = try await service.generateVideo(from: image, context: context)
                        let uploadDuration = CFAbsoluteTimeGetCurrent() - uploadStartTime
                        #if DEBUG
                        print("✅ Successfully uploaded image \(index + 1)/\(totalCount) in \(String(format: "%.3f", uploadDuration))s. Operation ID: \(response.operationId)")
                        #endif
                        return (index, response.operationId)
                    } catch {
                        let uploadDuration = CFAbsoluteTimeGetCurrent() - uploadStartTime
                        #if DEBUG
                        print("❌ Failed to upload image \(index + 1) after \(String(format: "%.3f", uploadDuration))s: \(error.localizedDescription)")
                        #endif
                        return (index, nil)
                    }
                }
            }

            // Collect results as they complete
            var completedCount = 0
            var successCount = 0
            for await (index, operationId) in group {
                uploadedOperationIds[index] = operationId
                completedCount += 1
                if operationId != nil {
                    successCount += 1
                }

                await MainActor.run {
                    uploadProgress = Int((Double(completedCount) / Double(totalImgCount)) * 100)
                    if operationId == nil && uploadError == nil {
                        uploadError = "Failed to upload image \(index + 1)"
                    }
                }
            }

            let totalUploadDuration = CFAbsoluteTimeGetCurrent() - uploadStartTime
            #if DEBUG
            print("📊 Upload complete: \(successCount)/\(totalImgCount) images uploaded successfully in \(String(format: "%.3f", totalUploadDuration))s")
            #endif
        }

        await MainActor.run {
            operationIds = uploadedOperationIds
            isUploading = false
            let totalDuration = CFAbsoluteTimeGetCurrent() - uploadStartTime
            #if DEBUG
            print("✅ All uploads finished in \(String(format: "%.3f", totalDuration))s. Proceeding to save and navigate...")
            #endif
        }

        return uploadedOperationIds
    }
}
