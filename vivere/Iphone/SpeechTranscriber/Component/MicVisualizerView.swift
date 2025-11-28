//import SwiftUI
//
//struct MicVisualizerView: View {
//    private var transcriber = SpeechTranscriber.shared
//
//    private let barCount: Int = 64
//    private let historyCapacity: Int = 256
//    private let barWidth: CGFloat = 3
//    private let barSpacing: CGFloat = 2
//    private let cornerRadius: CGFloat = 1.5
//    private let baseHeight: CGFloat = 8
//    private let maxExtraHeight: CGFloat = 150
//    private let color = Color(.viverePrimary)
//
//    @State private var tick: Int = 0
//    @State private var isActive: Bool = true
//    @State private var history: [CGFloat] = []
//    @State private var smoothed: [CGFloat] = []
//    private let smoothing: CGFloat = 0.1
//    private let idleJitter: CGFloat = 0.02
//
////    private var currentScalar: CGFloat {
//////        let mags = transcriber.downSampledMagnitudes
////        guard !mags.isEmpty else { return 0 }
////        
////        let upper = max(1, mags.count / 3)
////        let slice = mags.prefix(upper)
////        let avg = slice.reduce(0, +) / Float(slice.count)
////        let clamped = min(avg, Constants.magnitudeLimit)
////        // Normalize to 0...1
////        return CGFloat(clamped / Constants.magnitudeLimit)
////    }
//
//    var body: some View {
//        GeometryReader { geo in
//            let totalWidth = CGFloat(barCount) * barWidth + CGFloat(barCount - 1) * barSpacing
//            let scale = min(1, geo.size.width / totalWidth)
//
//            HStack(alignment: .bottom, spacing: barSpacing * scale) {
//                ForEach(visibleBars.indices, id: \.self) { i in
//                    let norm = visibleBars[i]
//                    let extra = norm * maxExtraHeight
//                    RoundedRectangle(cornerRadius: cornerRadius * scale, style: .continuous)
//                        .fill(color)
//                        .frame(width: barWidth * scale, height: baseHeight + extra)
//                        .shadow(color: .black.opacity(0.15), radius: 2, x: 0, y: 1)
//                }
//            }
//            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
//            .padding(.vertical, 8)
//            .padding(.horizontal, 12)
//            .background(
//                RoundedRectangle(cornerRadius: 16, style: .continuous)
//                    .fill(Color(.systemBackground).opacity(0.0))
//            )
//        }
//        .animation(.easeOut(duration: 0.08), value: smoothed)
//        .onAppear {
//            isActive = true
//            history = Array(repeating: 0, count: historyCapacity)
//            smoothed = Array(repeating: 0, count: historyCapacity)
//            startTicking()
//        }
//        .onDisappear {
//            isActive = false
//        }
//    }
//
//    private var visibleBars: [CGFloat] {
//        let count = min(barCount, smoothed.count)
//        guard count > 0 else { return [] }
//        let start = max(0, smoothed.count - count)
//        return Array(smoothed[start..<smoothed.count])
//    }
//
//    private func startTicking() {
//        func schedule() {
//            guard isActive else { return }
//            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0/60.0) {
//                // Compute target magnitude with a tiny idle jitter so it doesn’t freeze visually
////                var target = currentScalar
//                var target = 0.0
//                if target < 0.01 {
//                    target += CGFloat.random(in: -idleJitter...idleJitter)
//                    target = max(0, min(0.03, target))
//                }
//
//                // Append to history ring buffer
//                if history.count >= historyCapacity {
//                    history.removeFirst()
//                }
//                history.append(target)
//
//                // Smooth towards history
//                if smoothed.count != history.count {
//                    smoothed = Array(repeating: 0, count: history.count)
//                }
//                for i in 0..<history.count {
//                    let current = smoothed[i]
//                    let goal = history[i]
//                    smoothed[i] = current + (goal - current) * smoothing
//                }
//
//                tick &+= 1
//                schedule()
//            }
//        }
//        schedule()
//    }
//}
//
//#Preview {
//    MicVisualizerView()
//}
