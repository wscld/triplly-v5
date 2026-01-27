import SwiftUI

struct PaywallView: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.dismiss) private var dismiss

    @State private var isPurchasing = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 32) {
                    // Header
                    VStack(spacing: 16) {
                        Image(systemName: "airplane.circle.fill")
                            .font(.system(size: 80))
                            .foregroundStyle(Color.appPrimary)
                            .symbolEffect(.bounce)

                        Text("Upgrade to Pro")
                            .font(.largeTitle.bold())

                        Text("Unlock unlimited trips and premium features")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.top, 20)

                    // Features List
                    VStack(alignment: .leading, spacing: 16) {
                        FeatureRow(
                            icon: "infinity",
                            title: "Unlimited Trips",
                            description: "Create as many trips as you want"
                        )

                        FeatureRow(
                            icon: "person.3.fill",
                            title: "Unlimited Collaborators",
                            description: "Invite friends and family to plan together"
                        )

                        FeatureRow(
                            icon: "star.fill",
                            title: "Priority Support",
                            description: "Get help when you need it most"
                        )

                        FeatureRow(
                            icon: "sparkles",
                            title: "Early Access",
                            description: "Be the first to try new features"
                        )
                    }
                    .padding(.horizontal)

                    Spacer(minLength: 20)

                    // Pricing
                    VStack(spacing: 16) {
                        // Price Card
                        VStack(spacing: 8) {
                            Text("$4.99")
                                .font(.system(size: 48, weight: .bold))
                                .foregroundStyle(Color.appPrimary)

                            Text("per month")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 24)
                        .background(Color.appPrimary.opacity(0.1))
                        .clipShape(RoundedRectangle(cornerRadius: 16))

                        // Subscribe Button
                        Button {
                            Task { await subscribe() }
                        } label: {
                            HStack {
                                if isPurchasing {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                } else {
                                    Text("Subscribe Now")
                                        .fontWeight(.semibold)
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(Color.appPrimary)
                            .foregroundStyle(.white)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                        .disabled(isPurchasing)

                        // Restore Purchases
                        Button {
                            appState.restorePurchases()
                        } label: {
                            Text("Restore Purchases")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }

                        // Terms
                        Text("Cancel anytime. Subscription auto-renews monthly.")
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 20)
                }
            }
            .background(Color(.systemGroupedBackground))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title2)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
        .interactiveDismissDisabled(isPurchasing)
    }

    private func subscribe() async {
        isPurchasing = true

        // Simulate network delay for demo
        try? await Task.sleep(nanoseconds: 1_500_000_000)

        // In a real app, this would call StoreKit 2 or RevenueCat
        appState.purchaseSubscription()

        isPurchasing = false
        dismiss()
    }
}

// MARK: - Feature Row
private struct FeatureRow: View {
    let icon: String
    let title: String
    let description: String

    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(Color.appPrimary)
                .frame(width: 44, height: 44)
                .background(Color.appPrimary.opacity(0.1))
                .clipShape(Circle())

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline.weight(.semibold))

                Text(description)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()
        }
        .padding()
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

#Preview {
    PaywallView()
        .environmentObject(AppState())
}
