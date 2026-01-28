import SwiftUI

struct AwardBadgeView: View {
    let award: Award
    @State private var showingDetail = false

    var body: some View {
        Button {
            showingDetail = true
        } label: {
            VStack(spacing: 8) {
                Image(systemName: award.icon)
                    .font(.system(size: 22))
                    .foregroundStyle(.white)
                    .frame(width: 48, height: 48)
                    .background(Color.appPrimary.gradient)
                    .clipShape(Circle())

                Text(award.name)
                    .font(.caption2.weight(.medium))
                    .foregroundStyle(.primary)
                    .lineLimit(1)
                    .frame(width: 72)
            }
        }
        .popover(isPresented: $showingDetail, arrowEdge: .bottom) {
            VStack(spacing: 8) {
                Image(systemName: award.icon)
                    .font(.system(size: 28))
                    .foregroundStyle(Color.appPrimary)

                Text(award.name)
                    .font(.subheadline.bold())

                Text(award.description)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            .padding()
            .frame(width: 200)
            .presentationCompactAdaptation(.popover)
        }
    }
}

// MARK: - Awards Section
struct AwardsSection: View {
    let awards: [Award]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Awards")
                .font(.headline)
                .padding(.horizontal)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 16) {
                    ForEach(awards) { award in
                        AwardBadgeView(award: award)
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
