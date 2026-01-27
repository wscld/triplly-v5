import SwiftUI

struct EditItinerarySheet: View {
    let itinerary: Itinerary
    @ObservedObject var viewModel: TravelDetailViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var title: String = ""
    @State private var selectedDate: Date = Date()
    @State private var isUpdating = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                // Title
                VStack(alignment: .leading, spacing: 8) {
                    Text("Name")
                        .font(.subheadline.weight(.medium))

                    TextField("Day name", text: $title)
                        .textFieldStyle(.plain)
                        .padding(14)
                        .background(Color(.systemBackground))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .overlay {
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color(.systemGray4), lineWidth: 1)
                        }
                }

                // Date
                VStack(alignment: .leading, spacing: 8) {
                    Text("Date")
                        .font(.subheadline.weight(.medium))

                    DatePicker(
                        "Date",
                        selection: $selectedDate,
                        displayedComponents: .date
                    )
                    .datePickerStyle(.graphical)
                    .tint(Color.appPrimary)
                }

                Spacer()

                // Save Button
                Button {
                    Task { await updateItinerary() }
                } label: {
                    HStack(spacing: 8) {
                        if isUpdating {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        }
                        Text("Save Changes")
                            .font(.headline)
                    }
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(title.isEmpty ? Color.gray : Color.appPrimary)
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                }
                .disabled(title.isEmpty || isUpdating)
            }
            .padding(24)
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Edit Day")
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
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
        .onAppear {
            title = itinerary.title

            if let dateStr = itinerary.date {
                let formatter = DateFormatter()
                formatter.dateFormat = "yyyy-MM-dd"
                if let date = formatter.date(from: dateStr) {
                    selectedDate = date
                }
            }
        }
    }

    private func updateItinerary() async {
        isUpdating = true

        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let dateString = formatter.string(from: selectedDate)

        await viewModel.updateItinerary(
            id: itinerary.id,
            title: title,
            date: dateString
        )

        isUpdating = false
        dismiss()
    }
}

#Preview {
    EditItinerarySheet(
        itinerary: Itinerary.preview,
        viewModel: TravelDetailViewModel(travelId: "1")
    )
}
