import UIKit

/// It is compatible with any type of UIScrollView and UIScrollViewDelegate:
/// (e.g. UITableViewDelegate, UICollectionViewDelegateFlowLayout and any other custom type).
/// Do not overwrite scrollView.delegate, it will be used by ScrollShadeViewContent.
open class ScrollShadeViewContent: ShadeViewContent {

    open var scrollView: UIScrollView {
        return impl.scrollView
    }
    
    open var delegate: UIScrollViewDelegate? {
        get {
            return impl.delegate
        }
        set {
            impl.delegate = newValue
        }
    }

    public init(scrollView: UIScrollView, delegate: UIScrollViewDelegate?) {
        impl = Impl(scrollView: scrollView, delegate: delegate)
    }

    // MARK: - ShadeViewContent
    
    public var view: UIView {
        return impl.view
    }
    
    public var contentOffset: CGPoint {
        get {
            return impl.contentOffset
        }
        set {
            impl.contentOffset = newValue
        }
    }
    
    public var contentSize: CGSize {
        return impl.contentSize
    }
    
    public var contentInset: UIEdgeInsets {
        return impl.contentInset
    }
    
    public func addListener(_ listener: ShadeViewContentListener) {
        impl.addListener(listener)
    }
    
    public func removeListener(_ listener: ShadeViewContentListener) {
        impl.removeListener(listener)
    }
    
    // MARK: - Private
    
    private typealias Impl = ScrollShadeViewContentImpl
    
    private let impl: Impl

}

// MARK: - Private Impl

private class ScrollShadeViewContentImpl: NSObject {
    
    let scrollView: UIScrollView
    
    weak var delegate: UIScrollViewDelegate? {
        didSet {
            delegateProxy.supplementaryDelegate = delegate
        }
    }
    
    init(scrollView: UIScrollView, delegate: UIScrollViewDelegate?) {
        self.scrollView = scrollView
        self.delegate = delegate
        
        super.init()
        
        delegateProxy.mainDelegate = self
        delegateProxy.supplementaryDelegate = delegate
        
        scrollView.delegate = delegateProxy
        
        scrollViewObservations = [
            scrollView.observe(\.contentSize, options: [.new, .old]) { [weak self] _, value in
                guard let slf = self, let newValue = value.newValue, value.isChanged else { return }
                self?.notifier.forEach { $0.shadeViewContent(slf, didChangeContentSize: newValue) }
            },
            scrollView.observe(\.contentInset, options: [.new, .old]) { [weak self] _, value in
                guard let slf = self, let newValue = value.newValue, value.isChanged else { return }
                self?.notifier.forEach { $0.shadeViewContent(slf, didChangeContentInset: newValue) }
            }
        ]
    }
    
    deinit {
        // https://bugs.swift.org/browse/SR-5816
        scrollViewObservations = []
    }
    
    // MARK: - Private
    
    private let notifier = Notifier<ShadeViewContentListener>()
    
    private var scrollViewObservations: [NSKeyValueObservation] = []
    
    private let delegateProxy = SVPrivateScrollDelegateProxy()
    
}

extension ScrollShadeViewContentImpl: ShadeViewContent {

    var view: UIView {
        return scrollView
    }
    
    var contentOffset: CGPoint {
        get {
            return scrollView.contentOffset
        }
        set {
            scrollView.contentOffset = newValue
        }
    }
    
    var contentSize: CGSize {
        return scrollView.contentSize
    }
    
    var contentInset: UIEdgeInsets {
        return scrollView.contentInset
    }
    
    func addListener(_ listener: ShadeViewContentListener) {
        notifier.subscribe(listener)
    }
    
    func removeListener(_ listener: ShadeViewContentListener) {
        notifier.unsubscribe(listener)
    }
    
}

extension ScrollShadeViewContentImpl: UIScrollViewDelegate {

    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        notifier.forEach { $0.shadeViewContentDidScroll(self) }
    }
    
    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        notifier.forEach { $0.shadeViewContentWillBeginDragging(self) }
    }
    
    func scrollViewWillEndDragging(_ scrollView: UIScrollView, withVelocity velocity: CGPoint,
        targetContentOffset: UnsafeMutablePointer<CGPoint>)
    {
        notifier.forEach {
            $0.shadeViewContentWillEndDragging(self, withVelocity: velocity, targetContentOffset: targetContentOffset)
        }
    }

}

private extension CGFloat {
    
    func isEqual(to other: CGFloat, eps: CGFloat) -> Bool {
        return abs(self - other) < eps
    }
    
}

private extension CGSize {
    
    func isEqual(to other: CGSize, eps: CGFloat) -> Bool {
        return width.isEqual(to: other.width, eps: eps)
            && height.isEqual(to: other.height, eps: eps)
    }
    
}

private extension UIEdgeInsets {
    
    func isEqual(to other: UIEdgeInsets, eps: CGFloat) -> Bool {
        return top.isEqual(to: other.top, eps: eps)
            && left.isEqual(to: other.left, eps: eps)
            && bottom.isEqual(to: other.bottom, eps: eps)
            && right.isEqual(to: other.right, eps: eps)
    }
    
}

private extension NSKeyValueObservedChange where Value == CGSize {
    
    var isChanged: Bool {
        if let new = newValue, let old = oldValue {
            return !old.isEqual(to: new, eps: 0.0001)
        } else {
            return newValue != oldValue
        }
    }
    
}

private extension NSKeyValueObservedChange where Value == UIEdgeInsets {
    
    var isChanged: Bool {
        if let new = newValue, let old = oldValue {
            return !old.isEqual(to: new, eps: 0.0001)
        } else {
            return newValue != oldValue
        }
    }
    
}
