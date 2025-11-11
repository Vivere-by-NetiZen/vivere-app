import SwiftUI

struct MicVisualizerView: View {
    private var transcriber = SpeechTranscriber.shared

    let barWidth: CGFloat = 60
    let extraHeight: CGFloat = 150

    @State private var tick: Int = 0
    @State private var isActive: Bool = true

    @State private var smoothedBuckets: [CGFloat] = Array(repeating: 0, count: 4)

    private let smoothing: CGFloat = 0.25

    private var rawBuckets: [CGFloat] {
        let values = transcriber.downSampledMagnitudes
        guard !values.isEmpty else { return Array(repeating: 0, count: 4) }

        let bucketCount = 4
        let chunkSize = max(1, values.count / bucketCount)
        var buckets: [CGFloat] = []

        var start = 0
        for _ in 0..<bucketCount {
            let end = min(values.count, start + chunkSize)
            if start < end {
                let slice = values[start..<end]
                let avg = slice.reduce(0, +) / Float(slice.count)
                buckets.append(CGFloat(avg))
            } else {
                buckets.append(0)
            }
            start = end
        }

        return buckets
    }

    var body: some View {
        HStack(spacing: 16) {
            ForEach(smoothedBuckets.indices, id: \.self) { index in
                let magnitude = smoothedBuckets[index]
                Capsule()
                    .fill(Color(red: 75/255, green: 97/255, blue: 140/255))
                    .frame(
                        width: barWidth,
                        height: barWidth + (magnitude * extraHeight / CGFloat(Constants.magnitudeLimit))
                    )
                    .shadow(color: .black.opacity(0.3), radius: 6, x: 0, y: 6)
            }
        }
        .padding()
        .clipShape(RoundedRectangle(cornerRadius: 24))
        .animation(.easeOut(duration: 0.08), value: smoothedBuckets)
        .onAppear {
            isActive = true
            smoothedBuckets = rawBuckets
            startTicking()
        }
        .onDisappear {
            isActive = false
        }
    }

    private func startTicking() {
        func schedule() {
            guard isActive else { return }
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0/60.0) {
                let target = rawBuckets
                var next = smoothedBuckets
                if next.count != target.count { next = Array(repeating: 0, count: target.count) }
                for i in 0..<target.count {
                    let current = next[i]
                    let goal = target[i]
                    next[i] = current + (goal - current) * smoothing
                }
                smoothedBuckets = next

                tick &+= 1
                schedule()
            }
        }
        schedule()
    }
}

#Preview {
    MicVisualizerView()
}
