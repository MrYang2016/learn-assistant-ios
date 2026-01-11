import SwiftUI

struct AddKnowledgePointView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var viewModel: KnowledgeViewModel
    
    @State private var question = ""
    @State private var answer = ""
    @State private var isInReviewPlan = true
    @State private var isSubmitting = false
    @State private var errorMessage: String?
    
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
                    Toggle("Add to Review Plan", isOn: $isInReviewPlan)
                } footer: {
                    Text("If enabled, this knowledge point will be added to your spaced repetition review schedule")
                }
                
                if let errorMessage = errorMessage {
                    Section {
                        Text(errorMessage)
                            .foregroundColor(.red)
                            .font(.caption)
                    }
                }
            }
            .navigationTitle("New Knowledge Point")
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
                        saveKnowledgePoint()
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
    
    private func saveKnowledgePoint() {
        isSubmitting = true
        errorMessage = nil
        
        Task {
            do {
                try await viewModel.createKnowledgePoint(
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
    AddKnowledgePointView()
        .environmentObject(KnowledgeViewModel(authService: AuthService()))
}
