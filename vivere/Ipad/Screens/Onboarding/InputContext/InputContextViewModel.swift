//
//  InputContextViewModel.swift
//  vivere
//
//  Created by Reinhart on 10/11/25.
//

import Foundation
import SwiftUI
import Combine
import PhotosUI

class InputContextViewModel: ObservableObject {
    @Published var currentImage: Image?
    @Published var currentContext: String?
    @Published var idx: Int = 0
    @Published var totalImgCount: Int = 0
    
    var selectedImages: [Image] = []
    var imageIdentifiers: [String] = []
    var imageContexts: [String] = []
    
    func loadImages(imagesIds: [String]) async {
        idx = 0
        imageIdentifiers = imagesIds
        totalImgCount = imagesIds.count
        imageContexts = Array(repeating: "", count: totalImgCount)
        
        let assets = PHAsset.fetchAssets(withLocalIdentifiers: imagesIds, options: nil)
        let imageManager = PHImageManager.default()
        let options = PHImageRequestOptions()
        options.version = .original
        options.isNetworkAccessAllowed = true
        options.deliveryMode = .opportunistic
        options.isSynchronous = false
        options.resizeMode = .none
        for i in 0..<totalImgCount {
            let asset = assets.object(at: i)
            if let imgWait = await withCheckedContinuation({ continuation in
                imageManager.requestImageDataAndOrientation(for: asset, options: options) { data, _, _, _ in
                    if let data, let image = UIImage(data: data) {
                        continuation.resume(returning: image)
                    }
                }
            }) {
                self.selectedImages.append(Image(uiImage: imgWait))
            }
        }
        currentImage = selectedImages[idx]
        currentContext = imageContexts[idx]
    }
    
    func next(currContext: String) {
        imageContexts[idx] = currContext
        idx += 1
        currentImage = selectedImages[idx]
        currentContext = imageContexts[idx]
    }
    
    func previous(currContext: String) {
        imageContexts[idx] = currContext
        idx -= 1
        currentImage = selectedImages[idx]
        currentContext = imageContexts[idx]
    }
    
    func save(currContext: String) {
        imageContexts[idx] = currContext
    }
}
