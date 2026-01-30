import SwiftUI
import MapKit

struct PlaceDetailView: View {
    let placeId: String
    @Environment(\.dismiss) private var dismiss

    @State private var place: Place?
    @State private var checkIns: [CheckIn] = []
    @State private var reviews: [PlaceReview] = []
    @State private var isLoading = true
    @State private var showingWriteReview = false
    @State private var hasCheckedIn = false

    var body: some View {
        NavigationStack {
            Group {
                if isLoading {
                    ProgressView()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if let place = place {
                    placeContent(place)
                } else {
                    Text("Place not found")
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle(place?.name ?? "Place")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                        .fontWeight(.semibold)
                }
            }
            .sheet(isPresented: $showingWriteReview) {
                WriteReviewSheet(placeId: placeId) { newReview in
                    reviews.insert(newReview, at: 0)
                    // Refresh place to update average rating
                    Task { await loadPlace() }
                }
            }
        }
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
        .task {
            await loadAll()
        }
    }

    @ViewBuilder
    private func placeContent(_ place: Place) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Map preview
                Map(coordinateRegion: .constant(MKCoordinateRegion(
                    center: CLLocationCoordinate2D(latitude: place.latitudeDouble, longitude: place.longitudeDouble),
                    span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
                )), annotationItems: [place]) { (p: Place) in
                    MapAnnotation(coordinate: CLLocationCoordinate2D(latitude: p.latitudeDouble, longitude: p.longitudeDouble)) {
                        ZStack {
                            Circle()
                                .fill(Color.appPrimary)
                                .frame(width: 28, height: 28)
                            Image(systemName: "mappin")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundStyle(.white)
                        }
                    }
                }
                .frame(height: 180)
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .padding(.horizontal)

                // Place info
                VStack(alignment: .leading, spacing: 8) {
                    Text(place.name)
                        .font(.title2.weight(.bold))

                    if let address = place.address {
                        HStack(spacing: 6) {
                            Image(systemName: "mappin.circle.fill")
                                .foregroundStyle(Color.appPrimary)
                            Text(address)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                .padding(.horizontal)

                // Stats
                HStack(spacing: 0) {
                    VStack(spacing: 4) {
                        HStack(spacing: 4) {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(.green)
                            Text("\(place.checkInCount ?? checkIns.count)")
                                .font(.system(size: 16, weight: .bold, design: .rounded))
                        }
                        Text("Check-ins")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity)

                    Divider().frame(height: 40)

                    VStack(spacing: 4) {
                        HStack(spacing: 4) {
                            Image(systemName: "star.fill")
                                .foregroundStyle(.orange)
                            if let avg = place.averageRating?.value {
                                Text(String(format: "%.1f", avg))
                                    .font(.system(size: 16, weight: .bold, design: .rounded))
                            } else {
                                Text("—")
                                    .font(.system(size: 16, weight: .bold, design: .rounded))
                                    .foregroundStyle(.secondary)
                            }
                        }
                        Text("Rating")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                }
                .padding(.vertical, 16)
                .background(Color(.systemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .padding(.horizontal)

                // Check-ins section
                if !checkIns.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Check-ins")
                            .font(.headline)
                            .padding(.horizontal)

                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 12) {
                                ForEach(checkIns) { checkIn in
                                    if let user = checkIn.user {
                                        VStack(spacing: 6) {
                                            MiniAvatar(
                                                name: user.name,
                                                imageUrl: user.profilePhotoUrl,
                                                size: 40
                                            )
                                            Text(user.name.components(separatedBy: " ").first ?? user.name)
                                                .font(.caption2)
                                                .foregroundStyle(.secondary)
                                                .lineLimit(1)
                                        }
                                        .frame(width: 56)
                                    }
                                }
                            }
                            .padding(.horizontal)
                        }
                    }
                }

                // Reviews section
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text("Reviews")
                            .font(.headline)
                        Spacer()
                        if hasCheckedIn {
                            Button {
                                showingWriteReview = true
                            } label: {
                                HStack(spacing: 4) {
                                    Image(systemName: "square.and.pencil")
                                    Text("Write Review")
                                }
                                .font(.subheadline.weight(.medium))
                                .foregroundStyle(Color.appPrimary)
                            }
                        }
                    }
                    .padding(.horizontal)

                    if reviews.isEmpty {
                        VStack(spacing: 8) {
                            Image(systemName: "text.bubble")
                                .font(.title)
                                .foregroundStyle(.tertiary)
                            Text("No reviews yet")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                            if hasCheckedIn {
                                Text("Be the first to review!")
                                    .font(.caption)
                                    .foregroundStyle(.tertiary)
                            } else {
                                Text("Check in first to write a review")
                                    .font(.caption)
                                    .foregroundStyle(.tertiary)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 24)
                    } else {
                        LazyVStack(spacing: 12) {
                            ForEach(reviews) { review in
                                ReviewRow(review: review)
                            }
                        }
                        .padding(.horizontal)
                    }
                }

                Spacer(minLength: 20)
            }
            .padding(.vertical)
        }
    }

    private func loadAll() async {
        isLoading = true
        async let placeTask: () = loadPlace()
        async let checkInsTask: () = loadCheckIns()
        async let reviewsTask: () = loadReviews()
        async let checkedInTask: () = checkUserCheckedIn()
        _ = await (placeTask, checkInsTask, reviewsTask, checkedInTask)
        isLoading = false
    }

    private func loadPlace() async {
        do {
            place = try await APIClient.shared.getPlace(id: placeId)
        } catch {
            print("DEBUG: Failed to load place: \(error)")
        }
    }

    private func loadCheckIns() async {
        do {
            checkIns = try await APIClient.shared.getPlaceCheckIns(placeId: placeId)
        } catch {
            print("DEBUG: Failed to load check-ins: \(error)")
        }
    }

    private func loadReviews() async {
        do {
            reviews = try await APIClient.shared.getPlaceReviews(placeId: placeId)
        } catch {
            print("DEBUG: Failed to load reviews: \(error)")
        }
    }

    private func checkUserCheckedIn() async {
        do {
            let myCheckIns = try await APIClient.shared.getMyCheckIns()
            hasCheckedIn = myCheckIns.contains { $0.placeId == placeId }
        } catch {
            print("DEBUG: Failed to check user check-in status: \(error)")
        }
    }
}

// MARK: - Review Row
struct ReviewRow: View {
    let review: PlaceReview

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                if let user = review.user {
                    MiniAvatar(
                        name: user.name,
                        imageUrl: user.profilePhotoUrl,
                        size: 28
                    )
                    Text(user.name)
                        .font(.subheadline.weight(.semibold))
                }

                Spacer()

                HStack(spacing: 2) {
                    ForEach(1...5, id: \.self) { star in
                        Image(systemName: star <= review.rating ? "star.fill" : "star")
                            .font(.system(size: 10))
                            .foregroundStyle(star <= review.rating ? .orange : .gray.opacity(0.3))
                    }
                }
            }

            Text(review.content)
                .font(.subheadline)
                .foregroundStyle(.primary)
        }
        .padding(12)
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

// MARK: - Write Review Sheet
struct WriteReviewSheet: View {
    let placeId: String
    let onReviewCreated: (PlaceReview) -> Void
    @Environment(\.dismiss) private var dismiss

    @State private var rating: Int = 5
    @State private var content: String = ""
    @State private var isSubmitting = false
    @State private var errorMessage: String?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Star picker
                    VStack(spacing: 8) {
                        Text("Your Rating")
                            .font(.subheadline.weight(.medium))

                        HStack(spacing: 8) {
                            ForEach(1...5, id: \.self) { star in
                                Button {
                                    rating = star
                                } label: {
                                    Image(systemName: star <= rating ? "star.fill" : "star")
                                        .font(.system(size: 32))
                                        .foregroundStyle(star <= rating ? .orange : .gray.opacity(0.3))
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }

                    // Content
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Your Review")
                            .font(.subheadline.weight(.medium))

                        TextEditor(text: $content)
                            .frame(minHeight: 120)
                            .padding(8)
                            .background(Color(.systemBackground))
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                            .overlay {
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color(.systemGray4), lineWidth: 1)
                            }
                    }

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

                    // Submit
                    Button {
                        Task { await submitReview() }
                    } label: {
                        HStack {
                            if isSubmitting {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            } else {
                                Text("Submit Review")
                            }
                        }
                        .font(.headline)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? Color.gray : Color.appPrimary)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                    }
                    .disabled(content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isSubmitting)
                }
                .padding(24)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Write Review")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                        .foregroundStyle(.secondary)
                }
            }
        }
        .presentationDetents([.medium])
        .presentationDragIndicator(.visible)
    }

    private func submitReview() async {
        let trimmedContent = content.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedContent.isEmpty else { return }

        isSubmitting = true
        errorMessage = nil

        do {
            let review = try await APIClient.shared.createReview(
                placeId: placeId,
                rating: rating,
                content: trimmedContent
            )
            onReviewCreated(review)
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
        }

        isSubmitting = false
    }
}
