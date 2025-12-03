//
//  GalleryInputContextView.swift
//  vivere
//
//  Created by Imo Madjid on 19/11/25.
//

import SwiftUI
import SwiftData

struct GalleryInputContextView: View {
    @State var viewModel = InputContextViewModel()

    @State private var currContext: String = ""

    let imagesIds: [String]

    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack {
            Color.viverePrimary.ignoresSafeArea(edges: .all)

            VStack {
                // Header
                Text("Ceritakan sedikit tentang foto itu")
                    .font(Font.largeTitle.bold())
                    .foregroundColor(.white)
                    .padding(.top, 30)

                HStack {
                    VStack {
                        if let image = viewModel.currentImage {
                            image
                                .resizable()
//                                .scaledToFit()
                                .frame(maxWidth: .infinity, maxHeight: .infinity)
                                .padding()
                                .background(Color.white)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 20)
                                        .stroke(Color.black, lineWidth: 2)
                                )
                                .cornerRadius(20)
                                .padding()
                        }
                        Text("Foto \(viewModel.idx + 1) dari \(viewModel.totalImgCount)")
                            .font(Font.title3)
                            .fontWeight(.medium)
                            .foregroundColor(.white)
                    }

                    VStack {
                        Text("Ceritakan sedikit tentang foto itu")
                            .font(.title)
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                            .hidden() // Maintain spacing structure of original view

                        TextEditor(text: $currContext)
                            .frame(maxHeight: 300)
                            .padding()
                            .background(Color.white)
                            .overlay(
                                RoundedRectangle(cornerRadius: 20)
                                    .stroke(Color.black, lineWidth: 2)
                            )
                            .cornerRadius(20)
                            .padding()
                        Text("*Anda bisa melanjutkannya nanti")
                            .foregroundColor(.white)
                            .padding(.bottom, 20)
                            .padding(.horizontal)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        HStack {
                            if viewModel.idx > 0 {
                                Button("Kembali") {
                                    viewModel.previous(currContext: currContext)
                                    currContext = viewModel.currentContext ?? ""
                                }
                                .font(Font.title2)
                                .fontWeight(.semibold)
                                .buttonStyle(.plain)
                                .foregroundColor(.white)
                                Spacer()
                            }
                            if viewModel.idx < viewModel.totalImgCount - 1 {
                                CustomIpadButton(label: "Selanjutnya", color: .accent, style: .large) {
                                    viewModel.next(currContext: currContext)
                                    currContext = viewModel.currentContext ?? ""
                                }
                            } else {
                                CustomIpadButton(label: "Simpan", color: .accent, style: .large) {
                                    viewModel.save(currContext: currContext)
                                    Task {
                                        await uploadAndSave()
                                    }
                                }
                                .disabled(viewModel.isUploading)
                            }
                        }
                        .padding(.horizontal)
                    }
                    .frame(maxWidth: 500)
            }
                .padding(50)
        }

        // Upload progress overlay
        if viewModel.isUploading {
            ZStack {
                Color.black.opacity(0.6)
                    .ignoresSafeArea()

                VStack(spacing: 20) {
                    ProgressView()
                        .scaleEffect(1.5)
                        .tint(.white)

                    Text("Mengunggah foto dan membuat video...")
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)

                    Text("\(viewModel.uploadProgress)%")
                        .font(.title3)
                        .foregroundColor(.white)

                    if let error = viewModel.uploadError {
                        Text(error)
                            .font(.caption)
                            .foregroundColor(.red)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }
                }
                .padding(40)
                .background(Color.vivereSecondary)
                .cornerRadius(20)
                .padding(40)
            }
        }

        }
        .navigationBarBackButtonHidden(true)
        .task {
            await viewModel.loadImages(imagesIds: imagesIds)
            currContext = viewModel.currentContext ?? ""
        }
    }

    func uploadAndSave() async {
        // Save images to database immediately (without job IDs)
        // Store asset IDs for background update
        let assetIds = viewModel.imageIdentifiers

        await MainActor.run {
            #if DEBUG
            print("💾 Saving \(viewModel.totalImgCount) images to database immediately...")
            #endif

            for i in 0..<viewModel.totalImgCount {
                let imgData = ImageModel(
                    assetId: viewModel.imageIdentifiers[i],
                    context: viewModel.imageContexts[i],
                    operationId: "PENDING_UPLOAD" // Mark as pending to prevent duplicate uploads
                )
                modelContext.insert(imgData)
            }
            try? modelContext.save()

            #if DEBUG
            print("✅ Images saved. Navigating to next screen immediately...")
            #endif

            // Dismiss immediately - uploads happen in background
            dismiss()
        }

        // Start background upload task (doesn't block navigation)
        // Use Task instead of Task.detached to maintain access to view context
        Task(priority: .background) { [weak viewModel] in
            guard let viewModel = viewModel else { return }

            #if DEBUG
            print("🚀 Starting background upload process for \(viewModel.totalImgCount) images...")
            #endif

            let operationIds = await viewModel.uploadImagesForVideoGeneration()

            // Update database with operation IDs in background
            await MainActor.run {
                #if DEBUG
                print("💾 Updating database with operation IDs...")
                #endif

                // Fetch existing ImageModel entries and update them
                let descriptor = FetchDescriptor<ImageModel>()
                if let images = try? modelContext.fetch(descriptor) {
                    for i in 0..<min(assetIds.count, operationIds.count) {
                        let assetId = assetIds[i]
                        if let imageModel = images.first(where: { $0.assetId == assetId }) {
                            imageModel.operationId = operationIds[i]
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
}

