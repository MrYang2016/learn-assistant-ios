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

  @FocusState private var focusedField: Field?
  enum Field {
    case question
    case answer
  }

  init(point: KnowledgePoint) {
    self.point = point
    _question = State(initialValue: point.question)
    _answer = State(initialValue: point.answer)
    _isInReviewPlan = State(initialValue: point.isInReviewPlan)
  }

  var body: some View {
    NavigationView {
      VStack(spacing: 0) {
        ScrollView {
          VStack(alignment: .leading, spacing: 12) {
            // Date header
            HStack {
              Spacer()
              if let date = ISO8601DateFormatter().date(from: point.updatedAt) {
                Text(date.formatted(date: .long, time: .shortened))
                  .font(.caption)
                  .foregroundColor(.secondary)
              }
              Spacer()
            }
            .padding(.bottom, 8)

            TextField("Question", text: $question, axis: .vertical)
              .font(.system(.title, design: .default).weight(.bold))
              .focused($focusedField, equals: .question)
              .submitLabel(.next)
              .onSubmit {
                focusedField = .answer
              }

            TextField("Answer", text: $answer, axis: .vertical)
              .font(.body)
              .focused($focusedField, equals: .answer)
              .frame(minHeight: 200, alignment: .topLeading)
          }
          .padding()
        }

        // Bottom toolbar
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
            updateKnowledgePoint()
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
    question: "What is SwiftUI?",
    answer:
      "SwiftUI is a modern UI framework for building user interfaces across all Apple platforms.",
    createdAt: ISO8601DateFormatter().string(from: Date()),
    updatedAt: ISO8601DateFormatter().string(from: Date()),
    isInReviewPlan: true
  )

  return EditKnowledgePointView(point: samplePoint)
    .environmentObject(KnowledgeViewModel())
}
