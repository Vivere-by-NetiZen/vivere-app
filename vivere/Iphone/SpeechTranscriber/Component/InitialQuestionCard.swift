import SwiftUI

struct InitialQuestionCard: View {
    var question: String = "Apakah kalian punya lagu atau film favorit bersama?"
    
    var body: some View {
        VStack() {
            Text("Pertanyaan")
                .font(.title3)
                .foregroundColor(.black)
                .padding(.top, 25)
            Spacer()
            Text(question)
                .font(.title.bold())
                .multilineTextAlignment(.center)
                .foregroundColor(.black)
                .padding(.horizontal)
                .padding(.bottom, 50)
                .lineLimit(nil)
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: 400)
        .background(
            RoundedRectangle(cornerRadius: 45)
                .fill(Color.white)
                .shadow(color: .black.opacity(0.25), radius: 5, x: 0, y: 2)
        )
        .padding(25)
    }
}

struct QuestionCard_Previews: PreviewProvider {
    static var previews: some View {
        InitialQuestionCard()
            .previewLayout(.sizeThatFits)
    }
}
