import SwiftUI

struct InitialQuestionCard: View {
    var title: String = "Pertanyaan"
    var question: String = "Apakah kalian punya lagu atau film favorit bersama?"
    
    var body: some View {
        VStack(spacing: 96) {
            Text(title)
                .font(.title3)
                .foregroundColor(.black)
                .padding(.top, 25)
            
            ScrollView {
                Text(question)
                    .font(.title)
                    .fontWeight(.semibold)
                    .multilineTextAlignment(.center)
                    .foregroundColor(.black)
                    .padding(.horizontal, 26)
                    .padding(.bottom, 24)
                    .lineLimit(nil)
//                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .frame(maxWidth: .infinity, minHeight: 410)
//        .padding(25)
        .background(
            RoundedRectangle(cornerRadius: 45)
                .fill(Color.white)
                .shadow(color: .black.opacity(0.25), radius: 5, x: 0, y: 2)
        )
        
    }
}

struct QuestionCard_Previews: PreviewProvider {
    static var previews: some View {
        InitialQuestionCard()
            .previewLayout(.sizeThatFits)
    }
}
