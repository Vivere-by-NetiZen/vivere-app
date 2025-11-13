import SwiftUI
import Charts
import CoreHaptics

struct SpeechTranscriberView: View {
    @State private var hasRequestSuggestion: Bool = false
    private var viewModel = SpeechTranscriberViewModel.shared
    @Environment(MPCManager.self) private var mpc
    @Environment(Router.self) private var router
    
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
                    if !hasRequestSuggestion {
                        InitialQuestionCard(question: viewModel.isFetchingInitialQuestions ? "Loading..." : viewModel.initialQuestion)
                            .padding(.top, 80)
                            .multilineTextAlignment(.center)
                            .lineLimit(nil)
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
                                        .frame(maxWidth: .infinity, alignment: .center)
                                        .background(Color.white)
                                        .cornerRadius(16)
                                        .shadow(color: .black.opacity(0.05), radius: 1, y: 1)
                                        .fixedSize(horizontal: false, vertical: true)
                                        .lineLimit(nil)
                                }
                            }
                            .padding(.horizontal, 16)
                            .padding(.top, 64)
                            
                            Spacer()
                        } else {
                            Spacer()
                        }
                    }
                    
                    MicVisualizerView()
                        .frame(minHeight: 150, maxHeight: 180)
                        .padding(.bottom, 0)
                    
                    
                    HStack {
                        Button(action: {
                            viewModel.getSuggestions()
                            hasRequestSuggestion = true
                        }) {
                            Text("Dapatkan Rekomendasi")
                                .foregroundStyle(.white)
                        }
                        .buttonStyle(.borderedProminent)
                        .padding(8)
                        
                        Button("Selesaikan Sesi", role: .destructive, action: {
                            viewModel.toggle(resume: false)
                            router.popToRoot()
                        })
                        .buttonStyle(.borderedProminent)
                        .padding(8)
                    }
                }
            }
            .background(Color(hex: "#4A6FA5"))
        }
        .onAppear {
            viewModel.toggle(resume: false)
        }
    }
}

#Preview {
    SpeechTranscriberView()
}
