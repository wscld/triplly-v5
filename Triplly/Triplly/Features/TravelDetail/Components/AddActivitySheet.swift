import SwiftUI
import MapKit

struct AddActivitySheet: View {
    @ObservedObject var viewModel: TravelDetailViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var selectedPlace: PlaceResult?
    @State private var showingPlaceSearch = false
    @State private var isCreating = false
    @State private var errorMessage: String?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Location
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Where?")
                            .font(.subheadline)
                            .fontWeight(.medium)

                        Button {
                            showingPlaceSearch = true
                        } label: {
                            HStack(spacing: 12) {
                                Image(systemName: "mappin.circle.fill")
                                    .font(.system(size: 20))
                                    .foregroundStyle(selectedPlace != nil ? Color.appPrimary : .secondary)
                                    .frame(width: 24)

                                if let place = selectedPlace {
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(place.name)
                                            .font(.body.weight(.medium))
                                            .foregroundStyle(.primary)
                                            .lineLimit(1)
                                        Text(place.address)
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                            .lineLimit(1)
                                    }
                                } else {
                                    Text("Search for a place")
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
                                    .stroke(selectedPlace != nil ? Color.appPrimary.opacity(0.3) : Color(.systemGray4), lineWidth: 1)
                            }
                        }
                        .buttonStyle(.plain)
                    }

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
                        isDisabled: selectedPlace == nil
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
            .onChange(of: selectedPlace) { _, newPlace in
                if newPlace != nil {
                    Task { await createActivity() }
                }
            }
        }
        .presentationDetents([.medium, .large])
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

        // Use place name as the activity title
        let request = CreateActivityRequest(
            travelId: viewModel.travelId,
            itineraryId: itinerary.id,
            title: place.name,
            description: nil,
            latitude: place.latitude,
            longitude: place.longitude,
            externalId: place.externalId,
            provider: place.provider,
            address: place.address,
            startTime: nil
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
