import SwiftUI

struct ChatView: View {
    @EnvironmentObject var viewModel: ChatViewModel
    @State private var inputText = ""
    @State private var showingSources = false
    @FocusState private var isInputFocused: Bool
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                if viewModel.messages.isEmpty {
                    emptyStateView
                } else {
                    messagesView
                }
                
                if !viewModel.sources.isEmpty {
                    sourcesButton
                }
                
                inputBar
            }
            .navigationTitle("AI Chat")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { viewModel.clearChat() }) {
                        Image(systemName: "trash")
                    }
                    .disabled(viewModel.messages.isEmpty)
                }
            }
            .sheet(isPresented: $showingSources) {
                SourcesView(sources: viewModel.sources)
            }
        }
    }
    
    private var emptyStateView: some View {
        ScrollView {
            VStack(spacing: 24) {
                Spacer()
                
                Image(systemName: "message.circle.fill")
                    .font(.system(size: 60))
                    .foregroundColor(.blue)
                
                Text("AI Learning Assistant")
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Text("Ask questions about your knowledge base and get intelligent answers")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                
                VStack(alignment: .leading, spacing: 12) {
                    Text("Example questions:")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .fontWeight(.semibold)
                    
                    ForEach([
                        "Explain the concept of active recall",
                        "How does spaced repetition work?",
                        "What's the best way to study?"
                    ], id: \.self) { example in
                        Button(action: {
                            inputText = example
                        }) {
                            Text(example)
                                .font(.subheadline)
                                .foregroundColor(.primary)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 10)
                                .background(Color.gray.opacity(0.1))
                                .cornerRadius(12)
                        }
                    }
                }
                .padding()
                
                Spacer()
            }
            .padding()
        }
    }
    
    private var messagesView: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: 16) {
                    ForEach(viewModel.messages) { message in
                        MessageBubble(message: message)
                            .id(message.id)
                    }
                    
                    if viewModel.isLoading {
                        HStack {
                            ProgressView()
                                .padding(.leading, 12)
                            Text("Thinking...")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Spacer()
                        }
                    }
                }
                .padding()
            }
            .onChange(of: viewModel.messages.count) { _ in
                if let lastMessage = viewModel.messages.last {
                    withAnimation {
                        proxy.scrollTo(lastMessage.id, anchor: .bottom)
                    }
                }
            }
        }
    }
    
    private var sourcesButton: some View {
        Button(action: { showingSources = true }) {
            HStack {
                Image(systemName: "doc.text.magnifyingglass")
                Text("View \(viewModel.sources.count) source(s)")
                    .font(.subheadline)
            }
            .foregroundColor(.blue)
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(Color.blue.opacity(0.1))
            .cornerRadius(20)
        }
        .padding(.horizontal)
        .padding(.bottom, 8)
    }
    
    private var inputBar: some View {
        HStack(alignment: .bottom, spacing: 12) {
            TextField("Ask a question...", text: $inputText, axis: .vertical)
                .textFieldStyle(.roundedBorder)
                .lineLimit(1...5)
                .focused($isInputFocused)
            
            Button(action: sendMessage) {
                Image(systemName: "arrow.up.circle.fill")
                    .font(.system(size: 32))
                    .foregroundColor(inputText.isEmpty ? .gray : .blue)
            }
            .disabled(inputText.isEmpty || viewModel.isLoading)
        }
        .padding()
        .background(Color(uiColor: .systemBackground))
    }
    
    private func sendMessage() {
        let text = inputText
        inputText = ""
        isInputFocused = false
        
        Task {
            await viewModel.sendMessage(text)
        }
    }
}

struct MessageBubble: View {
    let message: ChatMessage
    
    var body: some View {
        HStack {
            if message.role == .user {
                Spacer(minLength: 60)
            }
            
            VStack(alignment: message.role == .user ? .trailing : .leading, spacing: 4) {
                Text(message.content)
                    .padding(12)
                    .background(message.role == .user ? Color.blue : Color.gray.opacity(0.2))
                    .foregroundColor(message.role == .user ? .white : .primary)
                    .cornerRadius(16)
                
                Text(formatTime(message.timestamp))
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            
            if message.role == .assistant {
                Spacer(minLength: 60)
            }
        }
    }
    
    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

struct SourcesView: View {
    @Environment(\.dismiss) var dismiss
    let sources: [Source]
    
    var body: some View {
        NavigationView {
            List(sources) { source in
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text(source.question)
                            .font(.headline)
                        
                        Spacer()
                        
                        Text("\(Int(source.similarity * 100))%")
                            .font(.caption)
                            .foregroundColor(.white)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.blue)
                            .cornerRadius(8)
                    }
                    
                    Text(source.answer)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .padding(.vertical, 4)
            }
            .navigationTitle("Knowledge Sources")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

#Preview {
    ChatView()
        .environmentObject(ChatViewModel(authService: AuthService()))
}
