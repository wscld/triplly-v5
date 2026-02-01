import SwiftUI

// MARK: - Award Color Mapping
private struct AwardColors {
    let foreground: Color
    let background: Color

    static func from(_ name: String) -> AwardColors {
        switch name {
        case "emerald": return AwardColors(foreground: Color(red: 5/255, green: 150/255, blue: 105/255), background: Color(red: 209/255, green: 250/255, blue: 229/255))
        case "teal": return AwardColors(foreground: Color(red: 13/255, green: 148/255, blue: 136/255), background: Color(red: 204/255, green: 251/255, blue: 241/255))
        case "cyan": return AwardColors(foreground: Color(red: 8/255, green: 145/255, blue: 178/255), background: Color(red: 207/255, green: 250/255, blue: 254/255))
        case "blue": return AwardColors(foreground: Color(red: 37/255, green: 99/255, blue: 235/255), background: Color(red: 219/255, green: 234/255, blue: 254/255))
        case "indigo": return AwardColors(foreground: Color(red: 79/255, green: 70/255, blue: 229/255), background: Color(red: 224/255, green: 231/255, blue: 255/255))
        case "violet": return AwardColors(foreground: Color(red: 124/255, green: 58/255, blue: 237/255), background: Color(red: 237/255, green: 233/255, blue: 254/255))
        case "purple": return AwardColors(foreground: Color(red: 147/255, green: 51/255, blue: 234/255), background: Color(red: 243/255, green: 232/255, blue: 255/255))
        case "pink": return AwardColors(foreground: Color(red: 219/255, green: 39/255, blue: 119/255), background: Color(red: 252/255, green: 231/255, blue: 243/255))
        case "rose": return AwardColors(foreground: Color(red: 225/255, green: 29/255, blue: 72/255), background: Color(red: 255/255, green: 228/255, blue: 230/255))
        case "amber": return AwardColors(foreground: Color(red: 217/255, green: 119/255, blue: 6/255), background: Color(red: 254/255, green: 243/255, blue: 199/255))
        case "orange": return AwardColors(foreground: Color(red: 234/255, green: 88/255, blue: 12/255), background: Color(red: 255/255, green: 237/255, blue: 213/255))
        case "yellow": return AwardColors(foreground: Color(red: 202/255, green: 138/255, blue: 4/255), background: Color(red: 254/255, green: 249/255, blue: 195/255))
        case "slate": return AwardColors(foreground: Color(red: 71/255, green: 85/255, blue: 105/255), background: Color(red: 241/255, green: 245/255, blue: 249/255))
        default: return from("emerald")
        }
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
        let colors = AwardColors.from(award.color)
        Button {
            showingDetail = true
        } label: {
            VStack(spacing: 4) {
                Image(systemName: award.icon)
                    .font(.system(size: 22))
                    .foregroundStyle(colors.foreground)
                    .frame(width: 48, height: 48)
                    .background(colors.background)
                    .clipShape(Circle())
                    .shadow(color: .black.opacity(0.06), radius: 4, y: 2)

                Text(award.name)
                    .font(.system(size: 10, weight: .medium, design: .rounded))
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
                    .multilineTextAlignment(.center)
                    .frame(width: 60)
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

    private var currentColors: AwardColors {
        guard awards.indices.contains(currentIndex) else { return AwardColors.from("emerald") }
        return AwardColors.from(awards[currentIndex].color)
    }

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    currentColors.foreground.opacity(0.7),
                    currentColors.foreground.opacity(0.2),
                    Color(red: 0.02, green: 0.02, blue: 0.05)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            .animation(.easeInOut(duration: 0.3), value: currentIndex)

            VStack(spacing: 0) {
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
            if let index = awards.firstIndex(where: { $0.id == initialAward.id }) {
                currentIndex = index
            }
        }
    }
}

// MARK: - Single Award Page
struct AwardPageView: View {
    let award: Award

    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: award.icon)
                .font(.system(size: 72))
                .foregroundStyle(.white)
                .frame(width: 180, height: 180)
                .background(.white.opacity(0.1))
                .clipShape(Circle())

            Text(award.name)
                .font(.system(size: 26, weight: .bold, design: .rounded))
                .foregroundStyle(.white)

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
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(alignment: .top, spacing: 12) {
                ForEach(awards) { award in
                    AwardBadgeView(award: award, allAwards: awards)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
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
                HStack(alignment: .top, spacing: 12) {
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
        Award(id: "first_steps", name: "First Steps", icon: "figure.walk", description: "Every journey begins with a single step", color: "emerald"),
        Award(id: "wanderer", name: "Wanderer", icon: "map", description: "The world is calling, and you're answering", color: "teal"),
        Award(id: "solo_adventurer", name: "Solo Adventurer", icon: "person.fill", description: "Brave enough to explore alone", color: "violet"),
        Award(id: "squad_goals", name: "Squad Goals", icon: "person.3.fill", description: "Everything's better with friends", color: "pink"),
    ])
    .padding(.vertical)
}
