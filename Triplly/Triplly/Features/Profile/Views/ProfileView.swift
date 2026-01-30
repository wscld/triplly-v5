import SwiftUI
import PhotosUI
import Himetrica

struct ProfileView: View {
    @EnvironmentObject var appState: AppState
    @State private var showingEditSheet = false

    var body: some View {
        List {
            // Profile Header
            Section {
                profileHeader
            }
            .listRowInsets(EdgeInsets())
            .listRowBackground(Color.clear)

            // Settings
            Section("Settings") {
                if let username = appState.currentUser?.username,
                   let url = URL(string: "https://triplly.com/u/\(username)") {
                    ShareLink(item: url) {
                        SettingsRow(
                            icon: "square.and.arrow.up",
                            iconColor: Color.appPrimary,
                            title: "Share Profile"
                        )
                    }
                    .tint(.primary)
                }

                SettingsRow(
                    icon: "bell",
                    iconColor: Color.appPrimary,
                    title: "Notifications"
                )

                SettingsRow(
                    icon: "globe",
                    iconColor: .blue,
                    title: "Language"
                )

                SettingsRow(
                    icon: "lock.shield",
                    iconColor: .green,
                    title: "Privacy"
                )

                SettingsRow(
                    icon: "questionmark.circle",
                    iconColor: .orange,
                    title: "Help & Support"
                )
            }

            // Sign Out
            Section {
                Button {
                    appState.logout()
                } label: {
                    HStack {
                        Spacer()
                        Text("Sign Out")
                            .foregroundStyle(.red)
                        Spacer()
                    }
                }
            }

            // App Info
            Section {
                appInfo
            }
            .listRowBackground(Color.clear)
        }
        .listStyle(.insetGrouped)
        .navigationTitle("Profile")
        .navigationBarTitleDisplayMode(.large)
        .trackScreen("Profile")
    }

    private var profileHeader: some View {
        VStack(alignment: .leading, spacing: 20) {
            // Avatar + Name row
            HStack(spacing: 16) {
                NetworkAvatarView(
                    name: appState.currentUser?.name ?? "User",
                    imageUrl: appState.currentUser?.profilePhotoUrl,
                    size: 124
                )

                VStack(alignment: .leading, spacing: 4) {
                    Text(appState.currentUser?.name ?? "User")
                        .font(.system(size: 22, weight: .bold, design: .rounded))

                    if let username = appState.currentUser?.username {
                        Text(username)
                            .font(.system(.subheadline, design: .rounded))
                            .foregroundStyle(.secondary)
                    }
                }

                Spacer()
            }


            // Awards inline row
            if let awards = appState.currentUser?.awards, !awards.isEmpty {
                AwardsInlineRow(awards: awards)
            }

            // Edit Profile Button
            Button {
                showingEditSheet = true
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "pencil")
                    Text("Edit Profile")
                }
                .font(.subheadline.weight(.medium))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .background(Color(.systemGray5))
                .clipShape(Capsule())
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 20)
        .sheet(isPresented: $showingEditSheet) {
            EditProfileSheet(appState: appState)
        }
    }

    private var appInfo: some View {
        VStack(spacing: 8) {
            Text("Triplly")
                .font(.headline)

            Text("Version 1.0.0")
                .font(.caption)
                .foregroundStyle(.secondary)

            Text("Made with SwiftUI")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
    }
}

// MARK: - Settings Row
struct SettingsRow: View {
    let icon: String
    var iconColor: Color = .primary
    let title: String
    var value: String? = nil

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundStyle(.white)
                .frame(width: 28, height: 28)
                .background(iconColor)
                .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))

            Text(title)

            Spacer()

            if let value = value {
                Text(value)
                    .foregroundStyle(.secondary)
            }

            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }
}

// MARK: - Edit Profile Sheet
struct EditProfileSheet: View {
    @ObservedObject var appState: AppState
    @Environment(\.dismiss) private var dismiss

    @State private var name: String = ""
    @State private var username: String = ""
    @State private var selectedPhoto: PhotosPickerItem?
    @State private var selectedPhotoData: Data?
    @State private var isLoading = false
    @State private var errorMessage: String?

    // Username availability
    @State private var usernameAvailable: Bool?
    @State private var isCheckingUsername = false
    @State private var usernameCheckTask: Task<Void, Never>?

    var body: some View {
        NavigationStack {
            Form {
                // Photo Section
                Section {
                    HStack {
                        Spacer()
                        VStack(spacing: 12) {
                            if let photoData = selectedPhotoData,
                               let uiImage = UIImage(data: photoData) {
                                Image(uiImage: uiImage)
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 100, height: 100)
                                    .clipShape(Circle())
                            } else {
                                NetworkAvatarView(
                                    name: appState.currentUser?.name ?? "User",
                                    imageUrl: appState.currentUser?.profilePhotoUrl,
                                    size: 124
                                )
                            }

                            PhotosPicker(selection: $selectedPhoto, matching: .images) {
                                Text("Change Photo")
                                    .font(.subheadline.weight(.medium))
                                    .foregroundStyle(Color.appPrimary)
                            }
                        }
                        Spacer()
                    }
                    .padding(.vertical, 16)
                }
                .listRowBackground(Color.clear)

                // Name Section
                Section("Name") {
                    TextField("Your name", text: $name)
                        .textContentType(.name)
                        .autocorrectionDisabled()
                }

                // Username Section
                Section {
                    HStack {
                        Text("@")
                            .foregroundStyle(.secondary)
                        TextField("username", text: $username)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()
                            .onChange(of: username) { _, newValue in
                                // Sanitize: lowercase, only alphanumeric + underscores
                                let sanitized = String(newValue.lowercased().filter { $0.isLetter || $0.isNumber || $0 == "_" })
                                if sanitized != newValue {
                                    username = sanitized
                                }
                                checkUsernameAvailability()
                            }

                        if isCheckingUsername {
                            ProgressView()
                                .scaleEffect(0.8)
                        } else if username.count >= 3 {
                            if let available = usernameAvailable {
                                Image(systemName: available ? "checkmark.circle.fill" : "xmark.circle.fill")
                                    .foregroundStyle(available ? .green : .red)
                            }
                        }
                    }
                } header: {
                    Text("Username")
                } footer: {
                    if !username.isEmpty && username.count < 3 {
                        Text("Username must be at least 3 characters")
                            .foregroundStyle(.orange)
                    } else if let available = usernameAvailable, !available, username.count >= 3 {
                        Text("This username is already taken")
                            .foregroundStyle(.red)
                    }
                }

                // Error Message
                if let error = errorMessage {
                    Section {
                        Text(error)
                            .foregroundStyle(.red)
                            .font(.subheadline)
                    }
                }
            }
            .navigationTitle("Edit Profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        Task { await saveProfile() }
                    }
                    .fontWeight(.semibold)
                    .disabled(isLoading || name.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
            .disabled(isLoading)
            .overlay {
                if isLoading {
                    ProgressView()
                        .scaleEffect(1.5)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(Color.black.opacity(0.1))
                }
            }
            .onChange(of: selectedPhoto) { _, newValue in
                Task {
                    if let data = try? await newValue?.loadTransferable(type: Data.self) {
                        selectedPhotoData = data
                    }
                }
            }
            .onAppear {
                name = appState.currentUser?.name ?? ""
                username = appState.currentUser?.username ?? ""
            }
        }
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
    }

    private func checkUsernameAvailability() {
        usernameCheckTask?.cancel()
        usernameAvailable = nil

        guard username.count >= 3 else { return }

        // If unchanged from current, it's available
        if username == appState.currentUser?.username {
            usernameAvailable = true
            return
        }

        usernameCheckTask = Task {
            // Debounce 500ms
            try? await Task.sleep(nanoseconds: 500_000_000)
            guard !Task.isCancelled else { return }

            isCheckingUsername = true
            do {
                let result = try await APIClient.shared.checkUsernameAvailability(username)
                if !Task.isCancelled {
                    usernameAvailable = result.available
                }
            } catch {
                // Silent fail
            }
            isCheckingUsername = false
        }
    }

    private func saveProfile() async {
        isLoading = true
        errorMessage = nil

        do {
            // Upload photo first if selected
            if let photoData = selectedPhotoData {
                // Compress image if needed
                let compressedData: Data
                if let uiImage = UIImage(data: photoData) {
                    compressedData = uiImage.jpegData(compressionQuality: 0.8) ?? photoData
                } else {
                    compressedData = photoData
                }

                let updatedUser = try await APIClient.shared.uploadProfilePhoto(imageData: compressedData)
                appState.currentUser = updatedUser
            }

            // Update name and/or username if changed
            let trimmedName = name.trimmingCharacters(in: .whitespaces)
            let trimmedUsername = username.trimmingCharacters(in: .whitespaces)

            let nameChanged = trimmedName != appState.currentUser?.name && !trimmedName.isEmpty
            let usernameChanged = trimmedUsername != (appState.currentUser?.username ?? "") && trimmedUsername.count >= 3

            if nameChanged || usernameChanged {
                let updatedUser = try await APIClient.shared.updateProfile(
                    name: nameChanged ? trimmedName : nil,
                    username: usernameChanged ? trimmedUsername : nil
                )
                appState.currentUser = updatedUser
            }

            dismiss()
        } catch {
            errorMessage = "Failed to update profile. Please try again."
        }

        isLoading = false
    }
}

#Preview {
    NavigationStack {
        ProfileView()
    }
    .environmentObject(AppState())
}
