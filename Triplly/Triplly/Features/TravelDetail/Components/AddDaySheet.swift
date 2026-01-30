import SwiftUI

struct AddDaySheet: View {
    @ObservedObject var viewModel: TravelDetailViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var selectedDate: Date = Date()

    private var dateFormatter: DateFormatter {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        return f
    }

    private var travelStartDate: Date? {
        viewModel.travel?.startDate.flatMap { dateFormatter.date(from: $0) }
    }

    private var travelEndDate: Date? {
        viewModel.travel?.endDate.flatMap { dateFormatter.date(from: $0) }
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Calendar
                DatePicker(
                    "Select Date",
                    selection: $selectedDate,
                    in: (travelStartDate ?? .distantPast)...(travelEndDate ?? .distantFuture),
                    displayedComponents: .date
                )
                .datePickerStyle(.graphical)
                .tint(Color.appPrimary)
                .padding(.horizontal)

                Spacer()

                // Add Button
                Button {
                    Task {
                        await createDay()
                    }
                } label: {
                    HStack(spacing: 8) {
                        if viewModel.isCreatingDay {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        } else {
                            Image(systemName: "plus")
                                .font(.system(size: 16, weight: .semibold))
                        }
                        Text("Add Day")
                            .font(.headline)
                    }
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(Color.appPrimary)
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                }
                .disabled(viewModel.isCreatingDay)
                .padding(.horizontal, 24)
                .padding(.bottom, 24)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Add Day")
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
            // Default to the day after the last itinerary date, or travel start date
            if let lastItinerary = viewModel.itineraries.last,
               let dateStr = lastItinerary.date {
                let formatter = DateFormatter()
                formatter.dateFormat = "yyyy-MM-dd"
                if let lastDate = formatter.date(from: dateStr) {
                    selectedDate = Calendar.current.date(byAdding: .day, value: 1, to: lastDate) ?? Date()
                }
            } else if let startDateStr = viewModel.travel?.startDate {
                let formatter = DateFormatter()
                formatter.dateFormat = "yyyy-MM-dd"
                if let startDate = formatter.date(from: startDateStr) {
                    selectedDate = startDate
                }
            }
        }
    }

    private func createDay() async {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let dateString = formatter.string(from: selectedDate)

        // Auto-generate title based on day number
        let dayNumber = viewModel.itineraries.count + 1
        let title = "Day \(dayNumber)"

        viewModel.newDayTitle = title
        viewModel.newDayDate = selectedDate

        await viewModel.createDay()
        dismiss()
    }
}

#Preview {
    AddDaySheet(viewModel: TravelDetailViewModel(travelId: "1"))
}
