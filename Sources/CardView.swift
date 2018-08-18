import UIKit

public protocol CardViewListener: class {
    func сardView(_ сardView: CardView, willBeginUpdatingOrigin origin: CGFloat, source: CardView.OriginChangeSource)
    func сardView(_ сardView: CardView, didUpdateOrigin origin: CGFloat, source: CardView.OriginChangeSource)
    func сardView(_ сardView: CardView, didEndUpdatingOrigin origin: CGFloat, source: CardView.OriginChangeSource)
}

open class CardView: UIView {

    public typealias ContentView = ShadeView.ContentView
    public typealias OriginChangeSource = ShadeView.OriginChangeSource

    public enum State {
        case top
        case middle
        case bottom
        case dismissed
    }
    
    public struct RelativePosition {
        public enum Edge {
            case top
            case bottom
        }
    
        public var offset: CGFloat
        public var edge: Edge
        
        init(offset: CGFloat, from edge: Edge) {
            self.offset = offset
            self.edge = edge
        }
        
        public static var zero: RelativePosition {
            return RelativePosition(offset: 0, from: .top)
        }
        
        public static func fromTop(_ offset: CGFloat) -> RelativePosition {
            return RelativePosition(offset: offset, from: .top)
        }
        
        public static func fromBottom(_ offset: CGFloat) -> RelativePosition {
            return RelativePosition(offset: offset, from: .bottom)
        }
    }

    public init(contentView: ContentView, headerView: UIView) {
        shadeView = ShadeView(contentView: contentView, headerView: headerView)
 
        super.init(frame: .zero)
        
        setupViews()
        contentView.addListener(self)
        shadeView.addListener(self)
    }
    
    open var contentView: ContentView {
        return shadeView.contentView
    }
    
    open var headerView: UIView {
        return shadeView.headerView
    }
    
    open var containerView: UIView {
        return shadeView.containerView
    }

    open var origin: CGFloat {
        return shadeView.origin
    }
    
    open var topPosition: RelativePosition = .zero {
        didSet {
            updateAnchors()
        }
    }
    
    /// Helper for topPosition
    open var topInset: CGFloat {
        get {
            return CardView.origin(for: topPosition, bounds: bounds)
        }
        set {
            topPosition = .fromTop(newValue)
        }
    }
    
    open var middlePosition: RelativePosition = .zero {
        didSet {
            updateAnchors()
        }
    }
    
    /// Default bottom inset is equal to headerHeight
    open var customBottomPosition: RelativePosition? = nil {
        didSet {
            updateAnchors()
        }
    }
    
    /// Indicates whether or not the card view should fit their height in the 'top' state ignoring the content size
    open var fitsHeight: Bool = false {
        didSet {
            updateAnchors()
        }
    }
    
    open var availableStates: Set<State> = [.top, .bottom, .middle] {
        didSet {
            updateAnchors()
        }
    }
    
    open var state: State? {
        let anchors = availableAnchors.sorted { $0.anchor < $1.anchor }
        
        if let first = anchors.first, origin <= first.anchor {
            return first.state
        }
        
        if let last = anchors.last, origin >= last.anchor {
            return last.state
        }
        
        return anchors.first(where: { $0.anchor == origin })?.state
    }
    
    open func scroll(to state: State, animated: Bool) {
        guard availableStates.contains(state) else { return }
        
        let newAnchor = anchor(for: state)
        shadeView.scroll(toOrigin: newAnchor, animated: animated)
    }
    
    /// Origins are bounds dependent. Use 'targetOrigin:for:bounds:' method if bounds are not ready.
    open func origin(for state: State) -> CGFloat {
        return anchor(for: state)
    }
    
    open func targetOrigin(for state: State, bounds: CGRect) -> CGFloat {
        return targetAnchor(for: state, bounds: bounds)
    }
    
    open func addListener(_ listener: CardViewListener) {
        notifier.subscribe(listener)
    }
    
    open func removeListener(_ listener: CardViewListener) {
        notifier.unsubscribe(listener)
    }
    
    public required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    deinit {
        // https://bugs.swift.org/browse/SR-5816
        headerObservation = nil
    }
    
    // MARK: - UIView
    
    open override func layoutSubviews() {
        super.layoutSubviews()
        
        let prevState = state
        
        updateAnchors()
        
        if let state = prevState {
            scroll(to: state, animated: false)
        }
    }
    
    @available(iOS 11.0, *)
    open override func safeAreaInsetsDidChange() {
        super.safeAreaInsetsDidChange()
        updateAnchors()
        if state == .bottom {
            scroll(to: .bottom, animated: false)
        }
    }
    
    override open func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
        return shadeView.point(inside: point, with: event)
    }

    // MARK: - Private
    
    private let shadeView: ShadeView
    private let notifier = Notifier<CardViewListener>()
    private var headerObservation: NSKeyValueObservation?

    private func setupViews() {
        addSubview(shadeView)
        shadeView.frame = bounds
        shadeView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        
        headerObservation = headerView.observe(\.bounds, options: .new) { [weak self] _, _ in
            self?.updateAnchors()
        }
    }
    
    private func getSafeAreaInsets() -> UIEdgeInsets {
        if #available(iOS 11.0, *) {
            return safeAreaInsets
        } else {
            return .zero
        }
    }
    
    private func updateContentVisibility() {
        guard #available(iOS 11.0, *), safeAreaInsets.bottom > 0 else {
            contentView.alpha = 1
            return
        }
        
        let fadingDistance: CGFloat = 40
        
        let diff = anchor(for: .bottom) - origin
        contentView.alpha = (diff / fadingDistance).clamped(to: 0...1)
    }
    
    // MARK: - Private: Anchors
    
    private struct AssociatedAnchor {
        var state: State
        var anchor: CGFloat
    }
    
    private func targetAnchorForTop(forBounds bounds: CGRect) -> CGFloat {
        let candidate = CardView.origin(for: topPosition, bounds: bounds)
        if fitsHeight {
            return candidate
        } else {
            let totalContentHeight = contentView.contentSize.height + shadeView.headerView.frame.height
                + getSafeAreaInsets().bottom
            
            let contentOrigin = CardView.origin(for: .fromBottom(totalContentHeight), bounds: bounds)
            
            return max(candidate, contentOrigin)
        }
    }
    
    private func targetAnchorForMiddle(forBounds bounds: CGRect) -> CGFloat {
        return CardView.origin(for: middlePosition, bounds: bounds)
    }
    
    private func targetAnchorForBottom(forBounds bounds: CGRect) -> CGFloat {
        if let customBottomPosition = customBottomPosition {
            return CardView.origin(for: customBottomPosition, bounds: bounds)
        } else {
            let bottomInset = shadeView.headerView.frame.height + getSafeAreaInsets().bottom
            return CardView.origin(for: .fromBottom(bottomInset), bounds: bounds)
        }
    }
    
    private func targetAnchorForDismissed(forBounds bounds: CGRect) -> CGFloat {
        return bounds.height
    }
    
    private func anchor(for state: State) -> CGFloat {
        return targetAnchor(for: state, bounds: bounds)
    }
    
    private func targetAnchor(for state: State, bounds: CGRect) -> CGFloat {
        switch state {
        case .top:
            return targetAnchorForTop(forBounds: bounds)
        case .middle:
            return targetAnchorForMiddle(forBounds: bounds)
        case .bottom:
            return targetAnchorForBottom(forBounds: bounds)
        case .dismissed:
            return targetAnchorForDismissed(forBounds: bounds)
        }
    }
    
    private func origin(for position: RelativePosition) -> CGFloat {
        return CardView.origin(for: position, bounds: bounds)
    }
    
    private static func origin(for position: RelativePosition, bounds: CGRect) -> CGFloat {
        switch (position.edge) {
        case .top:
            return position.offset
        case .bottom:
            return bounds.height - position.offset
        }
    }

    private var availableAnchors: [AssociatedAnchor] {
        return availableStates.map { AssociatedAnchor(state: $0, anchor: anchor(for: $0)) }
    }

    private func updateAnchors() {
        shadeView.anchors = availableAnchors.map { $0.anchor }
    }

}


extension CardView: ShadeViewListener {

    public func shadeView(_ shadeView: ShadeView, willBeginUpdatingOrigin origin: CGFloat,
        source: ShadeView.OriginChangeSource)
    {
        notifier.forEach { $0.сardView(self, willBeginUpdatingOrigin: origin, source: source) }
    }

    public func shadeView(_ shadeView: ShadeView, didUpdateOrigin origin: CGFloat,
        source: ShadeView.OriginChangeSource)
    {
        updateContentVisibility()
        notifier.forEach { $0.сardView(self, didUpdateOrigin: origin, source: source) }
    }
    
    public func shadeView(_ shadeView: ShadeView, didEndUpdatingOrigin origin: CGFloat,
        source: ShadeView.OriginChangeSource)
    {
        notifier.forEach { $0.сardView(self, didEndUpdatingOrigin: origin, source: source) }
    }
    
}


extension CardView: ShadeViewContentListener {
    
    public func shadeViewContent(_ shadeViewContent: ShadeViewContent, didChangeContentOffset contentOffset: CGPoint) {
        
    }
    
    public func shadeViewContent(_ shadeViewContent: ShadeViewContent, didChangeContentSize contentSize: CGSize) {
        updateAnchors()
    }
    
    public func shadeViewContent(_ shadeViewContent: ShadeViewContent, didChangeContentInset contentInset: UIEdgeInsets) {
        
    }
    
}
