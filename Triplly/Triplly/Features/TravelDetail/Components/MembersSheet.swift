import SwiftUI

struct MembersSheet: View {
    @ObservedObject var viewModel: TravelDetailViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var showingInvite = false
    @State private var inviteEmail = ""
    @State private var inviteRole: TravelRole = .editor
    @State private var isInviting = false
    @State private var inviteError: String?
    @State private var pendingInvites: [PendingInvite] = []
    @State private var isLoadingInvites = false
    @State private var selectedUsername: String?

    var body: some View {
        NavigationStack {
            List {
                // Invite Section
                Section {
                    if showingInvite {
                        inviteSection
                    } else {
                        Button {
                            withAnimation {
                                showingInvite = true
                            }
                        } label: {
                            HStack {
                                Image(systemName: "person.badge.plus")
                                Text("Invite Member")
                            }
                            .foregroundStyle(Color.appPrimary)
                        }
                    }
                }

                // Pending Invites Section
                if !pendingInvites.isEmpty {
                    Section("Pending Invites (\(pendingInvites.count))") {
                        ForEach(pendingInvites) { invite in
                            PendingInviteRow(invite: invite) {
                                Task { await cancelInvite(invite) }
                            }
                        }
                    }
                }

                // Members List
                Section("Members (\(viewModel.members.count))") {
                    ForEach(viewModel.members) { member in
                        MemberRow(member: member, onTap: {
                            if let username = member.user.username {
                                selectedUsername = username
                            }
                        }) {
                            Task { await viewModel.removeMember(member) }
                        }
                    }
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle("Team")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
            .sheet(isPresented: Binding(
                get: { selectedUsername != nil },
                set: { if !$0 { selectedUsername = nil } }
            )) {
                if let username = selectedUsername {
                    NavigationStack {
                        PublicProfileView(username: username)
                    }
                }
            }
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
        .globalErrorAlert()
        .task {
            await loadPendingInvites()
        }
    }

    private func loadPendingInvites() async {
        isLoadingInvites = true
        do {
            pendingInvites = try await APIClient.shared.getTravelInvites(travelId: viewModel.travelId)
        } catch {
            print("DEBUG: Failed to load pending invites: \(error)")
        }
        isLoadingInvites = false
    }

    private func cancelInvite(_ invite: PendingInvite) async {
        do {
            try await APIClient.shared.cancelInvite(travelId: viewModel.travelId, inviteId: invite.id)
            pendingInvites.removeAll { $0.id == invite.id }
        } catch {
            print("DEBUG: Failed to cancel invite: \(error)")
        }
    }

    private var inviteSection: some View {
        VStack(spacing: 16) {
            HStack {
                Text("Invite Member")
                    .font(.headline)

                Spacer()

                Button {
                    withAnimation {
                        showingInvite = false
                        inviteEmail = ""
                        inviteError = nil
                    }
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.secondary)
                }
            }

            TextField("Email address", text: $inviteEmail)
                .keyboardType(.emailAddress)
                .textInputAutocapitalization(.never)
                .textFieldStyle(.roundedBorder)

            // Role Picker
            Picker("Role", selection: $inviteRole) {
                Text("Editor").tag(TravelRole.editor)
                Text("Viewer").tag(TravelRole.viewer)
            }
            .pickerStyle(.segmented)

            if let error = inviteError {
                Text(error)
                    .font(.caption)
                    .foregroundStyle(.red)
            }

            Button {
                Task { await sendInvite() }
            } label: {
                HStack {
                    if isInviting {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    } else {
                        Text("Send Invite")
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(inviteEmail.isEmpty ? Color.appPrimary.opacity(0.5) : Color.appPrimary)
                .foregroundStyle(.white)
                .clipShape(RoundedRectangle(cornerRadius: 10))
            }
            .disabled(inviteEmail.isEmpty || isInviting)
        }
        .listRowInsets(EdgeInsets(top: 12, leading: 16, bottom: 12, trailing: 16))
    }

    private func sendInvite() async {
        isInviting = true
        inviteError = nil

        do {
            try await viewModel.sendInvite(email: inviteEmail, role: inviteRole)
            await loadPendingInvites()
            withAnimation {
                showingInvite = false
                inviteEmail = ""
            }
        } catch {
            inviteError = error.localizedDescription
        }

        isInviting = false
    }
}

// MARK: - Pending Invite Row
struct PendingInviteRow: View {
    let invite: PendingInvite
    let onCancel: () -> Void

    @State private var isCancelling = false

    var body: some View {
        HStack(spacing: 12) {
            NetworkAvatarView(
                name: invite.user.name,
                imageUrl: invite.user.profilePhotoUrl,
                size: 40
            )

            VStack(alignment: .leading, spacing: 2) {
                Text(invite.user.name)
                    .font(.subheadline.weight(.medium))

                Text(invite.user.email)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Text(invite.role.rawValue.capitalized)
                .font(.caption)
                .foregroundStyle(.orange)
                .padding(.horizontal, 10)
                .padding(.vertical, 4)
                .background(Color.orange.opacity(0.15))
                .clipShape(Capsule())

            Button {
                isCancelling = true
                onCancel()
            } label: {
                if isCancelling {
                    ProgressView()
                        .scaleEffect(0.7)
                } else {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.secondary)
                }
            }
            .disabled(isCancelling)
        }
    }
}

// MARK: - Member Row
struct MemberRow: View {
    let member: TravelMember
    var onTap: (() -> Void)? = nil
    let onRemove: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            Button {
                onTap?()
            } label: {
                HStack(spacing: 12) {
                    NetworkAvatarView(
                        name: member.user.name,
                        imageUrl: member.user.profilePhotoUrl,
                        size: 40
                    )

                    VStack(alignment: .leading, spacing: 2) {
                        HStack(spacing: 4) {
                            Text(member.user.name)
                                .font(.subheadline.weight(.medium))
                            if member.user.username != nil {
                                Image(systemName: "chevron.right")
                                    .font(.caption2)
                                    .foregroundStyle(.tertiary)
                            }
                        }

                        Text(member.user.email)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                .foregroundStyle(.primary)
            }
            .disabled(member.user.username == nil)

            Spacer()

            Text(member.role.rawValue.capitalized)
                .font(.caption)
                .foregroundStyle(.secondary)
                .padding(.horizontal, 10)
                .padding(.vertical, 4)
                .background(Color(.systemGray5))
                .clipShape(Capsule())

            if member.role != .owner {
                Button {
                    onRemove()
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.secondary)
                }
            }
        }
    }
}
