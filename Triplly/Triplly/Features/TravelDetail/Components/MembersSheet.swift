import SwiftUI

struct MembersSheet: View {
    @ObservedObject var viewModel: TravelDetailViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var showingInvite = false
    @State private var inviteEmail = ""
    @State private var inviteRole: TravelRole = .editor
    @State private var isInviting = false
    @State private var inviteError: String?

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

                // Members List
                Section("Members (\(viewModel.members.count))") {
                    ForEach(viewModel.members) { member in
                        MemberRow(member: member) {
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
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
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
            try await viewModel.inviteMember(email: inviteEmail, role: inviteRole)
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

// MARK: - Member Row
struct MemberRow: View {
    let member: TravelMember
    let onRemove: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            NetworkAvatarView(
                name: member.user.name,
                imageUrl: member.user.profilePhotoUrl,
                size: 40
            )

            VStack(alignment: .leading, spacing: 2) {
                Text(member.user.name)
                    .font(.subheadline.weight(.medium))

                Text(member.user.email)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

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
