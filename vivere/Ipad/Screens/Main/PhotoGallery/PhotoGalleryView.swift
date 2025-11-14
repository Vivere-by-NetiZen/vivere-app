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
    @Environment(\.displayScale) private var displayScale
    @Query private var images: [ImageModel]

    @State private var thumbnails: [UUID: UIImage] = [:]
    @State private var photoAuthorizationStatus: PHAuthorizationStatus = PHPhotoLibrary.authorizationStatus(for: .readWrite)
    @State private var showMediaCollection = false

    private let gridSpacing: CGFloat = 32
    private let maxGridWidth: CGFloat = 1000

    var body: some View {
        GeometryReader { geometry in
            let gridWidth = min(maxGridWidth, geometry.size.width - 80)
            let tileEdge = computeTileSize(gridWidth: gridWidth)

            VStack(spacing: 40) {
                header
                    .frame(maxWidth: gridWidth, alignment: .center)

                if images.isEmpty {
                    emptyState
                        .frame(maxWidth: gridWidth)
                        .frame(maxHeight: .infinity, alignment: .center)
                } else {
                    ScrollView(showsIndicators: false) {
                        LazyVGrid(columns: gridColumns(), spacing: gridSpacing) {
                            ForEach(images) { image in
                                NavigationLink(value: image.id) {
                                    galleryItem(for: image, tileEdge: tileEdge)
                                }
                                .buttonStyle(.plain)
                                .navigationTransition(.zoom(sourceID: image.id, in: zoomNamespace))
                            }
                        }
                        .frame(maxWidth: gridWidth)
                        .padding(.vertical, 32)
                        .frame(maxWidth: .infinity)
                    }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .padding(.vertical, 48)
            .padding(.horizontal, 40)
            .background(Color.viverePrimary.ignoresSafeArea())
        }
        .task {
            await requestPhotoAuthorizationIfNeeded()
        }
        .navigationDestination(for: UUID.self) { id in
            if let model = images.first(where: { $0.id == id }) {
                PhotoDetailView(imageModel: model, allImages: images)
                    .navigationTransition(.zoom(sourceID: id, in: zoomNamespace))
            } else {
                EmptyView()
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
                .padding(.horizontal, 20)
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
                .padding(.horizontal, 20)
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
        .padding()
    }

    private func galleryItem(for image: ImageModel, tileEdge: CGFloat) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .strokeBorder(.white, lineWidth: 10)

            if let uiImage = thumbnails[image.id] {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFill()
                    .frame(width: tileEdge - 20, height: tileEdge - 20)
                    .clipped()
                    .cornerRadius(18)
            } else {
                ProgressView()
                    .tint(.darkBlue)
            }
        }
        .frame(width: tileEdge, height: tileEdge * 1.05)
        .task {
            await loadThumbnailIfNeeded(for: image, targetSize: tileEdge)
        }
    }

    private func gridColumns() -> [GridItem] {
        Array(repeating: GridItem(.flexible(), spacing: gridSpacing), count: 4)
    }

    private func computeTileSize(gridWidth: CGFloat) -> CGFloat {
        let totalSpacing = gridSpacing * 3
        let usable = max(gridWidth - totalSpacing, 120)
        return usable / 4
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

    private func loadThumbnailIfNeeded(for model: ImageModel, targetSize: CGFloat) async {
        guard thumbnails[model.id] == nil else { return }
        guard photoAuthorizationStatus == .authorized || photoAuthorizationStatus == .limited else { return }

        let scale = max(displayScale, 1)
        let size = CGSize(width: targetSize * scale, height: targetSize * scale)

        if let thumbnail = await fetchImage(for: model.assetId, targetSize: size, deliveryMode: .opportunistic) {
            await MainActor.run {
                thumbnails[model.id] = thumbnail
            }
        }
    }

    private func fetchImage(for assetId: String, targetSize: CGSize, deliveryMode: PHImageRequestOptionsDeliveryMode) async -> UIImage? {
        let assets = PHAsset.fetchAssets(withLocalIdentifiers: [assetId], options: nil)
        guard let asset = assets.firstObject else { return nil }

        let options = PHImageRequestOptions()
        options.isSynchronous = false
        options.deliveryMode = deliveryMode
        options.resizeMode = .fast
        options.isNetworkAccessAllowed = true

        return await withCheckedContinuation { continuation in
            var didResume = false

            PHImageManager.default().requestImage(for: asset, targetSize: targetSize, contentMode: .aspectFill, options: options) { image, _ in
                guard !didResume else { return }
                didResume = true
                continuation.resume(returning: image)
            }
        }
    }
}

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: ImageModel.self, configurations: config)

    return PhotoGalleryView()
        .modelContainer(container)
}

