//
//  SidePanel.swift
//  vivere
//
//  Created by Ahmed Nizhan Haikal on 25/11/25.
//

import Foundation
import SwiftUI

struct SidePanel: View {
    @Binding var showEndSessionAlert: Bool
    @State var viewModel: ReminiscenceTherapyViewModel
    
    @State private var hasRequestSuggestion: Bool = false
    @State private var suggestionIndex: Int = 0
    
    @GestureState private var dragOffset: CGFloat = 0
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        if (!hasRequestSuggestion) {
            VStack(spacing: 12) {
                Spacer()
                Text("Belum ada saran")
                    .font(.body.weight(.semibold))
                    .foregroundColor(.black)
                Text("Tekan tombolnya untuk memunculkan saran tanggapan")
                    .font(.footnote)
                    .foregroundStyle(Color(.secondaryLabel))
                    .multilineTextAlignment(.center)
                Button(action: {
                    viewModel.getSuggestions()
                    hasRequestSuggestion.toggle()
                }) {
                    Text("Berikan Saran")
                        .font(.callout.weight(.medium))
                        .foregroundStyle(Color(.white))
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .buttonBorderShape(.roundedRectangle(radius: 8))
                
                Spacer()
            }
        } else {
            if let err = viewModel.errorMessage {
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
            } else {
                List(viewModel.suggestions, id: \.self) { suggestion in
                    Text(suggestion)
                        .font(.body.weight(.medium))
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .listRowBackground(
                            RoundedRectangle(cornerRadius: 20)
                                .fill(.thinMaterial)
                        )
                        .listRowSeparator(.hidden)
                        .listRowBackground(Color.clear)
                        .padding(.vertical, 10)
                }
                .listRowSpacing(8)
                .listStyle(.plain)
                .scrollContentBackground(.hidden)
                .background(.clear)
            }
            
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
            }
            .padding()
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

private extension View {
    // Helper to hide separators on supported OS versions without breaking older ones
    @ViewBuilder
    func separatorStyleHiddenIfAvailable() -> some View {
        if #available(iOS 15.0, *) {
            self.listRowSeparator(.hidden)
        } else {
            self
        }
    }
}
