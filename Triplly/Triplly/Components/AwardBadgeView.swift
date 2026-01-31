import SwiftUI

// MARK: - Badge Image Helper
func badgeImageName(for awardId: String) -> String? {
    let slug = awardId.replacingOccurrences(of: "_", with: "-")
    let name = "Badges/badge-\(slug)"
    return UIImage(named: name) != nil ? name : nil
}

// MARK: - Dominant Color Extractor
extension UIImage {
    func dominantColor() -> Color {
        guard let inputImage = CIImage(image: self) else {
            return Color(red: 0.05, green: 0.1, blue: 0.2)
        }

        let extentVector = CIVector(
            x: inputImage.extent.origin.x,
            y: inputImage.extent.origin.y,
            z: inputImage.extent.size.width,
            w: inputImage.extent.size.height
        )

        guard let filter = CIFilter(name: "CIAreaAverage", parameters: [
            kCIInputImageKey: inputImage,
            kCIInputExtentKey: extentVector
        ]),
              let outputImage = filter.outputImage else {
            return Color(red: 0.05, green: 0.1, blue: 0.2)
        }

        var bitmap = [UInt8](repeating: 0, count: 4)
        let context = CIContext(options: [.workingColorSpace: kCFNull as Any])
        context.render(
            outputImage,
            toBitmap: &bitmap,
            rowBytes: 4,
            bounds: CGRect(x: 0, y: 0, width: 1, height: 1),
            format: .RGBA8,
            colorSpace: nil
        )

        let r = Double(bitmap[0]) / 255.0
        let g = Double(bitmap[1]) / 255.0
        let b = Double(bitmap[2]) / 255.0

        return Color(red: r, green: g, blue: b)
    }
}

// MARK: - Award Badge View (tappable thumbnail)
struct AwardBadgeView: View {
    let award: Award
    let allAwards: [Award]
    @State private var showingDetail = false

    init(award: Award, allAwards: [Award] = []) {
        self.award = award
        self.allAwards = allAwards.isEmpty ? [award] : allAwards
    }

    var body: some View {
        Button {
            showingDetail = true
        } label: {
            if let imageName = badgeImageName(for: award.id) {
                Image(imageName)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 82, height: 82)
            }
        }
        .buttonStyle(.plain)
        .fullScreenCover(isPresented: $showingDetail) {
            AwardCarouselView(awards: allAwards, initialAward: award)
        }
    }
}

// MARK: - Award Carousel View (full screen with paging)
struct AwardCarouselView: View {
    let awards: [Award]
    let initialAward: Award
    @Environment(\.dismiss) private var dismiss
    @State private var currentIndex: Int = 0
    @State private var dominantColors: [String: Color] = [:]

    private var currentColor: Color {
        guard currentIndex < awards.count else {
            return Color(red: 0.05, green: 0.1, blue: 0.2)
        }
        let awardId = awards[currentIndex].id
        return dominantColors[awardId] ?? Color(red: 0.05, green: 0.1, blue: 0.2)
    }

    var body: some View {
        ZStack {
            // Dynamic gradient background
            LinearGradient(
                colors: [
                    currentColor.opacity(0.8),
                    currentColor.opacity(0.3),
                    Color(red: 0.02, green: 0.02, blue: 0.05)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            .animation(.easeInOut(duration: 0.4), value: currentIndex)

            VStack(spacing: 0) {
                // Close button
                HStack {
                    Spacer()
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundStyle(.white.opacity(0.7))
                            .frame(width: 32, height: 32)
                            .background(.white.opacity(0.15))
                            .clipShape(Circle())
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 16)

                Spacer()

                // Carousel
                TabView(selection: $currentIndex) {
                    ForEach(0..<awards.count, id: \.self) { index in
                        AwardPageView(award: awards[index])
                            .tag(index)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: awards.count > 1 ? .automatic : .never))

                Spacer()
            }
        }
        .onAppear {
            // Set initial page
            if let index = awards.firstIndex(where: { $0.id == initialAward.id }) {
                currentIndex = index
            }
            // Extract dominant colors for all awards
            for award in awards {
                if let imageName = badgeImageName(for: award.id),
                   let uiImage = UIImage(named: imageName) {
                    dominantColors[award.id] = uiImage.dominantColor()
                }
            }
        }
    }
}

// MARK: - Single Award Page
struct AwardPageView: View {
    let award: Award

    var body: some View {
        VStack(spacing: 24) {
            if let imageName = badgeImageName(for: award.id) {
                Image(imageName)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 220, height: 220)
                    .shadow(color: .white.opacity(0.15), radius: 20, y: 4)
            } else {
                Image(systemName: award.icon)
                    .font(.system(size: 72))
                    .foregroundStyle(.white)
                    .frame(width: 220, height: 220)
                    .background(.white.opacity(0.1))
                    .clipShape(Circle())
            }

            // Name
            Text(award.name)
                .font(.system(size: 26, weight: .bold, design: .rounded))
                .foregroundStyle(.white)

            // Description
            Text(award.description)
                .font(.system(.body, design: .rounded))
                .foregroundStyle(.white.opacity(0.7))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
        }
    }
}

// MARK: - Awards Inline Row (for profile)
struct AwardsInlineRow: View {
    let awards: [Award]

    var body: some View {
        HStack(spacing: 8) {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: -20) {
                    ForEach(awards) { award in
                        AwardBadgeView(award: award, allAwards: awards)
                    }
                }
            }
        }
    }
}

// MARK: - Awards Section (standalone, e.g. public profile)
struct AwardsSection: View {
    let awards: [Award]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Awards")
                .font(.headline)
                .padding(.horizontal)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: -20) {
                    ForEach(awards) { award in
                        AwardBadgeView(award: award, allAwards: awards)
                    }
                }
                .padding(.horizontal)
            }
        }
    }
}

#Preview {
    AwardsSection(awards: [
        Award(id: "first_steps", name: "First Steps", icon: "figure.walk", description: "Every journey begins with a single step"),
        Award(id: "wanderer", name: "Wanderer", icon: "map", description: "The world is calling, and you're answering"),
        Award(id: "solo_adventurer", name: "Solo Adventurer", icon: "person.fill", description: "Brave enough to explore alone"),
        Award(id: "squad_goals", name: "Squad Goals", icon: "person.3.fill", description: "Everything's better with friends"),
    ])
    .padding(.vertical)
}
