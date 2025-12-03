//
//  InputContextViewModel.swift
//  vivere
//
//  Created by Reinhart on 10/11/25.
//

import Foundation
import SwiftUI
import PhotosUI
import UIKit
import SwiftData

@Observable
@MainActor
class InputContextViewModel {
    var currentImage: Image?
    var currentContext: String?
    var idx: Int = 0
    var totalImgCount: Int = 0
    var isUploading: Bool = false
    var uploadProgress: Int = 0
    var uploadError: String?

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

        for assetId in imagesIds {
            // Find the specific asset for this ID
            var targetAsset: PHAsset?
            assets.enumerateObjects { asset, _, stop in
                if asset.localIdentifier == assetId {
                    targetAsset = asset
                    stop.pointee = true
                }
            }

            guard let asset = targetAsset else {
                print("⚠️ Could not find asset for ID: \(assetId)")
                continue
            }

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
                print("📷 Loaded image for \(assetId): \(String(format: "%.0f", imgWait.size.width))x\(String(format: "%.0f", imgWait.size.height)) (~\(String(format: "%.2f", imageSizeMB)) MB) in \(String(format: "%.3f", loadDuration))s")
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
    /// Note: Backend queues jobs immediately and returns operation_id - doesn't wait for video generation (~1-2 min)
    func uploadImagesForVideoGeneration() async -> [String?] {
        // Request background execution time to ensure uploads complete even if app is backgrounded
        var backgroundTaskID: UIBackgroundTaskIdentifier = .invalid
        backgroundTaskID = UIApplication.shared.beginBackgroundTask {
            // End the task if time expires.
            UIApplication.shared.endBackgroundTask(backgroundTaskID)
            backgroundTaskID = .invalid
        }

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

        // End background task
        if backgroundTaskID != .invalid {
            UIApplication.shared.endBackgroundTask(backgroundTaskID)
            backgroundTaskID = .invalid
        }

        return uploadedOperationIds
    }

    // MARK: - Save and Upload

    func saveAndUpload(modelContext: ModelContext, completion: @escaping () -> Void) {
        // 1. Prepare local data copy to avoid actor isolation issues
        let assetIds = self.imageIdentifiers
        let contexts = self.imageContexts
        let totalCount = self.totalImgCount

        Task {
            // 2. Save/Upsert to SwiftData on MainActor
            await MainActor.run {
                #if DEBUG
                print("💾 Saving \(totalCount) images to database immediately...")
                #endif

                // Fetch all existing images to check for duplicates
                let descriptor = FetchDescriptor<ImageModel>()
                let existingImages = (try? modelContext.fetch(descriptor)) ?? []

                for i in 0..<totalCount {
                    let assetId = assetIds[i]
                    let context = contexts[i]

                    // Find all existing models with this assetId
                    let matches = existingImages.filter { $0.assetId == assetId }

                    if let existingModel = matches.first {
                        // Update the first match
                        existingModel.context = context
                        existingModel.operationId = "PENDING_UPLOAD" // Mark as pending to prevent duplicate uploads
                        #if DEBUG
                        print("🔄 Updating existing model for asset: \(assetId)")
                        #endif

                        // Remove any duplicates found
                        for duplicate in matches.dropFirst() {
                            modelContext.delete(duplicate)
                            #if DEBUG
                            print("🗑️ Removing duplicate model for asset: \(assetId)")
                            #endif
                        }
                    } else {
                        // Insert new model if none exists
                        let imgData = ImageModel(
                            assetId: assetId,
                            context: context,
                            operationId: "PENDING_UPLOAD" // Mark as pending to prevent duplicate uploads
                        )
                        modelContext.insert(imgData)
                    }
                }
                try? modelContext.save()

                #if DEBUG
                print("✅ Images saved/updated. Navigating to next screen immediately...")
                #endif

                // Execute completion (navigation) immediately
                completion()
            }

            // 3. Start background upload
            await self.startBackgroundUpload(modelContext: modelContext, assetIds: assetIds)
        }
    }

    private func startBackgroundUpload(modelContext: ModelContext, assetIds: [String]) async {
        // Use Task.detached or just continue in the background
        #if DEBUG
        print("🚀 Starting background upload process for \(assetIds.count) images...")
        #endif

        let operationIds = await self.uploadImagesForVideoGeneration()

        // Update database with operation IDs
        await MainActor.run {
            #if DEBUG
            print("💾 Updating database with operation IDs...")
            #endif

            let descriptor = FetchDescriptor<ImageModel>()
            if let images = try? modelContext.fetch(descriptor) {
                for i in 0..<min(assetIds.count, operationIds.count) {
                    let assetId = assetIds[i]
                    // Update specific asset
                    if let imageModel = images.first(where: { $0.assetId == assetId }) {
                        let opId = operationIds[i]
                        imageModel.operationId = opId

                        // Start monitoring immediately for this operation ID if valid
                        if let opId = opId {
                            VideoDownloadService.shared.startMonitoring(operationId: opId)
                            #if DEBUG
                            print("👀 Started immediate monitoring for operation: \(opId)")
                            #endif
                        }
                    }
                }
                try? modelContext.save()

                #if DEBUG
                print("✅ Background upload complete. Operation IDs updated in database.")
                #endif
            }
        }
    }
}
