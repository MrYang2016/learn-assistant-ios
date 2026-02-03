import SwiftUI

struct AddKnowledgePointView: View {
  @Environment(\.dismiss) var dismiss
  @EnvironmentObject var viewModel: KnowledgeViewModel

  @State private var question = ""
  @State private var answer = ""
  @State private var isInReviewPlan = true
  @State private var isSubmitting = false
  @State private var errorMessage: String?

  @FocusState private var focusedField: Field?
  enum Field {
    case question
    case answer
  }

  var body: some View {
    NavigationView {
      VStack(spacing: 0) {
        ScrollView {
          VStack(alignment: .leading, spacing: 12) {
            // Date header
            HStack {
              Spacer()
              Text(Date().formatted(date: .long, time: .shortened))
                .font(.caption)
                .foregroundColor(.secondary)
              Spacer()
            }
            .padding(.bottom, 8)

            // Question (Title)
            TextField("Question", text: $question, axis: .vertical)
              .font(.system(.title, design: .default).weight(.bold))
              .focused($focusedField, equals: .question)
              .submitLabel(.next)
              .onSubmit {
                focusedField = .answer
              }

            // Answer (Body)
            TextField("Answer", text: $answer, axis: .vertical)
              .font(.body)
              .focused($focusedField, equals: .answer)
              .frame(minHeight: 200, alignment: .topLeading)
          }
          .padding()
        }

        // Bottom toolbar for Review Plan
        VStack(spacing: 0) {
          Divider()
          HStack {
            Button(action: {
              isInReviewPlan.toggle()
            }) {
              HStack {
                Image(systemName: isInReviewPlan ? "checkmark.circle.fill" : "circle")
                  .font(.system(size: 20))
                Text(isInReviewPlan ? "In Review Plan" : "Not in Review Plan")
                  .font(.subheadline)
              }
            }
            .foregroundColor(isInReviewPlan ? .accentColor : .secondary)

            Spacer()

            if let errorMessage = errorMessage {
              Text(errorMessage)
                .foregroundColor(.red)
                .font(.caption)
                .lineLimit(1)
            }
          }
          .padding()
          .background(Color(uiColor: .systemBackground))
        }
      }
      .navigationTitle("")
      .navigationBarTitleDisplayMode(.inline)
      .toolbar {
        ToolbarItem(placement: .cancellationAction) {
          Button("Cancel") {
            dismiss()
          }
          .disabled(isSubmitting)
        }

        ToolbarItem(placement: .confirmationAction) {
          Button("Done") {
            saveKnowledgePoint()
          }
          .disabled(question.isEmpty || answer.isEmpty || isSubmitting)
          .bold()
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
      .onAppear {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
          focusedField = .question
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
    .environmentObject(KnowledgeViewModel())
}
