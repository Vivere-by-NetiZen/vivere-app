////
////  MoodCart.swift
////  vivere
////
////  Created by Ahmed Nizhan Haikal on 19/11/25.
////
//
//import Foundation
//import SwiftUI
//
//enum Mood: String, CaseIterable {
//    case sad = "SEDIH"
//    case neutral = "NETRAL"
//    case happy = "SENANG"
//}
//
//struct MoodCard: View {
//    let questionText: String
//    @Binding var selectedMood: Mood?
//
//    var body: some View {
//        VStack(spacing: 16) {
//            Text(questionText)
//                .font(.body.weight(.semibold))
//                .multilineTextAlignment(.center)
//                .padding(8)
//
//            HStack(spacing: 16) {
//                moodButton(.sad, assetName: "mood_sad")
//                moodButton(.neutral, assetName: "mood_neutral")
//                moodButton(.happy, assetName: "mood_happy")
//            }
//        }
//        .padding(24)
//        .background(
//            RoundedRectangle(cornerRadius: 24, style: .continuous)
//                .fill(Color(.systemBackground))
//                .shadow(radius: 16)
//        )
//        .padding(.horizontal, 24)
//    }
//
//    @ViewBuilder
//    private func moodButton(_ mood: Mood, assetName: String) -> some View {
//        let isSelected = selectedMood == mood
//
//        Button {
//            selectedMood = mood
//        } label: {
//            VStack(spacing: 8) {
//                Image(assetName)
//                    .resizable()
//                    .scaledToFit()
//                    .frame(width: 68, height: 68)
//                    .scaleEffect(isSelected ? 1.15 : 1.0)
//                    .animation(.spring(response: 0.25, dampingFraction: 0.7), value: isSelected)
//
//                Text(mood.rawValue)
//                    .font(.footnote.weight(.semibold))
//                    .foregroundColor(.primary)
//            }
//        }
//        .buttonStyle(.plain)
//    }
//}
//
//#Preview {
//    @Previewable @State var selectedMood: Mood? = nil
//    MoodCard(questionText: "Bagaimana suasana hati ODD setelah melihat video?", selectedMood: $selectedMood)
//}
