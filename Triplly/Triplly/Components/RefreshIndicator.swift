import SwiftUI

// MARK: - Pull-to-Refresh Offset Tracker

private struct ScrollOffsetKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}

struct PullToRefreshAnchor: View {
    let coordinateSpace: String

    var body: some View {
        GeometryReader { geo in
            Color.clear.preference(
                key: ScrollOffsetKey.self,
                value: geo.frame(in: .named(coordinateSpace)).minY
            )
        }
        .frame(height: 0)
    }
}

// MARK: - Pull-to-Refresh Modifier

struct PullToRefreshModifier: ViewModifier {
    @Binding var isRefreshing: Bool
    let action: () async -> Void

    @State private var pullOffset: CGFloat = 0
    @State private var restingOffset: CGFloat?
    @State private var hasTriggered = false

    private let threshold: CGFloat = 100
    private let coordinateSpace = "ptr_scroll"

    func body(content: Content) -> some View {
        content
            .coordinateSpace(name: coordinateSpace)
            .onPreferenceChange(ScrollOffsetKey.self) { value in
                // Capture resting offset on first reading
                if restingOffset == nil {
                    restingOffset = value
                }

                let pulled = value - (restingOffset ?? 0)
                pullOffset = max(0, pulled)

                if pulled > threshold && !isRefreshing && !hasTriggered {
                    hasTriggered = true
                    UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                    Task {
                        withAnimation(.easeInOut(duration: 0.25)) {
                            isRefreshing = true
                        }
                        await action()
                        withAnimation(.easeInOut(duration: 0.25)) {
                            isRefreshing = false
                        }
                        hasTriggered = false
                    }
                }
            }
            .overlay {
                ZStack {
                    // Pull progress indicator (visible while dragging, before trigger)
                    if pullOffset > 10 && !isRefreshing {
                        PullProgressIndicator(progress: min(pullOffset / threshold, 1.0))
                            .transition(.opacity)
                    }

                    // Full overlay once refreshing
                    if isRefreshing {
                        RefreshOverlay()
                            .transition(.opacity)
                    }
                }
                .animation(.easeInOut(duration: 0.2), value: isRefreshing)
                .animation(.easeInOut(duration: 0.15), value: pullOffset > 10)
            }
    }
}

extension View {
    func pullToRefresh(isRefreshing: Binding<Bool>, action: @escaping () async -> Void) -> some View {
        modifier(PullToRefreshModifier(isRefreshing: isRefreshing, action: action))
    }
}

// MARK: - Pull Progress Indicator (pre-trigger)

private struct PullProgressIndicator: View {
    let progress: CGFloat

    var body: some View {
        VStack {
            ZStack {
                Circle()
                    .stroke(Color.appPrimary.opacity(0.15), lineWidth: 2.5)
                    .frame(width: 32, height: 32)

                Circle()
                    .trim(from: 0, to: progress)
                    .stroke(Color.appPrimary, style: StrokeStyle(lineWidth: 2.5, lineCap: .round))
                    .frame(width: 32, height: 32)
                    .rotationEffect(.degrees(-90))

                if progress >= 1.0 {
                    Image(systemName: "arrow.down")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(Color.appPrimary)
                        .transition(.scale.combined(with: .opacity))
                } else {
                    Image(systemName: "arrow.down")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(Color.appPrimary.opacity(0.5))
                }
            }
            .padding(.top, 60)

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .allowsHitTesting(false)
    }
}

// MARK: - Refresh Overlay (post-trigger)

struct RefreshOverlay: View {
    @State private var rotation: Double = 0
    @State private var appeared = false

    var body: some View {
        ZStack {
            LinearGradient(
                stops: [
                    .init(color: Color(.systemBackground).opacity(0.85), location: 0),
                    .init(color: Color(.systemBackground).opacity(0.4), location: 0.5),
                    .init(color: .clear, location: 1)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            VStack(spacing: 14) {
                ZStack {
                    Circle()
                        .stroke(Color.appPrimary.opacity(0.2), lineWidth: 3)
                        .frame(width: 48, height: 48)
                        .scaleEffect(appeared ? 1.15 : 0.9)
                        .opacity(appeared ? 0.0 : 0.6)
                        .animation(
                            .easeInOut(duration: 1.2).repeatForever(autoreverses: false),
                            value: appeared
                        )

                    Circle()
                        .trim(from: 0, to: 0.7)
                        .stroke(
                            AngularGradient(
                                colors: [Color.appPrimary.opacity(0), Color.appPrimary],
                                center: .center
                            ),
                            style: StrokeStyle(lineWidth: 3, lineCap: .round)
                        )
                        .frame(width: 36, height: 36)
                        .rotationEffect(.degrees(rotation))

                    Image(systemName: "airplane")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(Color.appPrimary)
                }

                Text("Refreshing...")
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(.secondary)
            }
            .padding(.top, 80)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            .scaleEffect(appeared ? 1.0 : 0.8)
            .opacity(appeared ? 1.0 : 0.0)
        }
        .allowsHitTesting(false)
        .onAppear {
            withAnimation(.easeOut(duration: 0.3)) {
                appeared = true
            }
            withAnimation(.linear(duration: 1.0).repeatForever(autoreverses: false)) {
                rotation = 360
            }
        }
    }
}
