import SwiftUI

// MARK: - Native-Style Text Field
struct AppTextField: View {
    let title: String
    let placeholder: String
    @Binding var text: String
    var icon: String? = nil
    var isSecure: Bool = false
    var keyboardType: UIKeyboardType = .default
    var autocapitalization: TextInputAutocapitalization = .sentences
    var errorMessage: String? = nil

    @FocusState private var isFocused: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Label
            Text(title)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundStyle(Color.textPrimary)

            // Input Field
            HStack(spacing: 12) {
                if let icon = icon {
                    Image(systemName: icon)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundStyle(isFocused ? Color.appPrimary : Color.secondary)
                        .frame(width: 20)
                }

                Group {
                    if isSecure {
                        SecureField(placeholder, text: $text)
                    } else {
                        TextField(placeholder, text: $text)
                            .keyboardType(keyboardType)
                            .textInputAutocapitalization(autocapitalization)
                    }
                }
                .font(.body)
                .focused($isFocused)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .background(Color(.systemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(
                        errorMessage != nil ? Color.red :
                            isFocused ? Color.appPrimary : Color(.systemGray4),
                        lineWidth: errorMessage != nil || isFocused ? 2 : 1
                    )
            }

            // Error Message
            if let error = errorMessage {
                HStack(spacing: 4) {
                    Image(systemName: "exclamationmark.circle.fill")
                        .font(.caption)
                    Text(error)
                        .font(.caption)
                }
                .foregroundStyle(.red)
            }
        }
        .animation(.easeInOut(duration: 0.15), value: isFocused)
        .animation(.easeInOut(duration: 0.15), value: errorMessage)
    }
}

// MARK: - Native-Style Text Editor
struct AppTextEditor: View {
    let title: String
    let placeholder: String
    @Binding var text: String
    var minHeight: CGFloat = 100

    @FocusState private var isFocused: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundStyle(Color.textPrimary)

            ZStack(alignment: .topLeading) {
                if text.isEmpty && !isFocused {
                    Text(placeholder)
                        .font(.body)
                        .foregroundStyle(Color(.placeholderText))
                        .padding(.horizontal, 16)
                        .padding(.vertical, 14)
                }

                TextEditor(text: $text)
                    .font(.body)
                    .scrollContentBackground(.hidden)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .focused($isFocused)
            }
            .frame(minHeight: minHeight)
            .background(Color(.systemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(
                        isFocused ? Color.appPrimary : Color(.systemGray4),
                        lineWidth: isFocused ? 2 : 1
                    )
            }
        }
        .animation(.easeInOut(duration: 0.15), value: isFocused)
    }
}

// MARK: - Native Search Bar
struct AppSearchBar: View {
    @Binding var text: String
    var placeholder: String = "Search"

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 16, weight: .medium))
                .foregroundStyle(Color(.placeholderText))

            TextField(placeholder, text: $text)
                .font(.body)

            if !text.isEmpty {
                Button {
                    text = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 16))
                        .foregroundStyle(Color(.placeholderText))
                }
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
    }
}

// MARK: - Primary Action Button
struct AppButton: View {
    let title: String
    var icon: String? = nil
    var style: ButtonStyleType = .primary
    var isLoading: Bool = false
    var isDisabled: Bool = false
    let action: () -> Void

    enum ButtonStyleType {
        case primary
        case secondary
        case destructive
    }

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                if isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: style == .primary ? .white : Color.appPrimary))
                        .scaleEffect(0.8)
                } else {
                    if let icon = icon {
                        Image(systemName: icon)
                            .font(.system(size: 16, weight: .semibold))
                    }
                    Text(title)
                        .font(.body)
                        .fontWeight(.semibold)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .foregroundStyle(foregroundColor)
            .background(backgroundColor)
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            .overlay {
                if style == .secondary {
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .stroke(Color(.systemGray4), lineWidth: 1)
                }
            }
        }
        .disabled(isLoading || isDisabled)
        .opacity(isDisabled ? 0.5 : 1)
    }

    private var foregroundColor: Color {
        switch style {
        case .primary: return .white
        case .secondary: return Color.textPrimary
        case .destructive: return .white
        }
    }

    private var backgroundColor: Color {
        switch style {
        case .primary: return Color.appPrimary
        case .secondary: return Color(.systemBackground)
        case .destructive: return .red
        }
    }
}

// MARK: - Date Picker Row
struct AppDatePicker: View {
    let title: String
    @Binding var date: Date?
    var minimumDate: Date? = nil

    @State private var showPicker = false
    @State private var tempDate = Date()

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundStyle(Color.textPrimary)

            Button {
                tempDate = date ?? minimumDate ?? Date()
                showPicker = true
            } label: {
                HStack {
                    Image(systemName: "calendar")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundStyle(Color.secondary)

                    if let date = date {
                        Text(date, style: .date)
                            .font(.body)
                            .foregroundStyle(Color.textPrimary)
                    } else {
                        Text("Select date")
                            .font(.body)
                            .foregroundStyle(Color(.placeholderText))
                    }

                    Spacer()

                    if date != nil {
                        Button {
                            self.date = nil
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .font(.system(size: 16))
                                .foregroundStyle(Color(.placeholderText))
                        }
                    } else {
                        Image(systemName: "chevron.right")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundStyle(Color(.placeholderText))
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 14)
                .background(Color(.systemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                .overlay {
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .stroke(Color(.systemGray4), lineWidth: 1)
                }
            }
            .buttonStyle(.plain)
        }
        .sheet(isPresented: $showPicker) {
            NavigationStack {
                DatePicker(
                    "Select Date",
                    selection: $tempDate,
                    in: (minimumDate ?? .distantPast)...,
                    displayedComponents: .date
                )
                .datePickerStyle(.graphical)
                .tint(Color.appPrimary)
                .padding()
                .navigationTitle(title)
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Cancel") { showPicker = false }
                    }
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Done") {
                            date = tempDate
                            showPicker = false
                        }
                        .fontWeight(.semibold)
                    }
                }
            }
            .presentationDetents([.medium])
        }
    }
}

// MARK: - Date Range Picker
struct AppDateRangePicker: View {
    let title: String
    @Binding var startDate: Date?
    @Binding var endDate: Date?

    @State private var showPicker = false
    @State private var tempStartDate = Date()
    @State private var tempEndDate = Date()
    @State private var selectingEndDate = false

    private var dateRangeText: String? {
        guard let start = startDate else { return nil }

        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"

        if let end = endDate {
            let yearFormatter = DateFormatter()
            yearFormatter.dateFormat = "MMM d, yyyy"

            let startYear = Calendar.current.component(.year, from: start)
            let endYear = Calendar.current.component(.year, from: end)

            if startYear == endYear {
                return "\(formatter.string(from: start)) - \(yearFormatter.string(from: end))"
            } else {
                return "\(yearFormatter.string(from: start)) - \(yearFormatter.string(from: end))"
            }
        } else {
            formatter.dateFormat = "MMM d, yyyy"
            return formatter.string(from: start)
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundStyle(Color.textPrimary)

            Button {
                tempStartDate = startDate ?? Date()
                tempEndDate = endDate ?? (startDate ?? Date())
                selectingEndDate = false
                showPicker = true
            } label: {
                HStack {
                    Image(systemName: "calendar")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundStyle(Color.secondary)

                    if let text = dateRangeText {
                        Text(text)
                            .font(.body)
                            .foregroundStyle(Color.textPrimary)
                    } else {
                        Text("Select dates")
                            .font(.body)
                            .foregroundStyle(Color(.placeholderText))
                    }

                    Spacer()

                    if startDate != nil {
                        Button {
                            startDate = nil
                            endDate = nil
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .font(.system(size: 16))
                                .foregroundStyle(Color(.placeholderText))
                        }
                    } else {
                        Image(systemName: "chevron.right")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundStyle(Color(.placeholderText))
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 14)
                .background(Color(.systemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                .overlay {
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .stroke(Color(.systemGray4), lineWidth: 1)
                }
            }
            .buttonStyle(.plain)
        }
        .sheet(isPresented: $showPicker) {
            DateRangePickerSheet(
                startDate: $tempStartDate,
                endDate: $tempEndDate,
                selectingEndDate: $selectingEndDate,
                onSave: {
                    startDate = tempStartDate
                    endDate = tempEndDate > tempStartDate ? tempEndDate : nil
                    showPicker = false
                },
                onCancel: {
                    showPicker = false
                }
            )
        }
    }
}

// MARK: - Date Range Picker Sheet
private struct DateRangePickerSheet: View {
    @Binding var startDate: Date
    @Binding var endDate: Date
    @Binding var selectingEndDate: Bool
    let onSave: () -> Void
    let onCancel: () -> Void

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Date selection tabs
                HStack(spacing: 0) {
                    DateTabButton(
                        title: "Start Date",
                        date: startDate,
                        isSelected: !selectingEndDate
                    ) {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            selectingEndDate = false
                        }
                    }

                    DateTabButton(
                        title: "End Date",
                        date: endDate,
                        isSelected: selectingEndDate
                    ) {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            selectingEndDate = true
                        }
                    }
                }
                .padding(.horizontal)
                .padding(.top, 8)

                // Calendar
                if selectingEndDate {
                    DatePicker(
                        "End Date",
                        selection: $endDate,
                        in: startDate...,
                        displayedComponents: .date
                    )
                    .datePickerStyle(.graphical)
                    .tint(Color.appPrimary)
                    .padding(.horizontal)
                } else {
                    DatePicker(
                        "Start Date",
                        selection: $startDate,
                        displayedComponents: .date
                    )
                    .datePickerStyle(.graphical)
                    .tint(Color.appPrimary)
                    .padding(.horizontal)
                    .onChange(of: startDate) { _, newValue in
                        if endDate < newValue {
                            endDate = newValue
                        }
                    }
                }

                Spacer()
            }
            .navigationTitle("Select Dates")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel", action: onCancel)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done", action: onSave)
                        .fontWeight(.semibold)
                }
            }
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
    }
}

// MARK: - Date Tab Button
private struct DateTabButton: View {
    let title: String
    let date: Date
    let isSelected: Bool
    let action: () -> Void

    private var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d, yyyy"
        return formatter.string(from: date)
    }

    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Text(title)
                    .font(.caption)
                    .foregroundStyle(isSelected ? Color.appPrimary : .secondary)

                Text(formattedDate)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(isSelected ? Color.appPrimary : .primary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(isSelected ? Color.appPrimary.opacity(0.1) : Color.clear)
            .clipShape(RoundedRectangle(cornerRadius: 10))
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    ScrollView {
        VStack(spacing: 24) {
            AppTextField(
                title: "Email",
                placeholder: "Enter your email",
                text: .constant(""),
                icon: "envelope"
            )

            AppTextField(
                title: "Password",
                placeholder: "Enter your password",
                text: .constant(""),
                icon: "lock",
                isSecure: true
            )

            AppTextField(
                title: "Email with error",
                placeholder: "Enter your email",
                text: .constant("invalid"),
                icon: "envelope",
                errorMessage: "Please enter a valid email"
            )

            AppTextEditor(
                title: "Description",
                placeholder: "Add a description...",
                text: .constant("")
            )

            AppSearchBar(text: .constant(""))

            AppButton(title: "Continue", icon: "arrow.right") {}

            AppButton(title: "Cancel", style: .secondary) {}

            AppDatePicker(title: "Start Date", date: .constant(nil))

            AppDateRangePicker(
                title: "Travel Dates",
                startDate: .constant(Date()),
                endDate: .constant(Date().addingTimeInterval(86400 * 7))
            )
        }
        .padding()
    }
    .background(Color(.systemGroupedBackground))
}
