//
//  MediaCollectionView.swift
//  vivere
//
//  Created by Reinhart on 09/11/25.
//

import SwiftUI
import PhotosUI

struct MediaCollectionView: View {
    @State var pickerItems = [PhotosPickerItem]()
    @State private var localIdentifier = [String]()
    @State private var isSelected: Bool = false

    var body: some View {
        ZStack {
            Color.viverePrimary.ignoresSafeArea(edges: .all)

            VStack (spacing: 24) {
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
                        .saturation(0)
                }
                .frame(maxWidth: 400)
                .padding()

                VStack(spacing: 32){
                    Image("addMemories")
                        .frame(width: 300, height: 300)

                    VStack(spacing: 16){
                        Text("Tambahkan Kenanganmu")
                            .font(Font.largeTitle.bold())
                            .foregroundColor(.white)

                        Text("Pilih beberapa foto yang memiliki cerita bagimu, tidak perlu banyak, cukup yang ingin dibagikan bersama.")
                            .font(Font.title)
                            .foregroundColor(Color.white)
                            .frame(width: 800)
                            .multilineTextAlignment(.center)
                    }
                }

                PhotosPicker(selection: $pickerItems, matching: .images, photoLibrary: .shared()) {
                    CustomIpadButtonAsView(label: "\(Image(systemName: "square.and.arrow.up")) Tambahkan Foto", color: .accent, style: .icon)
                        .frame(width: 350, height: 100)
                }
                .buttonStyle(.plain)
                .onAppear() {
                    Task {
                        await PHPhotoLibrary.requestAuthorization(for: .readWrite)
                    }
                }
                .onChange(of: pickerItems) {
                    Task {
                        localIdentifier.removeAll()

                        for item in pickerItems {
                            if let _ = try await item.loadTransferable(type: Data.self) {

                                if let itemId = item.itemIdentifier {
                                    localIdentifier.append(itemId)
                                }

                            }
                        }
                        isSelected = true
                    }
                }
            }

        }
        .navigationBarBackButtonHidden(true)
        .navigationDestination(isPresented: $isSelected) {
            InputContextView(imagesIds: localIdentifier, isOnboarding: true)
        }
    }
}

//#Preview {
    //    MediaCollectionView()
//}
