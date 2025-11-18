//
//  PhotoDetailView.swift
//  vivere
//
//  Created by ChatGPT on 11/14/25.
//

import SwiftUI
import SwiftData
import Photos

struct PhotoDetailView: View {
    @Environment(\.dismiss) private var dismiss

    private let allImages: [ImageModel]

    @State private var activeImage: ImageModel
    @State private var displayedImage: UIImage?
    @State private var photoAuthorizationStatus: PHAuthorizationStatus = PHPhotoLibrary.authorizationStatus(for: .readWrite)

    init(imageModel: ImageModel, allImages: [ImageModel]) {
        _activeImage = State(initialValue: imageModel)
        self.allImages = allImages
    }

    private var contextText: String {
        let trimmed = activeImage.context?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        return trimmed.isEmpty ? "Belum ada cerita yang ditambahkan untuk foto ini." : trimmed
    }

    private var currentIndex: Int? {
        allImages.firstIndex { $0.id == activeImage.id }
    }

    private var canGoPrevious: Bool {
        guard let index = currentIndex else { return false }
        return index > 0
    }

    private var canGoNext: Bool {
        guard let index = currentIndex else { return false }
        return index < allImages.count - 1
    }

    var body: some View {
        ZStack {
            Color.viverePrimary
                .ignoresSafeArea()

            VStack(spacing: 48) {
                header
                content
                navigationButtons
            }
            .padding(.horizontal, 60)
            .padding(.vertical, 40)
        }
        .navigationBarBackButtonHidden(true)
        .toolbar(.hidden, for: .navigationBar)
        .task(id: activeImage.id) {
            await requestPhotoAuthorizationIfNeeded()
            await loadFullImage()
        }
    }

    private var header: some View {
        HStack {
            CustomIpadButton(color: .vivereSecondary) {
                dismiss()
            } label: {
                HStack(spacing: 12) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 22, weight: .semibold))
                    Text("Kembali")
                        .font(.system(size: 24, weight: .semibold))
                }
                .foregroundColor(.black)
                .padding(.horizontal, 12)
                .frame(height: 70)
            }
            .frame(width: 210)

            Spacer()

            CustomIpadButton(color: .accent) {
                // Placeholder for future menu actions
            } label: {
                Image(systemName: "ellipsis")
                    .font(.system(size: 34, weight: .bold))
                    .foregroundColor(.black)
                    .frame(width: 64, height: 64)
            }
            .frame(width: 90)
        }
    }

    private var content: some View {
        HStack(spacing: 40) {
            ZStack {
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .fill(Color.white)
                    .frame(width: 520, height: 500)
                    .shadow(color: Color.black.opacity(0.12), radius: 10, x: 0, y: 8)

                if let uiImage = displayedImage {
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 480, height: 420)
                        .clipped()
                        .cornerRadius(20)
                } else {
                    ProgressView()
                        .tint(.darkBlue)
                }
            }

            VStack(alignment: .leading, spacing: 20) {
                Text("Tentang Foto Ini")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(.white)

                ScrollView {
                    Text(contextText)
                        .font(.system(size: 20))
                        .foregroundColor(.white.opacity(0.9))
                        .multilineTextAlignment(.leading)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .frame(height: 320)
                .scrollIndicators(.hidden)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private var navigationButtons: some View {
        HStack {
            CustomIpadButton(color: .darkBlue, showDashedBorder: true) {
                goToPrevious()
            } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 34, weight: .bold))
                    .foregroundColor(.white)
                    .frame(width: 60, height: 60)
            }
            .opacity(canGoPrevious ? 1 : 0.4)
            .disabled(!canGoPrevious)

            Spacer()

            CustomIpadButton(color: .darkBlue, showDashedBorder: true) {
                goToNext()
            } label: {
                Image(systemName: "chevron.right")
                    .font(.system(size: 34, weight: .bold))
                    .foregroundColor(.white)
                    .frame(width: 60, height: 60)
            }
            .opacity(canGoNext ? 1 : 0.4)
            .disabled(!canGoNext)
        }
    }

    private func goToPrevious() {
        guard let index = currentIndex, index > 0 else { return }
        activeImage = allImages[index - 1]
    }

    private func goToNext() {
        guard let index = currentIndex, index < allImages.count - 1 else { return }
        activeImage = allImages[index + 1]
    }

    private func requestPhotoAuthorizationIfNeeded() async {
        let current = PHPhotoLibrary.authorizationStatus(for: .readWrite)
        if current == .notDetermined {
            let newStatus = await PHPhotoLibrary.requestAuthorization(for: .readWrite)
            await MainActor.run {
                photoAuthorizationStatus = newStatus
            }
        } else {
            await MainActor.run {
                photoAuthorizationStatus = current
            }
        }
    }

    private func loadFullImage() async {
        guard photoAuthorizationStatus == .authorized || photoAuthorizationStatus == .limited else { return }

        if let image = await fetchFullResolutionImage(for: activeImage.assetId) {
            await MainActor.run {
                displayedImage = image
            }
        }
    }

    private func fetchFullResolutionImage(for assetId: String) async -> UIImage? {
        let assets = PHAsset.fetchAssets(withLocalIdentifiers: [assetId], options: nil)
        guard let asset = assets.firstObject else { return nil }

        let options = PHImageRequestOptions()
        options.version = .original
        options.deliveryMode = .highQualityFormat
        options.isNetworkAccessAllowed = true

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
}


