import SwiftUI
import PhotosUI

struct EditTravelSheet: View {
    @ObservedObject var viewModel: TravelDetailViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var selectedPhoto: PhotosPickerItem?
    @State private var selectedPhotoData: Data?
    @State private var isUploadingCover = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Cover Image
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Cover Image")
                            .font(.subheadline)
                            .fontWeight(.medium)

                        ZStack {
                            if let photoData = selectedPhotoData,
                               let uiImage = UIImage(data: photoData) {
                                Image(uiImage: uiImage)
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                                    .frame(height: 160)
                                    .clipShape(RoundedRectangle(cornerRadius: 12))
                            } else {
                                TravelCoverImage(
                                    coverUrl: viewModel.travel?.coverImageUrl,
                                    height: 160,
                                    cornerRadius: 12
                                )
                            }

                            // Overlay with change button
                            VStack {
                                Spacer()
                                HStack {
                                    Spacer()
                                    PhotosPicker(selection: $selectedPhoto, matching: .images) {
                                        HStack(spacing: 6) {
                                            if isUploadingCover {
                                                ProgressView()
                                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                                    .scaleEffect(0.8)
                                            } else {
                                                Image(systemName: "camera.fill")
                                            }
                                            Text(isUploadingCover ? "Uploading..." : "Change")
                                        }
                                        .font(.subheadline.weight(.medium))
                                        .foregroundStyle(.white)
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 8)
                                        .background(.black.opacity(0.6))
                                        .clipShape(Capsule())
                                    }
                                    .disabled(isUploadingCover)
                                    .padding(12)
                                }
                            }
                        }
                        .frame(height: 160)
                    }

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
                    AppDateRangePicker(
                        title: "Travel Dates",
                        startDate: $viewModel.editStartDate,
                        endDate: $viewModel.editEndDate
                    )

                    // Visibility Toggle
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Visibility")
                            .font(.subheadline)
                            .fontWeight(.medium)

                        HStack(spacing: 12) {
                            Image(systemName: viewModel.editIsPublic ? "globe" : "lock.fill")
                                .font(.title3)
                                .foregroundStyle(viewModel.editIsPublic ? Color.appPrimary : .secondary)
                                .frame(width: 24)

                            VStack(alignment: .leading, spacing: 2) {
                                Text(viewModel.editIsPublic ? "Public" : "Private")
                                    .font(.subheadline.weight(.medium))
                                Text(viewModel.editIsPublic
                                     ? "Anyone with the link can view this trip"
                                     : "Only members can view this trip")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }

                            Spacer()

                            Toggle("", isOn: $viewModel.editIsPublic)
                                .labelsHidden()
                                .tint(Color.appPrimary)
                        }
                        .padding(12)
                        .background(Color(.secondarySystemBackground))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    }

                    // Save Button
                    AppButton(
                        title: "Save Changes",
                        isLoading: viewModel.isUpdating,
                        isDisabled: viewModel.editTitle.isEmpty || isUploadingCover
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
            .onChange(of: selectedPhoto) { _, newValue in
                Task {
                    if let data = try? await newValue?.loadTransferable(type: Data.self) {
                        selectedPhotoData = data
                        await uploadCoverImage(data)
                    }
                }
            }
        }
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
    }

    private func uploadCoverImage(_ data: Data) async {
        isUploadingCover = true

        // Compress image
        let compressedData: Data
        if let uiImage = UIImage(data: data) {
            compressedData = uiImage.jpegData(compressionQuality: 0.8) ?? data
        } else {
            compressedData = data
        }

        do {
            let updatedTravel = try await APIClient.shared.uploadCoverImage(
                travelId: viewModel.travelId,
                imageData: compressedData
            )
            viewModel.travel = updatedTravel
        } catch {
            print("Failed to upload cover image: \(error)")
        }

        isUploadingCover = false
    }
}
