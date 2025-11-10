import SwiftUI
import Charts

struct SpeechTranscriberView: View {
    @State private var recording = false
    
    private var state = SpeechTranscriberViewModel()
    
    private var composedTranscript: String {
        let finals = state.finalTranscripts.joined(separator: " ")
        if state.partialTranscript.isEmpty {
            return finals.isEmpty ? "-" : finals
        } else {
            // Append partial after finals with a separating space if needed
            return finals.isEmpty ? state.partialTranscript : "\(finals) \(state.partialTranscript)"
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
                    ScrollView {
                        Text(composedTranscript)
                            .font(.system(size: 24, weight: .semibold, design: .default))
                            .foregroundColor(.black)
                            .italic(state.partialTranscript.isEmpty ? false : true)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.vertical, 8)
                    }
                    .frame(minHeight: 180)
                    .padding(4)
                    
                    GroupBox("Suggestions") {
                        ScrollView {
                            VStack(alignment: .leading, spacing: 8) {
                                if let p = state.suggestionPoint {
                                    Text("Point: \(p)")
                                        .font(.headline)
                                }
                                if state.suggestions.isEmpty {
                                    Text("—")
                                        .foregroundStyle(.secondary)
                                } else {
                                    ForEach(Array(state.suggestions.enumerated()), id: \.offset) { idx, item in
                                        HStack(alignment: .top, spacing: 8) {
                                            Text("\(idx+1).")
                                                .fontWeight(.semibold)
                                            Text(item)
                                                .fixedSize(horizontal: false, vertical: true)
                                                .frame(maxWidth: .infinity, alignment: .leading)
                                        }
                                    }
                                }
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.vertical, 4)
                        }
                        .frame(minHeight: 180, maxHeight: 320)
                    }
                    
                    MicVisualizerView()
                    
                    if state.isStreaming {
                        HStack{
                            Button(action: {
                                if state.isPaused {
                                    state.resumeStream()
                                } else {
                                    state.pauseStream()
                                }
                            }) {
                                if !state.isPaused {
                                    RoundedRectangle(cornerRadius: 35)
                                        .fill(Color.white)
                                        .frame(width: 160, height: 60)
                                        .overlay(
                                            Image(systemName: "pause.fill")
                                                .font(.system(size: 40, weight: .bold))
                                                .foregroundColor(.red)
                                        )
                                        .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
                                        .transition(.scale.combined(with: .opacity))
                                } else {
                                    RoundedRectangle(cornerRadius: 35)
                                        .fill(Color.white)
                                        .frame(width: 160, height: 60)
                                        .overlay(
                                            Image(systemName: "play.fill")
                                                .font(.system(size: 40, weight: .bold))
                                                .foregroundColor(.red)
                                        )
                                        .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
                                        .transition(.scale.combined(with: .opacity))
                                }
                            }
                            
                            if (state.suggested) {
                                Button(action: {state.toggle(resume: false)}) {
                                    RoundedRectangle(cornerRadius: 35)
                                        .fill(state.isPaused ? Color.blue : Color.gray)
                                        .frame(width: 160, height: 60)
                                        .overlay(
                                            Text("Akhiri Sesi")
                                                .font(Font.system(size: 20, weight: .bold))
                                                .foregroundStyle(.white)
                                        )
                                        .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
                                        .transition(.scale.combined(with: .opacity))
                                        .disabled(!state.isPaused)
                                }
                            } else {
                                Button(action: { state.getSuggestion() }) {
                                    RoundedRectangle(cornerRadius: 35)
                                        .fill(state.isPaused ? Color.blue : Color.gray)
                                        .frame(width: 160, height: 60)
                                        .overlay(
                                            Text("Rekomendasi")
                                                .font(Font.system(size: 20, weight: .bold))
                                                .foregroundStyle(.white)
                                        )
                                        .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
                                        .transition(.scale.combined(with: .opacity))
                                        .disabled(!state.isPaused)
                                }
                            }
                        }
                    } else {
                        Button(action: {state.toggle(resume: false)}) {
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
                        .animation(.easeInOut(duration: 0.25), value: state.isStreaming)
                    }
                }
                .padding()
            }
            .background(Color(hex: "#4A6FA5"))
        }
    }
}

#Preview {
    SpeechTranscriberView()
}
