import SwiftUI

struct TodosSheet: View {
    @ObservedObject var viewModel: TravelDetailViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var newTodoTitle = ""
    @FocusState private var isInputFocused: Bool

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Progress Header
                progressHeader
                    .padding(.horizontal, 24)
                    .padding(.top, 16)

                // Todos List
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(viewModel.todos) { todo in
                            TodoRow(todo: todo) {
                                Task { await viewModel.toggleTodo(todo) }
                            } onDelete: {
                                Task { await viewModel.deleteTodo(todo) }
                            }
                        }
                    }
                    .padding(24)
                }

                // Add Todo Input
                addTodoInput
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Checklist")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
    }

    private var progressHeader: some View {
        VStack(spacing: 12) {
            HStack {
                Text("Progress")
                    .font(.headline)

                Spacer()

                let completed = viewModel.todos.filter { $0.isCompleted }.count
                Text("\(completed)/\(viewModel.todos.count)")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color(.systemGray4))
                        .frame(height: 8)

                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.appPrimary)
                        .frame(width: geo.size.width * viewModel.todoProgress, height: 8)
                        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: viewModel.todoProgress)
                }
            }
            .frame(height: 8)
        }
        .padding(16)
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }

    private var addTodoInput: some View {
        HStack(spacing: 12) {
            HStack(spacing: 12) {
                Image(systemName: "plus.circle")
                    .foregroundStyle(.secondary)

                TextField("Add a task...", text: $newTodoTitle)
                    .focused($isInputFocused)
                    .onSubmit {
                        addTodo()
                    }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(Color(.systemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))

            if !newTodoTitle.isEmpty {
                Button {
                    addTodo()
                } label: {
                    Image(systemName: "arrow.up.circle.fill")
                        .font(.title)
                        .foregroundStyle(Color.appPrimary)
                }
            }
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 16)
        .background(Color(.systemBackground))
    }

    private func addTodo() {
        guard !newTodoTitle.isEmpty else { return }
        let title = newTodoTitle
        newTodoTitle = ""

        Task {
            await viewModel.createTodo(title)
        }
    }
}

// MARK: - Todo Row
struct TodoRow: View {
    let todo: Todo
    let onToggle: () -> Void
    let onDelete: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            Button(action: onToggle) {
                Image(systemName: todo.isCompleted ? "checkmark.circle.fill" : "circle")
                    .font(.title2)
                    .foregroundStyle(todo.isCompleted ? Color.appPrimary : Color.secondary)
            }

            Text(todo.title)
                .font(.body)
                .foregroundStyle(todo.isCompleted ? Color.secondary : .primary)
                .strikethrough(todo.isCompleted)
                .frame(maxWidth: .infinity, alignment: .leading)

            Button(action: onDelete) {
                Image(systemName: "trash")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(12)
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: todo.isCompleted)
    }
}

#Preview {
    TodosSheet(viewModel: TravelDetailViewModel(travelId: "1"))
}
