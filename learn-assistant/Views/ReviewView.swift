import SwiftUI

struct ReviewView: View {
    @EnvironmentObject var viewModel: ReviewViewModel
    
    var body: some View {
        NavigationView {
            ZStack {
                if viewModel.isLoading && viewModel.reviews.isEmpty {
                    ProgressView()
                } else if viewModel.reviews.isEmpty {
                    emptyStateView
                } else if viewModel.currentIndex >= viewModel.reviews.count {
                    completedView
                } else {
                    reviewCardView
                }
            }
            .navigationTitle("Review")
            .task {
                if viewModel.reviews.isEmpty {
                    await viewModel.loadReviews()
                }
            }
        }
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 60))
                .foregroundColor(.green)
            
            Text("All Caught Up!")
                .font(.title2)
                .fontWeight(.semibold)
            
            Text("No reviews due today. Great job!")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            Button(action: {
                Task {
                    await viewModel.loadReviews()
                }
            }) {
                Label("Refresh", systemImage: "arrow.clockwise")
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding()
                    .background(Color.blue)
                    .cornerRadius(12)
            }
        }
        .padding()
    }
    
    private var completedView: some View {
        VStack(spacing: 24) {
            Image(systemName: "star.circle.fill")
                .font(.system(size: 80))
                .foregroundColor(.yellow)
            
            Text("Reviews Complete!")
                .font(.title)
                .fontWeight(.bold)
            
            Text("You've completed all \(viewModel.totalCount) review(s) for today")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            Button(action: {
                Task {
                    await viewModel.loadReviews()
                }
            }) {
                Label("Refresh", systemImage: "arrow.clockwise")
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.blue)
                    .cornerRadius(12)
            }
            .padding(.horizontal)
        }
        .padding()
    }
    
    private var reviewCardView: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Progress indicator
                VStack(spacing: 8) {
                    HStack {
                        Text("Progress")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Spacer()
                        
                        Text("\(viewModel.completedCount + 1) of \(viewModel.totalCount)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    ProgressView(value: Double(viewModel.completedCount), total: Double(viewModel.totalCount))
                        .tint(.blue)
                }
                .padding()
                
                if let review = viewModel.currentReview {
                    ReviewCard(
                        review: review,
                        showAnswer: viewModel.showAnswer,
                        recallText: $viewModel.recallText,
                        onToggleAnswer: { viewModel.toggleAnswer() },
                        onComplete: {
                            Task {
                                await viewModel.completeCurrentReview()
                            }
                        }
                    )
                }
            }
            .padding()
        }
    }
}

struct ReviewCard: View {
    let review: ReviewSchedule
    let showAnswer: Bool
    @Binding var recallText: String
    let onToggleAnswer: () -> Void
    let onComplete: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            // Review badge
            HStack {
                Label("Review #\(review.reviewNumber)", systemImage: "calendar")
                    .font(.caption)
                    .foregroundColor(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.blue)
                    .cornerRadius(8)
                
                Spacer()
            }
            
            // Question
            VStack(alignment: .leading, spacing: 8) {
                Text("Question")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .textCase(.uppercase)
                
                Text(review.knowledgePoints.question)
                    .font(.title3)
                    .fontWeight(.semibold)
            }
            
            Divider()
            
            // Recall input
            VStack(alignment: .leading, spacing: 8) {
                Text("Your Recall")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .textCase(.uppercase)
                
                TextEditor(text: $recallText)
                    .frame(minHeight: 100)
                    .padding(8)
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(8)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                    )
            }
            
            // Show answer button
            Button(action: onToggleAnswer) {
                HStack {
                    Image(systemName: showAnswer ? "eye.slash" : "eye")
                    Text(showAnswer ? "Hide Answer" : "Show Answer")
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(showAnswer ? Color.gray.opacity(0.2) : Color.blue)
                .foregroundColor(showAnswer ? .primary : .white)
                .cornerRadius(12)
            }
            
            // Answer section
            if showAnswer {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Correct Answer")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .textCase(.uppercase)
                    
                    Text(review.knowledgePoints.answer)
                        .font(.body)
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color.green.opacity(0.1))
                        .cornerRadius(8)
                }
                .transition(.move(edge: .top).combined(with: .opacity))
                
                // Complete button
                Button(action: onComplete) {
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                        Text("Mark as Reviewed")
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.green)
                    .foregroundColor(.white)
                    .cornerRadius(12)
                }
            }
        }
        .padding()
        .background(Color(uiColor: .systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.1), radius: 10)
    }
}

#Preview {
    ReviewView()
        .environmentObject(ReviewViewModel(authService: AuthService()))
}
