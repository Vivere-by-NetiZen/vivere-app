//
//  InputContextView.swift
//  vivere
//
//  Created by Reinhart on 10/11/25.
//

import SwiftUI
import Combine
import SwiftData

struct InputContextView: View {
    @ObservedObject var viewModel = InputContextViewModel()

    @State private var currContext: String = ""
    @State private var isDoneInputing: Bool = false

    let imagesIds: [String]

    @Environment(\.modelContext) private var modelContext

    var body: some View {
        ZStack {
            Color.viverePrimary.ignoresSafeArea(edges: .all)

            Button("Lewati \(Image(systemName: "chevron.right.2"))") {
                viewModel.save(currContext: "")
                Task {
                    await uploadAndSave()
                }
            }
            .disabled(viewModel.isUploading)
            .font(Font.title)
            .fontWeight(.bold)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
            .buttonStyle(.plain)
            .foregroundColor(.white)
            .padding()

            VStack {
                HStack {
                    Image("progressStepper1")
                    Line()
                        .stroke(style: StrokeStyle(lineWidth: 4, dash: [15]))
                        .frame(height: 1)
                    Image("progressStepper2")
                    Line()
                        .stroke(style: StrokeStyle(lineWidth: 4, dash: [15]))
                        .frame(height: 1)
                    Image("progressStepper3")
                }
                .frame(maxWidth: 400)
                .padding()

                HStack {
                    VStack {
                        if let image = viewModel.currentImage {
                            image
                                .resizable()
                                .scaledToFit()
                                .frame(width: 300, height: 300)
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
                            if viewModel.idx != 0 {
                                Button("Kembali") {
                                    viewModel.previous(currContext: currContext)
                                    currContext = viewModel.imageContexts[viewModel.idx]
                                }
                                .font(Font.title2)
                                .fontWeight(.semibold)
                                .buttonStyle(.plain)
                                .foregroundColor(.white)
                                Spacer()
                            }
                            if viewModel.idx != viewModel.totalImgCount - 1 {
                                CustomIpadButton(label: "Selanjutnya", color: .darkBlue, style: .large) {
                                    viewModel.next(currContext: currContext)
                                    currContext = viewModel.imageContexts[viewModel.idx]
                                }
                            }else{
                                CustomIpadButton(label: "Selanjutnya", color: .darkBlue, style: .large) {
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
        .navigationDestination(isPresented: $isDoneInputing) {
            FinishOnboardingView()
        }
        .onAppear() {
            Task {
                await viewModel.loadImages(imagesIds: imagesIds)
            }
        }
    }

    func uploadAndSave() async {
        // Show upload progress
        await MainActor.run {
            // Upload images for video generation
        }

        // Upload all images and get job IDs
        let jobIds = await viewModel.uploadImagesForVideoGeneration()

        // Save to database with job IDs
        await MainActor.run {
            for i in 0..<viewModel.totalImgCount {
                let jobId = i < jobIds.count ? jobIds[i] : nil
                let imgData = ImageModel(
                    assetId: viewModel.imageIdentifiers[i],
                    context: viewModel.imageContexts[i],
                    jobId: jobId
                )
                modelContext.insert(imgData)
                try? modelContext.save()
            }

            // Navigate to next screen
            isDoneInputing = true
        }
    }

    func saveToDB(){
        for i in 0..<viewModel.totalImgCount {
            let jobId = i < viewModel.jobIds.count ? viewModel.jobIds[i] : nil
            let imgData = ImageModel(
                assetId: viewModel.imageIdentifiers[i],
                context: viewModel.imageContexts[i],
                jobId: jobId
            )
            modelContext.insert(imgData)
            try? modelContext.save()
        }
    }
}

//#Preview {
//    InputContextView()
//}
