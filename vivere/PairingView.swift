import SwiftUI

struct PairingView: View {
    let continueAction: () -> Void

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                Spacer()

                // Placeholder for pairing content
                VStack(spacing: 16) {
                    Image(systemName: "link.circle")
                        .font(.system(size: 64))
                        .foregroundStyle(.secondary)

                    Text("Pairing")
                        .font(.largeTitle)
                        .fontWeight(.semibold)
                }

                Spacer()

                Button(action: continueAction) {
                    Text("Continue to App")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
            }
            .padding()
            .navigationTitle("Pairing")
        }
    }
}

