//
//  DebugMenuView.swift
//  vivere
//
//  Created for debug purposes
//

import SwiftUI
import SwiftData

struct DebugMenuView: View {
    @AppStorage("debugSkipDeviceConnection") private var skipDeviceConnection: Bool = false
    @Environment(\.modelContext) private var modelContext

    var body: some View {
        Menu {
            Toggle("Skip Device Connection", isOn: $skipDeviceConnection)

            Divider()

            Button(action: {
                NotificationCenter.default.post(name: .navigateToHome, object: nil)
            }) {
                Label("Go to Home", systemImage: "house.fill")
            }

            Button(action: {
                logDebugInfo()
            }) {
                Label("Log Data & Videos", systemImage: "doc.text.magnifyingglass")
            }
        } label: {
            Image(systemName: "ladybug.fill")
                .font(.title3)
                .foregroundColor(.white)
                .frame(width: 44, height: 44)
                .background(
                    Circle()
                        .fill(Color.black.opacity(0.7))
                )
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomLeading)
        .padding(20)
    }

    private func logDebugInfo() {
        print("\n🚀 === DEBUG INFO START === 🚀")

        // 1. Log Images from SwiftData
        do {
            let descriptor = FetchDescriptor<ImageModel>()
            let images = try modelContext.fetch(descriptor)

            print("\n📸 SwiftData Images (\(images.count)):")
            for (index, image) in images.enumerated() {
                print("  [\(index)] ImageModel")
                print("    ├── ID: \(image.id)")
                print("    ├── AssetID: \(image.assetId)")
                print("    ├── Context: \(image.context?.prefix(20) ?? "nil")...")
                print("    ├── OperationID: \(image.operationId ?? "nil")")
                print("    └── Emotion: \(image.emotion)")

                if let opId = image.operationId {
                    let isDownloaded = VideoDownloadService.shared.isVideoDownloaded(operationId: opId)
                    print("    └── Video Status: \(isDownloaded ? "✅ Downloaded" : "❌ Not Found locally")")
                }
            }
        } catch {
            print("❌ Failed to fetch images: \(error)")
        }

        // 2. Log Files in Videos Directory
        print("\n📂 Local Videos Directory:")
        let fileManager = FileManager.default
        if let documentsPath = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first {
            let videosDir = documentsPath.appendingPathComponent("Videos")

            do {
                let files = try fileManager.contentsOfDirectory(at: videosDir, includingPropertiesForKeys: nil)
                if files.isEmpty {
                    print("  (Directory is empty)")
                } else {
                    for file in files {
                        let attributes = try? fileManager.attributesOfItem(atPath: file.path)
                        let size = attributes?[.size] as? Int64 ?? 0
                        let sizeMB = Double(size) / (1024 * 1024)
                        print("  📄 \(file.lastPathComponent) (\(String(format: "%.2f", sizeMB)) MB)")
                    }
                }
            } catch {
                print("  ❌ Could not list directory (might not exist yet): \(error.localizedDescription)")
            }
        }

        print("\n🏁 === DEBUG INFO END === 🏁\n")
    }
}

extension Notification.Name {
    static let navigateToHome = Notification.Name("navigateToHome")
}

#Preview {
    ZStack {
        Color.viverePrimary.ignoresSafeArea()
        DebugMenuView()
    }
}

