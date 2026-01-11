import SwiftUI

struct EditKnowledgePointView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var viewModel: KnowledgeViewModel
    
    let point: KnowledgePoint
    
    @State private var question: String
    @State private var answer: String
    @State private var isInReviewPlan: Bool
    @State private var isSubmitting = false
    @State private var errorMessage: String?
    
    init(point: KnowledgePoint) {
        self.point = point
        _question = State(initialValue: point.question)
        _answer = State(initialValue: point.answer)
        _isInReviewPlan = State(initialValue: point.isInReviewPlan)
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section {
                    TextField("Question", text: $question, axis: .vertical)
                        .lineLimit(3...6)
                } header: {
                    Text("Question")
                }
                
                Section {
                    TextEditor(text: $answer)
                        .frame(minHeight: 150)
                } header: {
                    Text("Answer")
                }
                
                Section {
                    Toggle("In Review Plan", isOn: $isInReviewPlan)
                } footer: {
                    Text("If enabled, this knowledge point will be included in your review schedule")
                }
                
                if let errorMessage = errorMessage {
                    Section {
                        Text(errorMessage)
                            .foregroundColor(.red)
                            .font(.caption)
                    }
                }
            }
            .navigationTitle("Edit Knowledge Point")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .disabled(isSubmitting)
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        updateKnowledgePoint()
                    }
                    .disabled(question.isEmpty || answer.isEmpty || isSubmitting)
                }
            }
            .overlay {
                if isSubmitting {
                    ProgressView()
                        .scaleEffect(1.5)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(Color.black.opacity(0.2))
                }
            }
        }
    }
    
    private func updateKnowledgePoint() {
        isSubmitting = true
        errorMessage = nil
        
        Task {
            do {
                try await viewModel.updateKnowledgePoint(
                    id: point.id,
                    question: question.trimmingCharacters(in: .whitespacesAndNewlines),
                    answer: answer.trimmingCharacters(in: .whitespacesAndNewlines),
                    isInReviewPlan: isInReviewPlan
                )
                
                await MainActor.run {
                    dismiss()
                }
            } catch {
                await MainActor.run {
                    errorMessage = error.localizedDescription
                    isSubmitting = false
                }
            }
        }
    }
}

#Preview {
    let samplePoint = KnowledgePoint(
        id: "1",
        userId: "user1",
        question: "What is SwiftUI?",
        answer: "SwiftUI is a modern UI framework for building user interfaces across all Apple platforms.",
        createdAt: ISO8601DateFormatter().string(from: Date()),
        updatedAt: ISO8601DateFormatter().string(from: Date()),
        isInReviewPlan: true
    )
    
    return EditKnowledgePointView(point: samplePoint)
        .environmentObject(KnowledgeViewModel(authService: AuthService()))
}
