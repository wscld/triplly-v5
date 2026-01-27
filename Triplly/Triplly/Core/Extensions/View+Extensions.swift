import SwiftUI
import UIKit

// MARK: - Conditional Modifier
extension View {
    @ViewBuilder
    func `if`<Content: View>(_ condition: Bool, transform: (Self) -> Content) -> some View {
        if condition {
            transform(self)
        } else {
            self
        }
    }

    @ViewBuilder
    func ifLet<Value, Content: View>(_ value: Value?, transform: (Self, Value) -> Content) -> some View {
        if let value = value {
            transform(self, value)
        } else {
            self
        }
    }
}

// MARK: - Hide Keyboard
extension View {
    func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}

// MARK: - Shake Effect
struct ShakeEffect: GeometryEffect {
    var amount: CGFloat = 10
    var shakesPerUnit = 3
    var animatableData: CGFloat

    func effectValue(size: CGSize) -> ProjectionTransform {
        ProjectionTransform(CGAffineTransform(translationX:
            amount * sin(animatableData * .pi * CGFloat(shakesPerUnit)),
            y: 0))
    }
}

extension View {
    func shake(trigger: Bool) -> some View {
        modifier(ShakeModifier(trigger: trigger))
    }
}

struct ShakeModifier: ViewModifier {
    let trigger: Bool
    @State private var shake: CGFloat = 0

    func body(content: Content) -> some View {
        content
            .modifier(ShakeEffect(animatableData: shake))
            .onChange(of: trigger) { _, _ in
                withAnimation(.default) {
                    shake += 1
                }
            }
    }
}

// MARK: - Placeholder Style
extension View {
    func placeholder<Content: View>(
        when shouldShow: Bool,
        alignment: Alignment = .leading,
        @ViewBuilder placeholder: () -> Content
    ) -> some View {
        ZStack(alignment: alignment) {
            placeholder().opacity(shouldShow ? 1 : 0)
            self
        }
    }
}

// MARK: - Corner Radius with Specific Corners
extension View {
    func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        clipShape(RoundedCorner(radius: radius, corners: corners))
    }
}

struct RoundedCorner: Shape {
    var radius: CGFloat = .infinity
    var corners: UIRectCorner = .allCorners

    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(
            roundedRect: rect,
            byRoundingCorners: corners,
            cornerRadii: CGSize(width: radius, height: radius)
        )
        return Path(path.cgPath)
    }
}

// MARK: - Scrollable Bottom Sheet
struct ScrollOffsetPreferenceKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}

extension View {
    func onScrollOffset(_ action: @escaping (CGFloat) -> Void) -> some View {
        self
            .background(
                GeometryReader { geo in
                    Color.clear
                        .preference(
                            key: ScrollOffsetPreferenceKey.self,
                            value: geo.frame(in: .named("scroll")).minY
                        )
                }
            )
            .onPreferenceChange(ScrollOffsetPreferenceKey.self, perform: action)
    }
}

// MARK: - Enable Interactive Pop Gesture
extension View {
    func enableInteractivePopGesture() -> some View {
        background(InteractivePopGestureEnabler())
    }
}

struct InteractivePopGestureEnabler: UIViewControllerRepresentable {
    func makeUIViewController(context: Context) -> UIViewController {
        InteractivePopGestureController()
    }

    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {}
}

private class InteractivePopGestureController: UIViewController {
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        enablePopGesture()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        enablePopGesture()
    }

    private func enablePopGesture() {
        if let navigationController = self.navigationController {
            navigationController.interactivePopGestureRecognizer?.isEnabled = true
            navigationController.interactivePopGestureRecognizer?.delegate = nil
        }
    }
}

// MARK: - View Lifecycle Callbacks
extension View {
    func onWillAppear(_ perform: @escaping () -> Void) -> some View {
        background(ViewLifecycleHandler(onDidAppear: nil, onWillAppear: perform, onWillDisappear: nil, animateAlongsideDisappear: nil))
    }

    func onWillDisappear(_ perform: @escaping () -> Void) -> some View {
        background(ViewLifecycleHandler(onDidAppear: nil, onWillAppear: nil, onWillDisappear: perform, animateAlongsideDisappear: nil))
    }

    func onViewLifecycle(willAppear: @escaping () -> Void, willDisappear: @escaping () -> Void) -> some View {
        background(ViewLifecycleHandler(onDidAppear: nil, onWillAppear: willAppear, onWillDisappear: willDisappear, animateAlongsideDisappear: nil))
    }

    func onViewLifecycle(didAppear: @escaping () -> Void, willDisappear: @escaping () -> Void) -> some View {
        background(ViewLifecycleHandler(onDidAppear: didAppear, onWillAppear: nil, onWillDisappear: willDisappear, animateAlongsideDisappear: nil))
    }

    /// Lifecycle callback with coordinated animation during navigation transition
    func onViewLifecycle(didAppear: @escaping () -> Void, animateAlongsideDisappear: @escaping () -> Void) -> some View {
        background(ViewLifecycleHandler(onDidAppear: didAppear, onWillAppear: nil, onWillDisappear: nil, animateAlongsideDisappear: animateAlongsideDisappear))
    }
}

struct ViewLifecycleHandler: UIViewControllerRepresentable {
    let onDidAppear: (() -> Void)?
    let onWillAppear: (() -> Void)?
    let onWillDisappear: (() -> Void)?
    let animateAlongsideDisappear: (() -> Void)?

    func makeUIViewController(context: Context) -> UIViewController {
        ViewLifecycleController(
            onDidAppear: onDidAppear,
            onWillAppear: onWillAppear,
            onWillDisappear: onWillDisappear,
            animateAlongsideDisappear: animateAlongsideDisappear
        )
    }

    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {
        if let controller = uiViewController as? ViewLifecycleController {
            controller.onDidAppear = onDidAppear
            controller.onWillAppear = onWillAppear
            controller.onWillDisappear = onWillDisappear
            controller.animateAlongsideDisappear = animateAlongsideDisappear
        }
    }
}

private class ViewLifecycleController: UIViewController {
    var onDidAppear: (() -> Void)?
    var onWillAppear: (() -> Void)?
    var onWillDisappear: (() -> Void)?
    var animateAlongsideDisappear: (() -> Void)?

    init(onDidAppear: (() -> Void)?, onWillAppear: (() -> Void)?, onWillDisappear: (() -> Void)?, animateAlongsideDisappear: (() -> Void)?) {
        self.onDidAppear = onDidAppear
        self.onWillAppear = onWillAppear
        self.onWillDisappear = onWillDisappear
        self.animateAlongsideDisappear = animateAlongsideDisappear
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        onWillAppear?()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        onDidAppear?()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)

        guard isMovingFromParent || isBeingDismissed else { return }

        // Regular callback
        onWillDisappear?()

        // Coordinated animation with navigation transition
        if let animateBlock = animateAlongsideDisappear {
            if let coordinator = transitionCoordinator {
                coordinator.animate(alongsideTransition: { _ in
                    animateBlock()
                }, completion: nil)
            } else {
                // Fallback if no coordinator
                animateBlock()
            }
        }
    }
}
