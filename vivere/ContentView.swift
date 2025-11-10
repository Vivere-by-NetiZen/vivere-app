import SwiftUI

struct ContentView: View {
    @State private var transcriber = SpeechTranscriber(localeIdentifier: "id-ID")

    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                HStack {
                    Button(transcriber.isTranscribing ? "Stop" : "Start Live Transcription") {
                        if transcriber.isTranscribing {
                            transcriber.stopTranscription()
                        } else {
                            transcriber.startLiveTranscription()
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    Button(transcriber.isFetchingSuggestion ? "Getting Suggestions…" : "Get Suggestions") {
                        transcriber.fetchSuggestions()
                    }
                    .buttonStyle(.bordered)
                    .disabled(transcriber.transcript.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || transcriber.isFetchingSuggestion)
                }

                GroupBox("Transcript") {
                    ScrollView {
                        Text(transcriber.transcript.isEmpty ? "—" : transcriber.transcript)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.vertical, 8)
                    }
                    .frame(minHeight: 180)
                }

                GroupBox("Suggestions") {
                    ScrollView {
                        VStack(alignment: .leading, spacing: 8) {
                            if let p = transcriber.suggestionPoint {
                                Text("Point: \(p)")
                                    .font(.headline)
                            }
                            if transcriber.suggestions.isEmpty {
                                Text("—")
                                    .foregroundStyle(.secondary)
                            } else {
                                ForEach(Array(transcriber.suggestions.enumerated()), id: \.offset) { idx, item in
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

                if let err = transcriber.errorMessage {
                    Text(err).foregroundStyle(.red)
                }

                Spacer()
            }
            .padding()
            .navigationTitle("Live ASR (Apple Speech)")
        }
        .onAppear {
            Task { await transcriber.requestAuthorization() }
        }
    }
}
