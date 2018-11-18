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
        
        public enum Point {
            case cardOrigin
            case contentOrigin
        }
    
        public var offset: CGFloat
        public var edge: Edge
        public var point: Point
        public var isAdjustedBySafeArea: Bool
        
        init(offset: CGFloat, edge: Edge, point: Point = .cardOrigin, isAdjustedBySafeArea: Bool = true) {
            self.offset = offset
            self.edge = edge
            self.point = point
            self.isAdjustedBySafeArea = isAdjustedBySafeArea
        }
        
        public static func fromTop(_ offset: CGFloat, relativeTo point: Point = .cardOrigin) -> RelativePosition {
            return RelativePosition(offset: offset, edge: .top, point: point, isAdjustedBySafeArea: false)
        }
        
        public static func fromBottom(_ offset: CGFloat, relativeTo point: Point = .cardOrigin) -> RelativePosition {
            return RelativePosition(offset: offset, edge: .bottom, point: point, isAdjustedBySafeArea: false)
        }
        
        public static func fromSafeAreaTop(_ offset: CGFloat, relativeTo point: Point = .cardOrigin)
            -> RelativePosition
        {
            return RelativePosition(offset: offset, edge: .top, point: point, isAdjustedBySafeArea: true)
        }
        
        public static func fromSafeAreaBottom(_ offset: CGFloat, relativeTo point: Point = .cardOrigin)
            -> RelativePosition
        {
            return RelativePosition(offset: offset, edge: .bottom, point: point, isAdjustedBySafeArea: true)
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
    
    open var topPosition: RelativePosition = .fromSafeAreaTop(0) {
        didSet {
            updateAnchors()
        }
    }
    
    /// Helper for topPosition
    open var topInset: CGFloat {
        get {
            return origin(for: topPosition)
        }
        set {
            topPosition = .fromTop(newValue)
        }
    }
    
    open var middlePosition: RelativePosition = .fromSafeAreaBottom(0, relativeTo: .contentOrigin) {
        didSet {
            updateAnchors()
        }
    }
    
    open var bottomPosition: RelativePosition = .fromSafeAreaBottom(0, relativeTo: .contentOrigin) {
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
    
    /// Origins are layout dependent. Use 'targetOrigin:for:boundsHeight:headerHeight' method if the view is not layouted.
    open func origin(for state: State) -> CGFloat {
        return anchor(for: state)
    }
    
    open func targetOrigin(for state: State, boundsHeight: CGFloat) -> CGFloat {
        return targetAnchor(for: state, boundsHeight: boundsHeight, headerHeight: headerView.frame.height)
    }
    
    open func targetOrigin(for state: State, boundsHeight: CGFloat, headerHeight: CGFloat) -> CGFloat {
        return targetAnchor(for: state, boundsHeight: boundsHeight, headerHeight: headerHeight)
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
    
    private func targetAnchorForTop(boundsHeight: CGFloat, headerHeight: CGFloat) -> CGFloat {
        let candidate = targetOrigin(for: topPosition, boundsHeight: boundsHeight, headerHeight: headerHeight)
        if fitsHeight {
            return candidate
        } else {
            let contentOriginPosition: RelativePosition =
                .fromSafeAreaBottom(contentView.contentSize.height, relativeTo: .contentOrigin)
            
            let contentOrigin = targetOrigin(for: contentOriginPosition, boundsHeight: boundsHeight,
                headerHeight: headerHeight)
            
            return max(candidate, contentOrigin)
        }
    }
    
    private func targetAnchorForMiddle(boundsHeight: CGFloat, headerHeight: CGFloat) -> CGFloat {
        return targetOrigin(for: middlePosition, boundsHeight: boundsHeight, headerHeight: headerHeight)
    }
    
    private func targetAnchorForBottom(boundsHeight: CGFloat, headerHeight: CGFloat) -> CGFloat {
        return targetOrigin(for: bottomPosition, boundsHeight: boundsHeight, headerHeight: headerHeight)
    }
    
    private func targetAnchorForDismissed(boundsHeight: CGFloat) -> CGFloat {
        return boundsHeight
    }
    
    private func anchor(for state: State) -> CGFloat {
        return targetAnchor(for: state, boundsHeight: bounds.height, headerHeight: headerView.frame.height)
    }
    
    private func targetAnchor(for state: State, boundsHeight: CGFloat, headerHeight: CGFloat) -> CGFloat {
        switch state {
        case .top:
            return targetAnchorForTop(boundsHeight: boundsHeight, headerHeight: headerHeight)
        case .middle:
            return targetAnchorForMiddle(boundsHeight: boundsHeight, headerHeight: headerHeight)
        case .bottom:
            return targetAnchorForBottom(boundsHeight: boundsHeight, headerHeight: headerHeight)
        case .dismissed:
            return targetAnchorForDismissed(boundsHeight: boundsHeight)
        }
    }
    
    private func origin(for position: RelativePosition) -> CGFloat {
        return targetOrigin(for: position, boundsHeight: bounds.height, headerHeight: headerView.frame.height)
    }
    
    private func targetOrigin(for position: RelativePosition, boundsHeight: CGFloat, headerHeight: CGFloat) -> CGFloat {
        var result: CGFloat = position.offset
    
        switch (position.edge) {
        case .top:
            if position.isAdjustedBySafeArea {
                result += getSafeAreaInsets().top
            }
        case .bottom:
            result = boundsHeight - result
            
            if position.isAdjustedBySafeArea {
                result -= getSafeAreaInsets().bottom
            }
        }
        
        if position.point == .contentOrigin {
            result -= headerHeight
        }
        
        return result
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
