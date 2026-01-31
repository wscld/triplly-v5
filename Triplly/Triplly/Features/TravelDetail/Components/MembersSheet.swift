import SwiftUI

struct MembersSheet: View {
    @ObservedObject var viewModel: TravelDetailViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var showingInvite = false
    @State private var pendingInvites: [PendingInvite] = []
    @State private var isLoadingInvites = false
    @State private var selectedUsername: String?
    @State private var memberToRemove: TravelMember?
    @State private var inviteToCancel: PendingInvite?

    var body: some View {
        NavigationStack {
            List {
                // Invite Section
                Section {
                    Button {
                        showingInvite = true
                    } label: {
                        HStack {
                            Image(systemName: "person.badge.plus")
                            Text("Invite Member")
                        }
                        .foregroundStyle(Color.appPrimary)
                    }
                }

                // Pending Invites Section
                if !pendingInvites.isEmpty {
                    Section("Pending Invites (\(pendingInvites.count))") {
                        ForEach(pendingInvites) { invite in
                            PendingInviteRow(invite: invite) {
                                inviteToCancel = invite
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
                            memberToRemove = member
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
            .sheet(isPresented: $showingInvite) {
                InviteFormSheet(viewModel: viewModel) {
                    await loadPendingInvites()
                }
            }
            .alert("Remove Member", isPresented: Binding(
                get: { memberToRemove != nil },
                set: { if !$0 { memberToRemove = nil } }
            )) {
                Button("Cancel", role: .cancel) {
                    memberToRemove = nil
                }
                Button("Remove", role: .destructive) {
                    if let member = memberToRemove {
                        Task { await viewModel.removeMember(member) }
                        memberToRemove = nil
                    }
                }
            } message: {
                if let member = memberToRemove {
                    Text("Are you sure you want to remove \(member.user.name) from this trip?")
                }
            }
            .alert("Cancel Invite", isPresented: Binding(
                get: { inviteToCancel != nil },
                set: { if !$0 { inviteToCancel = nil } }
            )) {
                Button("Keep", role: .cancel) {
                    inviteToCancel = nil
                }
                Button("Cancel Invite", role: .destructive) {
                    if let invite = inviteToCancel {
                        Task { await cancelInvite(invite) }
                        inviteToCancel = nil
                    }
                }
            } message: {
                if let invite = inviteToCancel {
                    Text("Are you sure you want to cancel the invite to \(invite.user.name)?")
                }
            }
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
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
}

// MARK: - Invite Form Sheet
struct InviteFormSheet: View {
    @ObservedObject var viewModel: TravelDetailViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var email = ""
    @State private var role: TravelRole = .editor
    @State private var isInviting = false
    @State private var inviteError: String?
    @State private var showConfirmation = false

    var onInviteSent: () async -> Void

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Email address", text: $email)
                        .keyboardType(.emailAddress)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()

                    Picker("Role", selection: $role) {
                        Text("Editor").tag(TravelRole.editor)
                        Text("Viewer").tag(TravelRole.viewer)
                    }
                }

                Section {
                    AppButton(
                        title: "Send Invite",
                        icon: "paperplane.fill",
                        isLoading: isInviting,
                        isDisabled: email.trimmingCharacters(in: .whitespaces).isEmpty
                    ) {
                        showConfirmation = true
                    }
                    .listRowInsets(EdgeInsets())
                    .listRowBackground(Color.clear)
                }
            }
            .navigationTitle("Invite Member")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .alert("Send Invite", isPresented: $showConfirmation) {
                Button("Cancel", role: .cancel) { }
                Button("Send") {
                    let emailToSend = email.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
                    let roleToSend = role
                    Task { await sendInvite(email: emailToSend, role: roleToSend) }
                }
            } message: {
                Text("Send an invite to \(email.trimmingCharacters(in: .whitespacesAndNewlines)) as \(role.rawValue)?")
            }
            .alert("Error", isPresented: Binding(
                get: { inviteError != nil },
                set: { if !$0 { inviteError = nil } }
            )) {
                Button("OK") { inviteError = nil }
            } message: {
                if let error = inviteError {
                    Text(error)
                }
            }
        }
        .presentationDetents([.medium])
    }

    private func sendInvite(email: String, role: TravelRole) async {
        isInviting = true
        inviteError = nil

        do {
            try await viewModel.sendInvite(email: email, role: role)
            await onInviteSent()
            dismiss()
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
                onCancel()
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .foregroundStyle(.secondary)
            }
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
