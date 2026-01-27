import SwiftUI

struct EditTravelSheet: View {
    @ObservedObject var viewModel: TravelDetailViewModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Title
                    AppTextField(
                        title: "Trip Name",
                        placeholder: "Trip name",
                        text: $viewModel.editTitle,
                        icon: "airplane"
                    )

                    // Description
                    AppTextEditor(
                        title: "Description",
                        placeholder: "Add a description...",
                        text: $viewModel.editDescription,
                        minHeight: 80
                    )

                    // Dates
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Travel Dates")
                            .font(.subheadline)
                            .fontWeight(.medium)

                        HStack(spacing: 12) {
                            AppDatePicker(
                                title: "Start Date",
                                date: $viewModel.editStartDate
                            )

                            AppDatePicker(
                                title: "End Date",
                                date: $viewModel.editEndDate,
                                minimumDate: viewModel.editStartDate
                            )
                        }
                    }

                    // Save Button
                    AppButton(
                        title: "Save Changes",
                        isLoading: viewModel.isUpdating,
                        isDisabled: viewModel.editTitle.isEmpty
                    ) {
                        Task { await viewModel.updateTravel() }
                    }
                    .padding(.top, 8)
                }
                .padding(24)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Edit Trip")
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
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
    }
}
