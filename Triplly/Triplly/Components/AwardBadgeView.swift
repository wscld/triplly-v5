import SwiftUI

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
            Image(systemName: award.icon)
                .font(.system(size: 22))
                .foregroundStyle(.emerald600)
                .frame(width: 48, height: 48)
                .background(.emerald100)
                .clipShape(Circle())
                .overlay(Circle().stroke(Color(.systemBackground), lineWidth: 2))
                .shadow(color: .black.opacity(0.06), radius: 4, y: 2)
        }
        .buttonStyle(.plain)
        .fullScreenCover(isPresented: $showingDetail) {
            AwardCarouselView(awards: allAwards, initialAward: award)
        }
    }
}

// MARK: - Emerald colors
private extension ShapeStyle where Self == Color {
    static var emerald100: Color { Color(red: 209/255, green: 250/255, blue: 229/255) }
    static var emerald600: Color { Color(red: 5/255, green: 150/255, blue: 105/255) }
}

// MARK: - Award Carousel View (full screen with paging)
struct AwardCarouselView: View {
    let awards: [Award]
    let initialAward: Award
    @Environment(\.dismiss) private var dismiss
    @State private var currentIndex: Int = 0

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(red: 5/255, green: 150/255, blue: 105/255).opacity(0.7),
                    Color(red: 5/255, green: 150/255, blue: 105/255).opacity(0.2),
                    Color(red: 0.02, green: 0.02, blue: 0.05)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

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
            HStack(spacing: -12) {
                ForEach(awards) { award in
                    AwardBadgeView(award: award, allAwards: awards)
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
                HStack(spacing: -12) {
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
