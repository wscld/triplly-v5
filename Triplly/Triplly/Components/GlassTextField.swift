import SwiftUI

// MARK: - Glass Text Field
struct GlassTextField: View {
    let placeholder: String
    @Binding var text: String
    var icon: String?
    var isSecure: Bool = false
    var keyboardType: UIKeyboardType = .default
    var autocapitalization: TextInputAutocapitalization = .sentences
    var errorMessage: String?

    @FocusState private var isFocused: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 12) {
                if let icon = icon {
                    Image(systemName: icon)
                        .font(.system(size: 18))
                        .foregroundStyle(isFocused ? Color.appPrimary : Color.secondary)
                        .frame(width: 24)
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
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: LiquidGlass.smallCornerRadius, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: LiquidGlass.smallCornerRadius, style: .continuous)
                    .stroke(
                        errorMessage != nil ? Color.error :
                            isFocused ? Color.appPrimary : Color.borderLight,
                        lineWidth: isFocused || errorMessage != nil ? 2 : 1
                    )
            }
            .animation(.easeInOut(duration: 0.2), value: isFocused)

            if let error = errorMessage {
                Text(error)
                    .font(.caption)
                    .foregroundStyle(Color.error)
                    .padding(.leading, 4)
            }
        }
    }
}

// MARK: - Glass Text Editor
struct GlassTextEditor: View {
    let placeholder: String
    @Binding var text: String
    var minHeight: CGFloat = 100

    @FocusState private var isFocused: Bool

    var body: some View {
        ZStack(alignment: .topLeading) {
            if text.isEmpty {
                Text(placeholder)
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 18)
            }

            TextEditor(text: $text)
                .font(.body)
                .scrollContentBackground(.hidden)
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
                .focused($isFocused)
        }
        .frame(minHeight: minHeight)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: LiquidGlass.smallCornerRadius, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: LiquidGlass.smallCornerRadius, style: .continuous)
                .stroke(
                    isFocused ? Color.appPrimary : Color.borderLight,
                    lineWidth: isFocused ? 2 : 1
                )
        }
        .animation(.easeInOut(duration: 0.2), value: isFocused)
    }
}

// MARK: - Search Bar
struct GlassSearchBar: View {
    @Binding var text: String
    var placeholder: String = "Search"
    var onSubmit: (() -> Void)?

    @FocusState private var isFocused: Bool

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 16))
                .foregroundStyle(.secondary)

            TextField(placeholder, text: $text)
                .font(.body)
                .focused($isFocused)
                .onSubmit {
                    onSubmit?()
                }

            if !text.isEmpty {
                Button {
                    text = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 16))
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(.ultraThinMaterial)
        .clipShape(Capsule())
    }
}

// MARK: - Previews
#Preview("Text Fields") {
    ZStack {
        Color.appBackground.ignoresSafeArea()

        VStack(spacing: 20) {
            GlassTextField(
                placeholder: "Email",
                text: .constant(""),
                icon: "envelope"
            )

            GlassTextField(
                placeholder: "Password",
                text: .constant(""),
                icon: "lock",
                isSecure: true
            )

            GlassTextField(
                placeholder: "Email",
                text: .constant("invalid"),
                icon: "envelope",
                errorMessage: "Please enter a valid email"
            )

            GlassTextEditor(
                placeholder: "Description",
                text: .constant("")
            )

            GlassSearchBar(text: .constant("Tokyo"))
        }
        .padding()
    }
}
