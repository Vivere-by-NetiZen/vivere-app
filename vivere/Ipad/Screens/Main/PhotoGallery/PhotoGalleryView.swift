//
//  PhotoGalleryView.swift
//  vivere
//
//  Created by ChatGPT on 11/14/25.
//

import SwiftUI
import SwiftData
import Photos

struct PhotoGalleryView: View {
    @Environment(\.dismiss) private var dismiss
    @Namespace private var zoomNamespace
    @Query private var images: [ImageModel]
    @State private var showMediaCollection = false

    private let columns = [GridItem](repeating: GridItem(.flexible(), spacing: 32), count: 4)
    private let gridSpacing: CGFloat = 32

    var body: some View {
        VStack(spacing: 40) {
            header

            if images.isEmpty {
                emptyState
            } else {
                ScrollView(showsIndicators: false) {
                    LazyVGrid(columns: columns, spacing: gridSpacing) {
                        ForEach(images) { image in
                            NavigationLink(value: image.id) {
                                PhotoThumbnailView(imageModel: image)
                                    .matchedTransitionSource(id: image.id, in: zoomNamespace)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.vertical, 32)
                }
            }
        }
        .padding(.vertical, 48)
        .padding(.horizontal, 40)
        .background(Color.viverePrimary.ignoresSafeArea())
        .navigationDestination(for: UUID.self) { id in
            if let model = images.first(where: { $0.id == id }) {
                PhotoDetailView(imageModel: model, allImages: images)
                    .navigationTransition(.zoom(sourceID: id, in: zoomNamespace))
            }
        }
        .navigationDestination(isPresented: $showMediaCollection) {
            MediaCollectionView()
        }
        .navigationBarBackButtonHidden(true)
        .toolbar(.hidden, for: .navigationBar)
    }

    private var header: some View {
        HStack(spacing: 40) {
            CustomIpadButton(color: .vivereSecondary) {
                dismiss()
            } label: {
                HStack(spacing: 12) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 22, weight: .semibold))
                    Text("Kembali")
                        .font(.system(size: 22, weight: .semibold))
                }
                .foregroundColor(.black)
                .padding(.horizontal, 40)
                .frame(height: 70)
            }

            Spacer()

            Text("Kumpulan Kenangan")
                .font(.system(size: 34, weight: .semibold))
                .foregroundColor(.white)

            Spacer()

            CustomIpadButton(color: .accent) {
                showMediaCollection = true
            } label: {
                HStack(spacing: 12) {
                    Image(systemName: "plus")
                        .font(.system(size: 28, weight: .bold))
                    Text("Tambahkan Foto")
                        .font(.system(size: 22, weight: .semibold))
                }
                .foregroundColor(.black)
                .padding(.horizontal, 40)
                .frame(height: 70)
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "photo.on.rectangle.angled")
                .font(.system(size: 64))
                .foregroundColor(.white.opacity(0.7))
            Text("Belum ada foto yang tersimpan.")
                .font(.system(size: 24, weight: .semibold))
                .foregroundColor(.white)
            Text("Tambahkan foto melalui proses onboarding atau gunakan fitur pengelolaan foto pada perangkatmu.")
                .font(.system(size: 18))
                .foregroundColor(.white.opacity(0.85))
                .multilineTextAlignment(.center)
                .frame(maxWidth: 400)
        }
        .frame(maxHeight: .infinity)
    }
}

// Simple thumbnail view component
struct PhotoThumbnailView: View {
    let imageModel: ImageModel
    @State private var thumbnail: UIImage?
    @Environment(\.displayScale) private var displayScale

    var body: some View {
        GeometryReader { geometry in
            let size = geometry.size.width

            ZStack {
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .strokeBorder(.white, lineWidth: 10)

                if let thumbnail {
                    Image(uiImage: thumbnail)
                        .resizable()
                        .scaledToFill()
                        .frame(width: size - 20, height: size - 20)
                        .clipped()
                        .cornerRadius(18)
                } else {
                    ProgressView()
                        .tint(.darkBlue)
                }
            }
            .frame(width: size, height: size * 1.05)
        }
        .aspectRatio(1, contentMode: .fit)
        .task {
            await loadThumbnail()
        }
    }

    private func loadThumbnail() async {
        guard thumbnail == nil else { return }
        guard PHPhotoLibrary.authorizationStatus(for: .readWrite) == .authorized ||
              PHPhotoLibrary.authorizationStatus(for: .readWrite) == .limited else { return }

        let scale = max(displayScale, 1)
        let targetSize = CGSize(width: 200 * scale, height: 200 * scale)

        let assets = PHAsset.fetchAssets(withLocalIdentifiers: [imageModel.assetId], options: nil)
        guard let asset = assets.firstObject else { return }

        let options = PHImageRequestOptions()
        options.deliveryMode = .opportunistic
        options.resizeMode = .fast
        options.isNetworkAccessAllowed = true

        let image = await withCheckedContinuation { continuation in
            PHImageManager.default().requestImage(
                for: asset,
                targetSize: targetSize,
                contentMode: .aspectFill,
                options: options
            ) { image, _ in
                continuation.resume(returning: image)
            }
        }

        await MainActor.run {
            thumbnail = image
        }
    }
}

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: ImageModel.self, configurations: config)

    return PhotoGalleryView()
        .modelContainer(container)
}

