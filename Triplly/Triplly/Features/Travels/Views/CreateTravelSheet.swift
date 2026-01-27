import SwiftUI

struct CreateTravelSheet: View {
    @ObservedObject var viewModel: TravelsViewModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Destination
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Where to?")
                            .font(.subheadline)
                            .fontWeight(.medium)

                        Button {
                            viewModel.showingLocationSearch = true
                        } label: {
                            HStack(spacing: 12) {
                                Image(systemName: "mappin.circle.fill")
                                    .font(.system(size: 20))
                                    .foregroundStyle(viewModel.selectedLocation != nil ? Color.appPrimary : .secondary)
                                    .frame(width: 24)

                                if let location = viewModel.selectedLocation {
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(location.name)
                                            .font(.body.weight(.medium))
                                            .foregroundStyle(.primary)
                                            .lineLimit(1)
                                        Text(location.address)
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                            .lineLimit(1)
                                    }
                                } else {
                                    Text("Search for a destination")
                                        .font(.body)
                                        .foregroundStyle(Color(.placeholderText))
                                }

                                Spacer()

                                if viewModel.selectedLocation != nil {
                                    Button {
                                        viewModel.selectedLocation = nil
                                    } label: {
                                        Image(systemName: "xmark.circle.fill")
                                            .foregroundStyle(.secondary)
                                    }
                                } else {
                                    Image(systemName: "chevron.right")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 14)
                            .background(Color(.systemBackground))
                            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                            .overlay {
                                RoundedRectangle(cornerRadius: 12, style: .continuous)
                                    .stroke(viewModel.selectedLocation != nil ? Color.appPrimary.opacity(0.3) : Color(.systemGray4), lineWidth: 1)
                            }
                        }
                        .buttonStyle(.plain)
                    }

                    // Dates
                    AppDateRangePicker(
                        title: "When?",
                        startDate: $viewModel.newTravelStartDate,
                        endDate: $viewModel.newTravelEndDate
                    )

                    // Error
                    if let error = viewModel.createError {
                        HStack(spacing: 8) {
                            Image(systemName: "exclamationmark.triangle.fill")
                            Text(error)
                        }
                        .font(.subheadline)
                        .foregroundStyle(.red)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.red.opacity(0.1))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    }

                    // Create Button
                    AppButton(
                        title: "Create Trip",
                        icon: "plus",
                        isLoading: viewModel.isCreating,
                        isDisabled: viewModel.selectedLocation == nil
                    ) {
                        Task {
                            await viewModel.createTravel()
                            if viewModel.createError == nil {
                                dismiss()
                            }
                        }
                    }
                    .padding(.top, 8)
                }
                .padding(24)
            }
            .scrollBounceBehavior(.basedOnSize)
            .background(Color(.systemGroupedBackground))
            .navigationTitle("New Trip")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        viewModel.resetCreateForm()
                        dismiss()
                    }
                    .foregroundStyle(.secondary)
                }
            }
            .sheet(isPresented: $viewModel.showingLocationSearch) {
                PlaceSearchView(selectedPlace: $viewModel.selectedLocation)
            }
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
    }
}

#Preview {
    CreateTravelSheet(viewModel: TravelsViewModel())
}
