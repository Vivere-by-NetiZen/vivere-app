import SwiftUI
import Charts
import CoreHaptics

struct SpeechTranscriberView: View {
    @State private var hasRequestSuggestion: Bool = false
    @State private var suggestionIndex: Int = 0
    @State private var showEndSessionAlert: Bool = false
    @State private var showMoodAlert: Bool = false
    @State private var selectedMood: Mood? = nil
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
                        InitialQuestionCard(
                            title: "Pertanyaan",
                            question: viewModel.isFetchingInitialQuestions ? "Loading..." : viewModel.initialQuestion
                        )
                        //                        .padding(.top, 80)
                        //                        .padding(.horizontal, 26)
                        .multilineTextAlignment(.center)
                        .lineLimit(nil)
                        .frame(minHeight: 410)
                    } else {
                        if viewModel.isFetchingSuggestion {
                            ZStack {
                                InitialQuestionCard(
                                    title: "Saran Tanggapan",
                                    question: ""
                                )
                                .frame(minHeight: 410)
                            }
                        } else if !viewModel.suggestions.isEmpty {
                            ZStack {
                                InitialQuestionCard(
                                    title: "Saran Tanggapan",
                                    question: currentSuggestion
                                )
                                .frame(minHeight: 410)
                                .lineLimit(nil)
                                
                                if hasPrevious {
                                    Button {
                                        withAnimation(.easeInOut) {
                                            suggestionIndex = max(0, suggestionIndex - 1)
                                        }
                                    } label: {
                                        Image(systemName: "chevron.left")
                                            .resizable()
                                            .foregroundStyle(.black.opacity(0.8))
                                            .frame(width: 20, height: 29)
                                            .shadow(color: .black.opacity(0.15), radius: 2, x: 0, y: 1)
                                            .padding()
                                    }
                                    .buttonStyle(.plain)
                                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomLeading)
                                    .padding(.bottom, 40)
                                    .padding(.leading, 40)
                                }
                                
                                if hasNext {
                                    Button {
                                        withAnimation(.easeInOut) {
                                            suggestionIndex = min(viewModel.suggestions.count - 1, suggestionIndex + 1)
                                        }
                                    } label: {
                                        Image(systemName: "chevron.right")
                                            .resizable()
                                            .foregroundStyle(.black.opacity(0.8))
                                            .frame(width: 20, height: 29)
                                            .padding()
                                            .shadow(color: .black.opacity(0.15), radius: 2, x: 0, y: 1)
                                    }
                                    .buttonStyle(.plain)
                                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomTrailing)
                                    .padding(.bottom, 40)
                                    .padding(.trailing, 40)
                                }
                            }
                            
                        } else if let err = viewModel.errorMessage {
                            VStack(spacing: 12) {
                                Text("Gagal mengambil rekomendasi")
                                    .font(.headline)
                                    .foregroundColor(.black)
                                Text(err)
                                    .font(.subheadline)
                                    .foregroundColor(.black)
                                    .multilineTextAlignment(.center)
                                    .padding(.horizontal)
                            }
                            .padding(.top, 80)
                            .padding(.horizontal, 16)
                        }
                    }
                    
                    MicVisualizerView()
                        .frame(minHeight: 150, maxHeight: 180)
                        .padding(.bottom, 0)
                    
                    VStack(spacing: 12) {
                        if viewModel.errorMessage != nil {
                            Button(action: {
                                suggestionIndex = 0
                                viewModel.getSuggestions()
                                hasRequestSuggestion = true
                            }) {
                                Text("Coba Lagi")
                                    .font(.headline)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 8)
                            }
                            .buttonStyle(.borderedProminent)
                            .tint(.accentColor)
                            .disabled(viewModel.isFetchingSuggestion)
                        } else {
                            Button(action: {
                                suggestionIndex = 0
                                viewModel.getSuggestions()
                                hasRequestSuggestion = true
                            }) {
                                HStack(spacing: 8) {
//                                    if viewModel.isFetchingSuggestion {
//                                        ProgressView()
//                                            .tint(.white)
//                                    }
                                    Text("Saran Tanggapan")
                                        .font(.headline)
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 8)
                            }
                            .buttonStyle(.borderedProminent)
                            .tint(.accentColor)
                            .disabled(viewModel.isFetchingSuggestion || (viewModel.partialTranscript.isEmpty && viewModel.finalTranscripts.isEmpty))
                        }
                        
                        Button(action: {
                            showEndSessionAlert = true
                        }) {
                            Text("Selesaikan Sesi")
                                .font(.headline)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 8)
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(.red)
                        .font(.headline)
                        .disabled(!hasRequestSuggestion || viewModel.isFetchingSuggestion)
                    }
                }
                .padding(.vertical, 74)
                .padding(.horizontal, 33)
            }
            .background(Color(hex: "#4A6FA5"))
            
            .overlay {
                if showEndSessionAlert {
                    ZStack {
                        Color.black.opacity(0.4)
                            .ignoresSafeArea()
                        
                        VStack(spacing: 16) {
                            VStack(spacing: 10){
                                Text("Apakah kamu yakin untuk mengakhiri sesi?")
                                    .font(.body)
                                    .fontWeight(.semibold)
                                    .multilineTextAlignment(.center)
                                    .foregroundStyle(.primary)
                                
                                Text("Mengakhiri sesi akan menghentikan terapi dan menyimpan hasilnya secara otomatis.")
                                    .font(.footnote)
                                    .multilineTextAlignment(.center)
                                    .foregroundStyle(.black)
                            }
                            .padding(24)
                            
                            HStack(spacing: 16) {
                                Button {
                                    withAnimation(.easeInOut) {
                                        showEndSessionAlert = false
                                    }
                                } label: {
                                    Text("Batalkan")
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 13)
                                        .padding(.horizontal, 16)
                                }
                                .buttonStyle(.bordered)
                                .tint(.gray)
                                .foregroundStyle(.black)
                                
                                Button {
                                    withAnimation(.easeInOut) {
                                        showEndSessionAlert = false
                                    }
                                    mpc.send(message: "end_session")
                                    viewModel.toggle(resume: false)
                                    showMoodAlert = true
                                    //                                    router.popToRoot()
                                } label: {
                                    Text("Ya")
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 13)
                                        .padding(.horizontal, 16)
                                }
                                .buttonStyle(.borderedProminent)
                                .tint(.accentColor)
                            }
                            .padding(.horizontal)
                            .padding(.bottom)
                        }
                        .frame(maxWidth: 298)
                        .background(.ultraThickMaterial, in: RoundedRectangle(cornerRadius: 34, style: .continuous))
                        .shadow(color: .black.opacity(0.25), radius: 20, x: 0, y: 8)
                        .padding(.horizontal, 24)
                        .transition(.scale.combined(with: .opacity))
                    }
                    .animation(.easeInOut, value: showEndSessionAlert)
                }
                
                if showMoodAlert {
                    Color.black.opacity(0.4)
                        .ignoresSafeArea()
                        .transition(.opacity)
                    
                    MoodCard(
                        questionText: "Bagaimana suasana hati ODD-mu setelah sesi?",
                        selectedMood: $selectedMood,
                    )
                    .transition(.scale.combined(with: .opacity))
                    .onChange(of: selectedMood) {
                        if selectedMood != nil {
                            withAnimation(.easeInOut) {
                                showMoodAlert = false
                            }
                            mpc.send(message: "mood_\(selectedMood!)")
                            router.popToRoot()
                        }
                    }
                }
            }
        }
        .task {
            await Task.yield()
            viewModel.toggle(resume: false)
        }
        .onChange(of: viewModel.suggestions) { _, _ in
            suggestionIndex = 0
        }
    }
    
    private var hasPrevious: Bool {
        suggestionIndex > 0
    }
    
    private var hasNext: Bool {
        suggestionIndex < max(0, viewModel.suggestions.count - 1)
    }
    
    private var currentSuggestion: String {
        guard !viewModel.suggestions.isEmpty,
              viewModel.suggestions.indices.contains(suggestionIndex) else {
            return ""
        }
        return viewModel.suggestions[suggestionIndex]
    }
}

#Preview {
    SpeechTranscriberView()
}
