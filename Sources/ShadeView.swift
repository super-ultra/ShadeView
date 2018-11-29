import UIKit
import pop

public protocol ShadeViewListener: class {
    func shadeView(_ shadeView: ShadeView, willBeginUpdatingOrigin origin: CGFloat, source: ShadeView.OriginChangeSource)
    func shadeView(_ shadeView: ShadeView, didUpdateOrigin origin: CGFloat, source: ShadeView.OriginChangeSource)
    func shadeView(_ shadeView: ShadeView, didEndUpdatingOrigin origin: CGFloat, source: ShadeView.OriginChangeSource)
}

open class ShadeView: UIView {

    public enum OriginChangeSource {
        case contentInteraction
        case headerInteraction
        case program
    }

    public typealias Content = ShadeViewContent

    public let content: Content
    
    public let headerView: UIView
    
    /// The view containing the header view and the content view.
    /// It represents the visible and tappable area of the ShadeView.
    /// E.g. it can be used for a shadow or mask.
    public let containerView: UIView

    public private(set) var origin: CGFloat {
        didSet {
            containerOriginConstraint?.constant = origin
        }
    }
    
    open var anchors: [CGFloat] {
        didSet {
            updateContentConstraints()
        }
    }
    
    public init(content: Content, headerView: UIView) {
        self.content = content
        self.headerView = headerView
        self.containerView = UIView()
        self.origin = 0
        self.anchors = []

        super.init(frame: .zero)
        
        setupViews()
    }
    
    open func scroll(toOrigin origin: CGFloat, animated: Bool, completion: ((Bool) -> Void)? = nil) {
        notifyWillBeginUpdatingOrigin(with: .program)
        moveOrigin(to: origin, source: .program, animated: animated, completion: completion)
    }
    
    open func addListener(_ listener: ShadeViewListener) {
        notifier.subscribe(listener)
    }
    
    open func removeListener(_ listener: ShadeViewListener) {
        notifier.unsubscribe(listener)
    }
    
    public required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - UIView
    
    override open func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
        let visibleRect = CGRect(x: 0.0, y: origin, width: bounds.width, height: bounds.height - origin)
        return visibleRect.contains(point)
    }
    
    override open func layoutSubviews() {
        super.layoutSubviews()
        updateContentConstraints()
    }
    
    // MARK: - Private
    
    private let notifier = Notifier<ShadeViewListener>()
    
    private var containerOriginConstraint: NSLayoutConstraint?
    
    private func setupViews() {
        addSubview(containerView)
    
        containerView.addSubview(content.view)
        content.view.clipsToBounds = false
        content.addListener(self)
        
        containerView.addSubview(headerView)
        headerView.addGestureRecognizer(headerPanRecognizer)
        headerPanRecognizer.addTarget(self, action: #selector(handleHeaderPanRecognizer))
        
        setupLayout()
    }
    
    private func setupLayout() {
        containerView.translatesAutoresizingMaskIntoConstraints = false
        containerView.set([.left, .right, .bottom], equalTo: self)
        containerOriginConstraint = containerView.set(.top, equalTo: self, constant: origin, priority: .fittingSizeLevel)
    
        content.view.translatesAutoresizingMaskIntoConstraints = false
        content.view.set([.left, .right], equalTo: containerView)
        content.view.set(.top, equalTo: headerView, attribute: .bottom)
        
        contentBottomConstraint = content.view.set(.bottom, equalTo: containerView, attribute: .top,
            constant: targetContentBottomPosition, priority: .fittingSizeLevel)
        
        headerView.translatesAutoresizingMaskIntoConstraints = false
        headerView.set([.left, .right, .top], equalTo: containerView)
        if headerView.constraints.isEmpty && !type(of: headerView).requiresConstraintBasedLayout {
            headerView.set(.height, equalTo: headerView.frame.height, priority: .fittingSizeLevel)
        }
    }
    
    private func setOrigin(_ origin: CGFloat, source: OriginChangeSource) {
        self.origin = origin
        notifier.forEach { $0.shadeView(self, didUpdateOrigin: origin, source: source) }
    }
    
    private func notifyWillBeginUpdatingOrigin(with source: OriginChangeSource) {
        notifier.forEach { $0.shadeView(self, willBeginUpdatingOrigin: origin, source: source) }
    }
    
    private func notifyDidEndUpdatingOrigin(with source: OriginChangeSource) {
        notifier.forEach { $0.shadeView(self, didEndUpdatingOrigin: origin, source: source) }
    }
    
    // MARK: - Private: Content
    
    private enum ContentState: Equatable {
        case normal
        case dragging(lastContentOffset: CGPoint)
    }
    
    private var contentState: ContentState = .normal
    
    private var contentBottomConstraint: NSLayoutConstraint?
    
    private func updateContentConstraints() {
        contentBottomConstraint?.constant = targetContentBottomPosition
    }
    
    private var targetContentBottomPosition: CGFloat {
        if let anchorLimits = anchorLimits {
            return bounds.height - anchorLimits.lowerBound
        } else {
            return bounds.height
        }
    }
    
    // MARK: - Private: Header
    
    private struct Static {
        static let originAnimationKey = "ShadeView.originAnimation"
    }

    private enum HeaderState: Equatable {
        case normal
        case dragging(initialOrigin: CGFloat)
    }
    
    private var headerState: HeaderState = .normal
    
    private let headerPanRecognizer = UIPanGestureRecognizer()
    
    private var anchorLimits: ClosedRange<CGFloat>? {
        if let min = anchors.min(), let max = anchors.max() {
            return min...max
        } else {
            return nil
        }
    }
    
    private var isHeaderInteractionEnabled: Bool {
        return anchors.count > 1 || origin != anchors.first
    }
    
    @objc private func handleHeaderPanRecognizer(_ sender: UIPanGestureRecognizer) {
        if !isHeaderInteractionEnabled {
            return
        }
    
        switch sender.state {
        case .began:
            stopOriginAnimation()
            headerState = .dragging(initialOrigin: origin)
            notifyWillBeginUpdatingOrigin(with: .headerInteraction)
        
        case .changed:
            let translation = sender.translation(in: headerView)
        
            if case .dragging(let initialOrigin) = headerState {
                let newOrigin = trimTargetHeaderOrigin(initialOrigin + translation.y)
                setOrigin(newOrigin, source: .headerInteraction)
            }
        
        case .ended:
            headerState = .normal
            
            let velocity = sender.velocity(in: headerView).y / 1000
            
            moveOriginToTheNearestAnchor(withVelocity: velocity, source: .headerInteraction)
            
        case .cancelled, .failed:
            headerState = .normal
            notifyDidEndUpdatingOrigin(with: .headerInteraction)
        
        case .possible:
            break
        }
    }
    
    private func trimTargetHeaderOrigin(_ target: CGFloat) -> CGFloat {
        if let limits = anchorLimits {
            if target < limits.lowerBound {
                return limits.lowerBound - sqrt(limits.lowerBound - target)
            } else if target > limits.upperBound {
                return limits.upperBound + sqrt(target - limits.upperBound)
            }
        }
        return target
    }
    
    private func moveOriginToTheNearestAnchor(withVelocity velocity: CGFloat, source: OriginChangeSource,
        completion: ((Bool) -> Void)? = nil)
    {
        // TODO: Compute decelerationRate using anchors
        let decelerationRate = (UIScrollView.DecelerationRate.normal.rawValue + UIScrollView.DecelerationRate.fast.rawValue) / 2
        let projection = origin.project(initialVelocity: velocity, decelerationRate: decelerationRate)
        
        if let anchor = anchors.nearestElement(to: projection) {
            moveOrigin(to: anchor, source: source, animated: true, velocity: velocity)
        }
    }
    
    private func moveOrigin(to newOriginY: CGFloat, source: OriginChangeSource, animated: Bool,velocity: CGFloat? = nil,
        completion: ((Bool) -> Void)? = nil)
    {
        if !animated {
            setOrigin(newOriginY, source: source)
            notifyDidEndUpdatingOrigin(with: source)
            completion?(true)
            return
        }
    
        let animation: POPSpringAnimation = POPSpringAnimation(
            customPropertyRead: { obj, values in
                guard let obj = obj as? ShadeView, let values = values else { return }
                values[0] = obj.origin
            },
            write: { [source] obj, values in
                guard let obj = obj as? ShadeView, let values = values else { return }
                obj.setOrigin(values[0], source: source)
            }
        )
    
        animation.velocity = velocity
        animation.toValue = newOriginY
        animation.fromValue = origin
        animation.springBounciness = 2
        animation.completionBlock = { [weak self, source] animation, finished in
            self?.notifyDidEndUpdatingOrigin(with: source)
            completion?(finished)
        }

        pop_add(animation, forKey: Static.originAnimationKey)
    }
    
    private func stopOriginAnimation() {
        pop_removeAnimation(forKey: Static.originAnimationKey)
    }

}

extension ShadeView: ShadeViewContentListener {

    public func shadeViewContent(_ shadeViewContent: ShadeViewContent, didChangeContentSize contentSize: CGSize) {
    }
    
    public func shadeViewContent(_ shadeViewContent: ShadeViewContent, didChangeContentInset contentInset: UIEdgeInsets) {
    }
    
    public func shadeViewContentDidScroll(_ shadeViewContent: ShadeViewContent) {
        guard case let .dragging(lastContentOffset) = contentState else { return }
        
        defer {
            contentState = .dragging(lastContentOffset: shadeViewContent.contentOffset)
        }
        
        guard let limits = anchorLimits, isHeaderInteractionEnabled else { return }
        
        let diff = lastContentOffset.y - shadeViewContent.contentOffset.y
    
        if (diff < 0 && origin > limits.lowerBound)
            || (diff > 0 && shadeViewContent.contentOffset.y < -shadeViewContent.contentInset.top)
        {
            // Drop contentOffset changing
            shadeViewContent.removeListener(self)
            shadeViewContent.contentOffset.y = -shadeViewContent.contentInset.top
            shadeViewContent.addListener(self)
            
            let newOrigin: CGFloat
            
            if diff > 0 {
                newOrigin = origin + diff
            } else {
                newOrigin = (origin + diff).clamped(to: limits)
            }
            
            setOrigin(newOrigin, source: .contentInteraction)
        }
    }
    
    public func shadeViewContentWillBeginDragging(_ shadeViewContent: ShadeViewContent) {
        contentState = .dragging(lastContentOffset: shadeViewContent.contentOffset)
        
        stopOriginAnimation()
        notifyWillBeginUpdatingOrigin(with: .contentInteraction)
    }
    
    public func shadeViewContentWillEndDragging(_ shadeViewContent: ShadeViewContent, withVelocity velocity: CGPoint,
        targetContentOffset: UnsafeMutablePointer<CGPoint>)
    {
        contentState = .normal
    
        guard let limits = anchorLimits, origin > limits.lowerBound else { return }
        
        /// Stop scrolling
        targetContentOffset.pointee = shadeViewContent.contentOffset
        
        moveOriginToTheNearestAnchor(withVelocity: -velocity.y, source: .contentInteraction)
    }
    
}
