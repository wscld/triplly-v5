import SwiftUI
import MapKit

// MARK: - Place Search View
struct PlaceSearchView: View {
    @Binding var selectedPlace: PlaceResult?
    @Environment(\.dismiss) private var dismiss

    @State private var searchText = ""
    @State private var searchResults: [PlaceResult] = []
    @State private var isSearching = false
    @State private var searchTask: Task<Void, Never>?

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Search Bar
                HStack(spacing: 12) {
                    Image(systemName: "magnifyingglass")
                        .foregroundStyle(.secondary)

                    TextField("Search for a place...", text: $searchText)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .onSubmit {
                            performSearch()
                        }

                    if !searchText.isEmpty {
                        Button {
                            searchText = ""
                            searchResults = []
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                .padding(12)
                .background(Color(.systemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .padding()
                .onChange(of: searchText) { _, newValue in
                    // Cancel previous search
                    searchTask?.cancel()

                    if newValue.isEmpty {
                        searchResults = []
                    } else {
                        // Debounce search
                        searchTask = Task {
                            try? await Task.sleep(nanoseconds: 300_000_000) // 300ms
                            if !Task.isCancelled {
                                await search()
                            }
                        }
                    }
                }

                // Results
                if isSearching {
                    Spacer()
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: Color.appPrimary))
                    Spacer()
                } else if searchResults.isEmpty && !searchText.isEmpty {
                    Spacer()
                    VStack(spacing: 12) {
                        Image(systemName: "magnifyingglass")
                            .font(.largeTitle)
                            .foregroundStyle(.secondary)
                        Text("No results found")
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                } else if searchResults.isEmpty {
                    Spacer()
                    VStack(spacing: 12) {
                        Image(systemName: "mappin.and.ellipse")
                            .font(.largeTitle)
                            .foregroundStyle(.secondary)
                        Text("Search for a place")
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                } else {
                    List(searchResults) { result in
                        Button {
                            selectedPlace = result
                            dismiss()
                        } label: {
                            HStack(spacing: 12) {
                                Image(systemName: "mappin.circle.fill")
                                    .font(.title2)
                                    .foregroundStyle(Color.appPrimary)

                                VStack(alignment: .leading, spacing: 2) {
                                    Text(result.name)
                                        .font(.headline)
                                        .foregroundStyle(.primary)
                                        .lineLimit(1)

                                    Text(result.address)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                        .lineLimit(2)
                                }
                            }
                        }
                    }
                    .listStyle(.plain)
                }
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Search Place")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }

    private func performSearch() {
        searchTask?.cancel()
        Task {
            await search()
        }
    }

    private func search() async {
        guard !searchText.isEmpty else {
            searchResults = []
            return
        }

        await MainActor.run {
            isSearching = true
        }

        // Using Nominatim API (same as React Native version)
        let query = searchText.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        let urlString = "https://nominatim.openstreetmap.org/search?q=\(query)&format=json&limit=10"

        guard let url = URL(string: urlString) else {
            await MainActor.run {
                isSearching = false
            }
            return
        }

        var request = URLRequest(url: url)
        request.setValue("Triplly/1.0", forHTTPHeaderField: "User-Agent")

        do {
            let (data, response) = try await URLSession.shared.data(for: request)

            if let httpResponse = response as? HTTPURLResponse {
                print("DEBUG: Place search response status: \(httpResponse.statusCode)")
            }

            let results = try JSONDecoder().decode([NominatimResult].self, from: data)
            print("DEBUG: Found \(results.count) places")

            await MainActor.run {
                searchResults = results.map { result in
                    PlaceResult(
                        id: String(result.placeId),
                        name: result.displayName.components(separatedBy: ",").first ?? result.displayName,
                        address: result.displayName,
                        latitude: Double(result.lat) ?? 0,
                        longitude: Double(result.lon) ?? 0
                    )
                }
                isSearching = false
            }
        } catch {
            print("DEBUG: Place search error: \(error)")
            await MainActor.run {
                searchResults = []
                isSearching = false
            }
        }
    }
}

// MARK: - Place Result
struct PlaceResult: Identifiable, Equatable {
    let id: String
    let name: String
    let address: String
    let latitude: Double
    let longitude: Double
}

// MARK: - Nominatim Result
struct NominatimResult: Codable {
    let placeId: Int
    let displayName: String
    let lat: String
    let lon: String

    enum CodingKeys: String, CodingKey {
        case placeId = "place_id"
        case displayName = "display_name"
        case lat, lon
    }
}

#Preview {
    PlaceSearchView(selectedPlace: .constant(nil))
}
