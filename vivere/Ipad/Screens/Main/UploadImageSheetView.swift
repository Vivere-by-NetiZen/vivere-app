//
//  UploadImageSheetView.swift
//  vivere
//
//  Created by Reinhart on 20/11/25.
//

import SwiftUI
import PhotosUI

struct UploadImageSheetView: View {
    @Binding var isPresented: Bool
    @Binding var inputDetailTrigger: Bool
    @Binding var localIdentifier: [String]
    
    @State var pickerItems = [PhotosPickerItem]()
    
    var body: some View {
        ZStack {
            Color.black.opacity(0.4)
                .ignoresSafeArea(.all)
                .onTapGesture {_ in
                    isPresented = false
                }
            
            HStack {
                VStack(alignment: .leading) {
                    Spacer()
                    Image("buttonLeft")
                        .padding()
                }
                .padding()
                
                VStack {
                    Image("notEnoughPhoto")
                        .padding()
                    Text("Fotomu Tidak Cukup")
                        .font(Font.largeTitle)
                        .fontWeight(.semibold)
                        .padding()
                    Text("Kamu harus upload minimal 3 foto untuk bermain cocokkan gambar.")
                        .padding()
                    PhotosPicker(selection: $pickerItems, matching: .images, photoLibrary: .shared()) {
                        CustomIpadButtonAsView(label: "\(Image(systemName: "square.and.arrow.up")) Tambahkan Foto", labelColor: .white, color: .darkBlue, style: .icon)
                            .frame(width: 350, height: 100)
                            .foregroundColor(.white)
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
                            isPresented = false
                            inputDetailTrigger = true
                        }
                    }
                }
                .frame(maxWidth: .infinity)
                .padding()
                .padding(.vertical, 30)
                
                VStack(alignment: .trailing) {
                    Button("\(Image(systemName: "xmark"))"){
                        isPresented = false
                    }
                    .foregroundColor(Color.black)
                    .font(Font.title)
                    .padding()
                    Spacer()
                    Image("buttonRight")
                        .padding()
                }
                .padding()
            }
            .frame(width: 720)
            .cornerRadius(20)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .foregroundColor(.accent)
            )
        }
    }
}

#Preview {
    @Previewable @State var isPresented: Bool = true
    @Previewable @State var inputDetailTrigger: Bool = false
    @Previewable @State var localIdentifier = [String]()
    UploadImageSheetView(isPresented: $isPresented, inputDetailTrigger: $inputDetailTrigger, localIdentifier: $localIdentifier)
}
