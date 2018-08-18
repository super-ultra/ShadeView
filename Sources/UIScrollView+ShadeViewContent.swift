import UIKit

extension UIScrollView: ShadeViewContent {

    public func addListener(_ listener: ShadeViewContentListener) {
        state.notifier.subscribe(listener)
    }
    
    public func removeListener(_ listener: ShadeViewContentListener) {
        state.notifier.unsubscribe(listener)
    }

    // MARK: - Private

    private final class State {
        static let associatedObjectKey = "ShadeView.UIScrollView+ShadeViewContent.state"

        let notifier = Notifier<ShadeViewContentListener>()

        init(scrollView: UIScrollView) {
            self.scrollView = scrollView

            observers = [
                scrollView.observe(\.contentSize, options: .new) { [weak self] _, value in
                    guard let scrollView = self?.scrollView, let newValue = value.newValue else { return }
                    self?.notifier.forEach { $0.shadeViewContent(scrollView, didChangeContentSize: newValue) }
                },
                scrollView.observe(\.contentInset, options: .new) { [weak self] _, value in
                    guard let scrollView = self?.scrollView, let newValue = value.newValue else { return }
                    self?.notifier.forEach { $0.shadeViewContent(scrollView, didChangeContentInset: newValue) }
                },
                scrollView.observe(\.contentOffset, options: .new) { [weak self] _, value in
                    guard let scrollView = self?.scrollView, let newValue = value.newValue else { return }
                    self?.notifier.forEach { $0.shadeViewContent(scrollView, didChangeContentOffset: newValue) }
                }
            ]
        }

        deinit {
            // https://bugs.swift.org/browse/SR-5816
            observers = []
        }

        // MARK: - Private

        private weak var scrollView: UIScrollView?
        private var observers: [NSKeyValueObservation] = []
    }

    private var state: State {
        get {
            if let obj = objc_getAssociatedObject(self, State.associatedObjectKey) as? State {
                return obj
            }
            let newState = State(scrollView: self)
            objc_setAssociatedObject(self, State.associatedObjectKey, newState, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
            return newState
        }
        set {
            objc_setAssociatedObject(self, State.associatedObjectKey, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }
}
