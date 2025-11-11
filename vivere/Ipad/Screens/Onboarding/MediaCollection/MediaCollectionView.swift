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
                        .saturation(0)
                }
                .frame(maxWidth: 400)
                .padding()
                
                
                //                Image("")
                //                    .frame(width: 300, height: 300)
                //                    .clipShape(Circle())
                
                //placeholder
                ZStack {
                    Color.vivereSecondary.frame(width: 300, height: 300)
                        .clipShape(Circle())
                    Text("ASET")
                        .font(.largeTitle)
                        .fontWeight(.semibold)
                        .foregroundColor(Color.red)
                }
                
                Text("Tambahkan Kenanganmu")
                    .font(Font.largeTitle.bold())
                    .foregroundColor(.white)
                    .padding(.top, 30)
                
                Text("Pilih beberapa foto yang memiliki cerita bagi Anda, tidak perlu banyak, cukup yang ingin dibagikan bersama eyang.")
                    .font(Font.title)
                    .foregroundColor(Color.white)
                    .frame(width: 800)
                    .multilineTextAlignment(.center)
                    .padding(.top, 10)
                    .padding(.bottom, 30)
                
                PhotosPicker(selection: $pickerItems, matching: .images, photoLibrary: .shared()) {
                    CustomIpadButtonAsView(label: "\(Image(systemName: "square.and.arrow.up")) Tambahkan Foto", color: .accent, style: .large)
                }
                .buttonStyle(.plain)
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
            InputContextView(imagesIds: localIdentifier)
        }
    }
}

//#Preview {
    //    MediaCollectionView()
//}
