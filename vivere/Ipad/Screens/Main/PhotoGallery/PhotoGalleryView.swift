//
//  PhotoGalleryView.swift
//  vivere
//
//  Created by ChatGPT on 11/14/25.
//

import SwiftUI
import SwiftData
import Photos
import PhotosUI

struct PhotoGalleryView: View {
    @Environment(\.dismiss) private var dismiss
    @Query private var images: [ImageModel]
    @State private var pickerItems = [PhotosPickerItem]()
    @State private var selectedImageIdentifiers: [String] = []
    @State private var showInputContext = false
    @State private var showVideoProgress = false

    private let columns = [GridItem](repeating: GridItem(.flexible(), spacing: 32), count: 4)
    private let gridSpacing: CGFloat = 32

    private var imagesWithVideoJobs: [ImageModel] {
        images.filter { $0.jobId != nil }
    }

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
            }
        }
        .navigationDestination(isPresented: $showInputContext) {
            InputContextView(imagesIds: selectedImageIdentifiers)
        }
        .sheet(isPresented: $showVideoProgress) {
            VideoProgressView(images: imagesWithVideoJobs)
        }
        .onAppear {
            Task {
                await PHPhotoLibrary.requestAuthorization(for: .readWrite)
            }
        }
        .onChange(of: pickerItems) {
            Task {
                selectedImageIdentifiers.removeAll()

                for item in pickerItems {
                    if let _ = try await item.loadTransferable(type: Data.self) {
                        if let itemId = item.itemIdentifier {
                            selectedImageIdentifiers.append(itemId)
                        }
                    }
                }

                if !selectedImageIdentifiers.isEmpty {
                    showInputContext = true
                }
            }
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

            // Video progress button
            if !imagesWithVideoJobs.isEmpty {
                CustomIpadButton(color: .vivereSecondary) {
                    showVideoProgress = true
                } label: {
                    Image(systemName: "video.fill")
                        .font(.system(size: 22, weight: .semibold))
                        .foregroundColor(.black)
                        .frame(width: 70, height: 70)
                }
            }

            PhotosPicker(selection: $pickerItems, matching: .images, photoLibrary: .shared()) {
                HStack(spacing: 12) {
                    Image(systemName: "plus")
                        .font(.system(size: 28, weight: .bold))
                }
                .foregroundColor(.black)
                .padding(.horizontal, 40)
                .frame(height: 70)
                .background(
                    ZStack {
                        RoundedRectangle(cornerRadius: 20)
                            .foregroundColor(.accent)
                            .shadow(
                                color: .accent.tint(0.2),
                                radius: 0,
                                x: 3,
                                y: 3
                            )
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(style: StrokeStyle(lineWidth: 2, dash: [15]))
                            .padding(10)
                            .foregroundStyle(.black)
                    }
                )
            }
            .buttonStyle(.plain)
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

struct PhotoThumbnailView: View {
    let imageModel: ImageModel
    @State private var thumbnail: UIImage?
    @Environment(\.displayScale) private var displayScale

    private enum Constants {
        static let thumbnailBaseSize: CGFloat = 200
        static let borderWidth: CGFloat = 10
        static let borderPadding: CGFloat = 20
        static let cornerRadius: CGFloat = 24
        static let imageCornerRadius: CGFloat = 18
        static let heightMultiplier: CGFloat = 1.05
    }

    var body: some View {
        GeometryReader { geometry in
            let size = geometry.size.width

            ZStack {
                RoundedRectangle(cornerRadius: Constants.cornerRadius, style: .continuous)
                    .strokeBorder(.white, lineWidth: Constants.borderWidth)

                if let thumbnail {
                    Image(uiImage: thumbnail)
                        .resizable()
                        .scaledToFill()
                        .frame(
                            width: size - Constants.borderPadding,
                            height: size - Constants.borderPadding
                        )
                        .clipped()
                        .cornerRadius(Constants.imageCornerRadius)
                } else {
                    ProgressView()
                        .tint(.darkBlue)
                }
            }
            .frame(width: size, height: size * Constants.heightMultiplier)
        }
        .aspectRatio(1, contentMode: .fit)
        .task {
            await loadThumbnail()
        }
    }

    private func loadThumbnail() async {
        guard thumbnail == nil else { return }

        let authStatus = PHPhotoLibrary.authorizationStatus(for: .readWrite)
        guard authStatus == .authorized || authStatus == .limited else { return }

        let scale = max(displayScale, 1)
        let targetSize = CGSize(
            width: Constants.thumbnailBaseSize * scale,
            height: Constants.thumbnailBaseSize * scale
        )

        let assets = PHAsset.fetchAssets(withLocalIdentifiers: [imageModel.assetId], options: nil)
        guard let asset = assets.firstObject else { return }

        let options = PHImageRequestOptions()
        // Use .fastFormat for thumbnails - ensures single completion call
        // This prevents continuation misuse errors with async/await
        options.deliveryMode = .fastFormat
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
