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
                saveToDB()
                isDoneInputing = true
            }
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
                                    saveToDB()
                                    isDoneInputing = true
                                }
                            }
                        }
                        .padding(.horizontal)
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
            }
        }
    }
    
    func saveToDB(){
        for i in 0..<viewModel.totalImgCount {
            let imgData = ImageModel(assetId: viewModel.imageIdentifiers[i], context: viewModel.imageContexts[i])
            modelContext.insert(imgData)
            try? modelContext.save()
        }
    }
}

//#Preview {
//    InputContextView()
//}
