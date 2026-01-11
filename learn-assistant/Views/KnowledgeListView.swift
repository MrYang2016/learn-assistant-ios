import SwiftUI

struct KnowledgeListView: View {
    @EnvironmentObject var viewModel: KnowledgeViewModel
    @State private var showingAddSheet = false
    @State private var showingEditSheet = false
    @State private var selectedPoint: KnowledgePoint?
    @State private var showingDeleteAlert = false
    @State private var pointToDelete: KnowledgePoint?
    
    var body: some View {
        NavigationView {
            ZStack {
                if viewModel.knowledgePoints.isEmpty && !viewModel.isLoading {
                    emptyStateView
                } else {
                    listView
                }
            }
            .navigationTitle("Knowledge")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingAddSheet = true }) {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingAddSheet) {
                AddKnowledgePointView()
                    .environmentObject(viewModel)
            }
            .sheet(item: $selectedPoint) { point in
                EditKnowledgePointView(point: point)
                    .environmentObject(viewModel)
            }
            .alert("Delete Knowledge Point", isPresented: $showingDeleteAlert, presenting: pointToDelete) { point in
                Button("Cancel", role: .cancel) { }
                Button("Delete", role: .destructive) {
                    deletePoint(point)
                }
            } message: { point in
                Text("Are you sure you want to delete '\(point.question)'?")
            }
            .task {
                if viewModel.knowledgePoints.isEmpty {
                    await viewModel.loadKnowledgePoints()
                }
            }
            .refreshable {
                await viewModel.loadKnowledgePoints(refresh: true)
            }
        }
    }
    
    private var listView: some View {
        List {
            ForEach(viewModel.knowledgePoints) { point in
                KnowledgePointRow(point: point)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        selectedPoint = point
                    }
                    .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                        Button(role: .destructive) {
                            pointToDelete = point
                            showingDeleteAlert = true
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                        
                        Button {
                            selectedPoint = point
                        } label: {
                            Label("Edit", systemImage: "pencil")
                        }
                        .tint(.blue)
                    }
                    .onAppear {
                        if point.id == viewModel.knowledgePoints.last?.id {
                            Task {
                                await viewModel.loadKnowledgePoints()
                            }
                        }
                    }
            }
            
            if viewModel.isLoading {
                HStack {
                    Spacer()
                    ProgressView()
                    Spacer()
                }
            }
        }
        .listStyle(.insetGrouped)
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: "book.closed")
                .font(.system(size: 60))
                .foregroundColor(.gray)
            
            Text("No Knowledge Points")
                .font(.title2)
                .fontWeight(.semibold)
            
            Text("Start adding knowledge points to begin your learning journey")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            Button(action: { showingAddSheet = true }) {
                Label("Add Knowledge Point", systemImage: "plus.circle.fill")
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding()
                    .background(Color.blue)
                    .cornerRadius(12)
            }
        }
        .padding()
    }
    
    private func deletePoint(_ point: KnowledgePoint) {
        Task {
            do {
                try await viewModel.deleteKnowledgePoint(id: point.id)
            } catch {
                // Handle error
                print("Delete error: \(error)")
            }
        }
    }
}

struct KnowledgePointRow: View {
    let point: KnowledgePoint
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(point.question)
                .font(.headline)
                .lineLimit(2)
            
            Text(point.answer)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .lineLimit(3)
            
            HStack {
                if point.isInReviewPlan {
                    Label("In Review", systemImage: "calendar")
                        .font(.caption)
                        .foregroundColor(.blue)
                }
                
                Spacer()
                
                Text(formattedDate(point.createdAt))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
    
    private func formattedDate(_ dateString: String) -> String {
        let formatter = ISO8601DateFormatter()
        guard let date = formatter.date(from: dateString) else {
            return dateString
        }
        
        let displayFormatter = DateFormatter()
        displayFormatter.dateStyle = .medium
        displayFormatter.timeStyle = .none
        return displayFormatter.string(from: date)
    }
}

#Preview {
    KnowledgeListView()
        .environmentObject(KnowledgeViewModel(authService: AuthService()))
}
