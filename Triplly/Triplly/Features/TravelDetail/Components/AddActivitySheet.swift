import SwiftUI
import MapKit

struct AddActivitySheet: View {
    @ObservedObject var viewModel: TravelDetailViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var title = ""
    @State private var description = ""
    @State private var startTime: Date?
    @State private var showTimePicker = false
    @State private var selectedPlace: PlaceResult?
    @State private var showingPlaceSearch = false
    @State private var isCreating = false
    @State private var errorMessage: String?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Title
                    AppTextField(
                        title: "Activity Name",
                        placeholder: "e.g., Visit Tokyo Tower",
                        text: $title,
                        icon: "mappin"
                    )

                    // Location
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Location")
                            .font(.subheadline)
                            .fontWeight(.medium)

                        Button {
                            showingPlaceSearch = true
                        } label: {
                            HStack(spacing: 12) {
                                Image(systemName: "location.circle")
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundStyle(.secondary)
                                    .frame(width: 20)

                                if let place = selectedPlace {
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(place.name)
                                            .font(.body)
                                            .foregroundStyle(.primary)
                                            .lineLimit(1)
                                        Text(place.address)
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                            .lineLimit(1)
                                    }
                                } else {
                                    Text("Search for a location")
                                        .font(.body)
                                        .foregroundStyle(Color(.placeholderText))
                                }

                                Spacer()

                                if selectedPlace != nil {
                                    Button {
                                        selectedPlace = nil
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
                                    .stroke(Color(.systemGray4), lineWidth: 1)
                            }
                        }
                        .buttonStyle(.plain)
                    }

                    // Time (optional)
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Start Time (optional)")
                            .font(.subheadline)
                            .fontWeight(.medium)

                        Button {
                            if startTime == nil {
                                startTime = Date()
                            }
                            showTimePicker.toggle()
                        } label: {
                            HStack {
                                Image(systemName: "clock")
                                    .foregroundStyle(.secondary)

                                if let time = startTime {
                                    Text(time, style: .time)
                                        .foregroundStyle(.primary)
                                } else {
                                    Text("Add start time")
                                        .foregroundStyle(Color(.placeholderText))
                                }

                                Spacer()

                                if startTime != nil {
                                    Button {
                                        startTime = nil
                                        showTimePicker = false
                                    } label: {
                                        Image(systemName: "xmark.circle.fill")
                                            .foregroundStyle(.secondary)
                                    }
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

                        if showTimePicker, startTime != nil {
                            DatePicker(
                                "",
                                selection: Binding(
                                    get: { startTime ?? Date() },
                                    set: { startTime = $0 }
                                ),
                                displayedComponents: .hourAndMinute
                            )
                            .datePickerStyle(.wheel)
                            .labelsHidden()
                        }
                    }

                    // Description (optional)
                    AppTextEditor(
                        title: "Notes (optional)",
                        placeholder: "Add any notes about this activity...",
                        text: $description,
                        minHeight: 80
                    )

                    // Error
                    if let error = errorMessage {
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
                        title: "Add Activity",
                        icon: "plus",
                        isLoading: isCreating,
                        isDisabled: title.isEmpty || selectedPlace == nil
                    ) {
                        Task {
                            await createActivity()
                        }
                    }
                    .padding(.top, 8)
                }
                .padding(24)
            }
            .scrollBounceBehavior(.basedOnSize)
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Add Activity")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundStyle(.secondary)
                }
            }
            .sheet(isPresented: $showingPlaceSearch) {
                PlaceSearchView(selectedPlace: $selectedPlace)
            }
        }
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
    }

    private func createActivity() async {
        guard let place = selectedPlace else {
            errorMessage = "Please select a location"
            return
        }

        guard let itinerary = viewModel.selectedItinerary else {
            errorMessage = "No day selected"
            return
        }

        isCreating = true
        errorMessage = nil

        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"

        let request = CreateActivityRequest(
            travelId: viewModel.travelId,
            itineraryId: itinerary.id,
            title: title,
            description: description.isEmpty ? nil : description,
            latitude: place.latitude,
            longitude: place.longitude,
            googlePlaceId: nil,
            address: place.address,
            startTime: startTime.map { formatter.string(from: $0) }
        )

        do {
            let newActivity = try await APIClient.shared.createActivity(request)

            // Update local state
            if var updatedTravel = viewModel.travel {
                if let index = updatedTravel.itineraries?.firstIndex(where: { $0.id == itinerary.id }) {
                    var updatedItinerary = updatedTravel.itineraries![index]
                    var activities = updatedItinerary.activities ?? []
                    activities.append(newActivity)
                    updatedItinerary.activities = activities
                    updatedTravel.itineraries![index] = updatedItinerary
                    viewModel.travel = updatedTravel
                }
            }

            dismiss()
        } catch {
            errorMessage = error.localizedDescription
        }

        isCreating = false
    }
}

#Preview {
    AddActivitySheet(viewModel: TravelDetailViewModel(travelId: "1"))
}
