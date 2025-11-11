//
//  InputContextView.swift
//  vivere
//
//  Created by Reinhart on 10/11/25.
//

import SwiftUI
import Combine

struct InputContextView: View {
    @ObservedObject var viewModel = InputContextViewModel()
    
    @State private var currContext: String = ""
    @State private var isDoneInputing: Bool = false
    
    let imagesIds: [String]
    @State var thisImgs = [Image]()
    
    var body: some View {
        ZStack {
            Color.viverePrimary.ignoresSafeArea(edges: .all)
            
            Button("Lewati \(Image(systemName: "chevron.right.2"))") {
                viewModel.save(currContext: "")
                isDoneInputing = true
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
            .buttonStyle(.plain)
            .foregroundColor(.white)
            
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
                    }
                    
                    VStack {
                        Text("Ceritakan sedikit tentang foto itu")
                            .font(.title)
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                        TextEditor(text: $currContext)
                            .frame(maxHeight: 300)
                            .background(Color.white)
                            .padding()
                            .overlay(
                                RoundedRectangle(cornerRadius: 20)
                                    .stroke(Color.black, lineWidth: 2)
                            )
                            .padding()
                        Text("*Anda bisa melanjutkannya nanti")
                            .foregroundColor(.white)
                        HStack {
                            if viewModel.idx != 0 {
                                Button("Kembali") {
                                    viewModel.previous(currContext: "")
                                }
                                .buttonStyle(.plain)
                                .foregroundColor(.white)
                            }
                            if viewModel.idx != viewModel.totalImgCount - 1 {
                                CustomIpadButton(label: "Selanjutnya", color: .darkBlue, style: .large) {
                                    viewModel.next(currContext: "")
                                }
                            }else{
                                CustomIpadButton(label: "Selanjutnya", color: .darkBlue, style: .large) {
                                    viewModel.save(currContext: "")
                                }
                            }
                        }
                    }
                    .frame(maxWidth: 500)
                }
            }

        }
        .navigationBarBackButtonHidden(true)
        .navigationDestination(isPresented: $isDoneInputing) {
            // Main View
        }
        .onAppear() {
            Task {
                await viewModel.loadImages(imagesIds: imagesIds)
                thisImgs = viewModel.selectedImages
            }
        }
    }
}

//#Preview {
//    InputContextView()
//}
