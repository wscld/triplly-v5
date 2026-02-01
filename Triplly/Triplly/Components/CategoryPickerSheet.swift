import SwiftUI

struct CategoryPickerSheet: View {
    let categories: [CategoryModel]
    let currentCategoryId: String?
    let onSelect: (CategoryModel?) -> Void
    let onCreateCustom: @Sendable (String, String, String) async -> CategoryModel?
    @Environment(\.dismiss) private var dismiss

    @State private var showingAddCustom = false

    private var defaultCategories: [CategoryModel] {
        categories.filter { $0.isDefault }
    }

    private var customCategories: [CategoryModel] {
        categories.filter { !$0.isDefault }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Default categories grid
                    LazyVGrid(columns: [
                        GridItem(.flexible()),
                        GridItem(.flexible()),
                        GridItem(.flexible())
                    ], spacing: 12) {
                        // "None" option
                        noneCell

                        ForEach(defaultCategories.filter { $0.name != "other" }) { category in
                            categoryCell(category)
                        }

                        // "Other" last
                        if let other = defaultCategories.first(where: { $0.name == "other" }) {
                            categoryCell(other)
                        }
                    }

                    // Custom categories section
                    if !customCategories.isEmpty {
                        Divider()

                        Text("Custom")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(.secondary)

                        LazyVGrid(columns: [
                            GridItem(.flexible()),
                            GridItem(.flexible()),
                            GridItem(.flexible())
                        ], spacing: 12) {
                            ForEach(customCategories) { category in
                                categoryCell(category)
                            }
                        }
                    }

                    // Add custom button
                    Divider()

                    Button {
                        showingAddCustom = true
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: "plus.circle.fill")
                                .font(.system(size: 18))
                            Text("Add Custom Category")
                                .font(.subheadline.weight(.medium))
                        }
                        .foregroundStyle(Color.appPrimary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(Color.appPrimary.opacity(0.08))
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                        .overlay {
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .stroke(Color.appPrimary.opacity(0.2), lineWidth: 1)
                        }
                    }
                    .buttonStyle(.plain)
                }
                .padding(16)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Category")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
            .sheet(isPresented: $showingAddCustom) {
                AddCustomCategorySheet { name, icon, color in
                    let created = await onCreateCustom(name, icon, color)
                    if let created {
                        onSelect(created)
                        dismiss()
                    }
                }
            }
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
    }

    private var noneCell: some View {
        Button {
            onSelect(nil)
            dismiss()
        } label: {
            VStack(spacing: 8) {
                ZStack {
                    Circle()
                        .fill(Color(.systemGray5))
                        .frame(width: 44, height: 44)

                    Image(systemName: "xmark")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(.secondary)
                }

                Text("None")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(
                currentCategoryId == nil
                    ? Color(.systemGray5)
                    : Color(.systemBackground)
            )
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(
                        currentCategoryId == nil ? Color.appPrimary : Color.clear,
                        lineWidth: 2
                    )
            )
        }
        .buttonStyle(.plain)
    }

    private func categoryCell(_ category: CategoryModel) -> some View {
        let isSelected = currentCategoryId == category.id

        return Button {
            onSelect(category)
            dismiss()
        } label: {
            VStack(spacing: 8) {
                ZStack {
                    Circle()
                        .fill(isSelected ? category.swiftUIColor : category.backgroundColor)
                        .frame(width: 44, height: 44)

                    if category.isEmoji {
                        Text(category.icon)
                            .font(.system(size: 20))
                    } else {
                        Image(systemName: category.icon)
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(isSelected ? .white : category.swiftUIColor)
                    }
                }

                Text(category.displayName)
                    .font(.caption)
                    .foregroundStyle(isSelected ? category.swiftUIColor : .primary)
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(
                isSelected
                    ? category.backgroundColor
                    : Color(.systemBackground)
            )
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(
                        isSelected ? category.swiftUIColor : Color.clear,
                        lineWidth: 2
                    )
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Add Custom Category Sheet
struct AddCustomCategorySheet: View {
    let onCreate: @Sendable (String, String, String) async -> Void
    @Environment(\.dismiss) private var dismiss

    @State private var name = ""
    @State private var emoji = ""
    @State private var selectedColor = "#EA580C"
    @State private var isCreating = false

    private let colorOptions = [
        "#EA580C", "#A16207", "#9333EA", "#2563EB", "#7C3AED",
        "#16A34A", "#06B6D4", "#DB2777", "#4F46E5", "#E11D48",
        "#059669", "#D97706", "#0D9488", "#EF4444", "#3B82F6",
    ]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Preview
                    VStack(spacing: 8) {
                        ZStack {
                            Circle()
                                .fill(Color(hex: selectedColor))
                                .frame(width: 56, height: 56)

                            if !emoji.isEmpty {
                                Text(emoji)
                                    .font(.system(size: 28))
                            } else {
                                Image(systemName: "tag.fill")
                                    .font(.system(size: 22, weight: .semibold))
                                    .foregroundStyle(.white)
                            }
                        }

                        Text(name.isEmpty ? "Category Name" : name)
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(name.isEmpty ? .secondary : .primary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)

                    // Name field
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Name")
                            .font(.subheadline.weight(.medium))

                        TextField("e.g. Live Music", text: $name)
                            .padding(14)
                            .background(Color(.systemBackground))
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    }

                    // Emoji field
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Emoji Icon")
                            .font(.subheadline.weight(.medium))

                        TextField("e.g. 🎸", text: $emoji)
                            .padding(14)
                            .background(Color(.systemBackground))
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                            .onChange(of: emoji) { _, newValue in
                                // Only keep the last emoji character
                                if let last = newValue.last, last.unicodeScalars.allSatisfy({ !$0.isASCII }) {
                                    emoji = String(last)
                                } else if newValue.count > 1 {
                                    emoji = String(newValue.suffix(1))
                                }
                            }
                    }

                    // Color picker
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Color")
                            .font(.subheadline.weight(.medium))

                        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 5), spacing: 12) {
                            ForEach(colorOptions, id: \.self) { hex in
                                Button {
                                    selectedColor = hex
                                } label: {
                                    Circle()
                                        .fill(Color(hex: hex))
                                        .frame(width: 40, height: 40)
                                        .overlay(
                                            Circle()
                                                .stroke(.white, lineWidth: selectedColor == hex ? 3 : 0)
                                        )
                                        .overlay(
                                            Circle()
                                                .stroke(Color(hex: hex), lineWidth: selectedColor == hex ? 1 : 0)
                                                .padding(-2)
                                        )
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }

                    // Create button
                    Button {
                        isCreating = true
                        Task {
                            let icon = emoji.isEmpty ? "tag.fill" : emoji
                            await onCreate(name, icon, selectedColor)
                            isCreating = false
                            dismiss()
                        }
                    } label: {
                        HStack {
                            if isCreating {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            } else {
                                Image(systemName: "plus.circle.fill")
                                Text("Create Category")
                            }
                        }
                        .font(.headline)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(name.isEmpty ? Color.gray : Color.appPrimary)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                    }
                    .disabled(name.isEmpty || isCreating)
                }
                .padding(24)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("New Category")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundStyle(.secondary)
                }
            }
        }
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
    }
}
