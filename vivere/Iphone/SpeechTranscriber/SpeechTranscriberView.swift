import SwiftUI
import Charts

struct SpeechTranscriberView: View {
    @State private var hasRecorded: Bool = false
    private var viewModel = SpeechTranscriberViewModel()
    
    private var composedTranscript: String {
        let finals = viewModel.finalTranscripts.joined(separator: " ")
        if viewModel.partialTranscript.isEmpty {
            return finals.isEmpty ? "-" : finals
        } else {
            return finals.isEmpty ? viewModel.partialTranscript : "\(finals) \(viewModel.partialTranscript)"
        }
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                RadialGradient(
                    gradient: Gradient(stops: [
                        .init(color: Color(hex: "#6594D8"), location:0.0),
                        .init(color: Color(hex: "#D8E0F4"), location: 0.78)]),
                    center: .bottom,
                    startRadius: 0,
                    endRadius: 250
                )
                .scaleEffect(x: 1.0,
                             y: 2.5,
                             anchor: .bottom)
                .ignoresSafeArea()
                
                VStack(spacing: 16) {
                    if !hasRecorded {
                        InitialQuestionCard(question: viewModel.isFetchingInitialQuestions ? "Loading..." : viewModel.initialQuestion)
                    } else {
                        if !viewModel.suggestions.isEmpty {
                            VStack(alignment: .leading, spacing: 8) {
                                ForEach(Array(viewModel.suggestions.enumerated()), id: \.offset) { idx, item in
                                    Text(item)
                                        .font(.body.weight(.medium))
                                        .multilineTextAlignment(.center)
                                        .foregroundColor(.black)
                                        .padding(.vertical, 16)
                                        .padding(.horizontal, 20)
                                        .frame(maxWidth: .infinity)
                                        .background(Color.white)
                                        .cornerRadius(16)
                                        .shadow(color: .black.opacity(0.05), radius: 1, y: 1)
                                }
                            }
                            .frame(minHeight: 180, maxHeight: 320)
                        } else {
                            Spacer()
                        }
                        
                        MicVisualizerView()
                    }
                    
                    if viewModel.isStreaming {
                        Button(action: {
                            viewModel.toggle(resume: hasRecorded)
                        }) {
                            RoundedRectangle(cornerRadius: 35)
                                .fill(Color.white)
                                .frame(width: 160, height: 60)
                                .overlay(
                                    Image(systemName: "stop.fill")
                                        .font(.system(size: 40, weight: .bold))
                                        .foregroundColor(.red)
                                )
                                .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
                                .transition(.scale.combined(with: .opacity))
                        }
                    } else {
                        Button(action: {
                            viewModel.toggle(resume: hasRecorded)
                            hasRecorded = true
                        }) {
                            Circle()
                                .fill(Color.red)
                                .frame(width: 90, height: 60)
                                .overlay(
                                    Circle()
                                        .stroke(Color.white, lineWidth: 6)
                                )
                                .shadow(color: .black.opacity(0.1), radius: 4)
                                .transition(.scale.combined(with: .opacity))
                        }
                        .buttonStyle(.plain)
                        .animation(.easeInOut(duration: 0.25), value: viewModel.isStreaming)
                    }
                }
            }
            .background(Color(hex: "#4A6FA5"))
        }
        .onAppear {
            if let image = UIImage(named: "IMG_7427") {
                viewModel.getInitialQuestion(image: image)
            } else {
                // Fallback for bundle file with known extension, e.g., jpg
                if let url = Bundle.main.url(forResource: "IMG_7427", withExtension: "jpg"),
                   let fileImage = UIImage(contentsOfFile: url.path) {
                    viewModel.getInitialQuestion(image: fileImage)
                } else {
                    // Optional: log or set an error state
                    print("Test image img_7427 not found in assets or bundle.")
                }
            }
        }
    }
}

#Preview {
    SpeechTranscriberView()
}
