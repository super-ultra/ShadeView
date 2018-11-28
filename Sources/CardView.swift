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
        public var ignoresSafeArea: Bool
        
        init(offset: CGFloat, edge: Edge, point: Point = .cardOrigin, ignoresSafeArea: Bool = false) {
            self.offset = offset
            self.edge = edge
            self.point = point
            self.ignoresSafeArea = ignoresSafeArea
        }
        
        public static func fromTop(_ offset: CGFloat, relativeTo point: Point = .cardOrigin,
            ignoresSafeArea: Bool = false) -> RelativePosition
        {
            return RelativePosition(offset: offset, edge: .top, point: point, ignoresSafeArea: ignoresSafeArea)
        }
        
        public static func fromBottom(_ offset: CGFloat, relativeTo point: Point = .cardOrigin,
            ignoresSafeArea: Bool = false) -> RelativePosition
        {
            return RelativePosition(offset: offset, edge: .bottom, point: point, ignoresSafeArea: ignoresSafeArea)
        }
    }
    
    public struct PositionDependencies {
        public var boundsHeight: CGFloat
        public var headerHeight: CGFloat
        public var safeAreaInsets: UIEdgeInsets
        
        public init(boundsHeight: CGFloat, headerHeight: CGFloat, safeAreaInsets: UIEdgeInsets) {
            self.boundsHeight = boundsHeight
            self.headerHeight = headerHeight
            self.safeAreaInsets = safeAreaInsets
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
    
    open var topPosition: RelativePosition = .fromTop(0) {
        didSet {
            updateAnchors()
        }
    }
    
    open var middlePosition: RelativePosition = .fromBottom(0, relativeTo: .contentOrigin) {
        didSet {
            updateAnchors()
        }
    }
    
    open var bottomPosition: RelativePosition = .fromBottom(0, relativeTo: .contentOrigin) {
        didSet {
            updateAnchors()
        }
    }
    
    /// Indicates whether or not the card positions should be constrained by the content size
    open var isConstrainedByContentSize: Bool = true {
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
    
    /// Origins are layout dependent. All dependencies are declared in PositionDependencies.
    /// Use 'targetOrigin:for:positionDependencies' method if the view is not layouted.
    open func origin(for state: State) -> CGFloat {
        return anchor(for: state)
    }
    
    open func targetOrigin(for state: State, positionDependencies: PositionDependencies) -> CGFloat {
        return targetAnchor(for: state, positionDependencies: positionDependencies)
    }
    
    open var cornerRadius: CGFloat {
        set {
            if newValue > 0 {
                containerView.mask = CornerRadiusMaskView(radius: newValue)
                containerView.mask?.frame = bounds
            } else {
                containerView.mask = nil
            }
        }
        get {
            return (containerView.mask as? CornerRadiusMaskView)?.radius ?? 0
        }
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
        
        containerView.mask?.frame = bounds
        
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
    
    private var availableAnchors: [AssociatedAnchor] {
        return availableStates.map { AssociatedAnchor(state: $0, anchor: anchor(for: $0)) }
    }
    
    private var currentPositionDependencies: PositionDependencies {
        return PositionDependencies(boundsHeight: bounds.height, headerHeight: headerView.frame.height,
            safeAreaInsets: getSafeAreaInsets())
    }

    private func updateAnchors() {
        shadeView.anchors = availableAnchors.map { $0.anchor }
    }
    
    private func targetAnchorForTop(with positionDependencies: PositionDependencies) -> CGFloat {
        return targetOrigin(for: topPosition, positionDependencies: positionDependencies)
    }
    
    private func targetAnchorForMiddle(with positionDependencies: PositionDependencies) -> CGFloat {
        return targetOrigin(for: middlePosition, positionDependencies: positionDependencies)
    }
    
    private func targetAnchorForBottom(with positionDependencies: PositionDependencies) -> CGFloat {
        return targetOrigin(for: bottomPosition, positionDependencies: positionDependencies)
    }
    
    private func targetAnchorForDismissed(with positionDependencies: PositionDependencies) -> CGFloat {
        return positionDependencies.boundsHeight
    }
    
    private func anchor(for state: State) -> CGFloat {
        return targetAnchor(for: state, positionDependencies: currentPositionDependencies)
    }
    
    private func targetAnchor(for state: State, positionDependencies: PositionDependencies) -> CGFloat {
        switch state {
        case .top:
            return targetAnchorForTop(with: positionDependencies)
        case .middle:
            return targetAnchorForMiddle(with: positionDependencies)
        case .bottom:
            return targetAnchorForBottom(with: positionDependencies)
        case .dismissed:
            return targetAnchorForDismissed(with: positionDependencies)
        }
    }
    
    private func origin(for position: RelativePosition) -> CGFloat {
        return targetOrigin(for: position, positionDependencies: currentPositionDependencies)
    }
    
    private func targetOrigin(for position: RelativePosition, positionDependencies: PositionDependencies) -> CGFloat {
        let candidate = CardView.targetOriginIgnoringContentSize(for: position, positionDependencies: positionDependencies)
        
        if !isConstrainedByContentSize {
            return candidate
        } else {
            let contentOriginPosition: RelativePosition =
                .fromBottom(contentView.contentSize.height, relativeTo: .contentOrigin)

            let contentOrigin = CardView.targetOriginIgnoringContentSize(for: contentOriginPosition,
                positionDependencies: positionDependencies)

            return max(candidate, contentOrigin)
        }
    }
    
    private static func targetOriginIgnoringContentSize(for position: RelativePosition,
        positionDependencies: PositionDependencies) -> CGFloat
    {
        var result: CGFloat = position.offset
    
        switch (position.edge) {
        case .top:
            if !position.ignoresSafeArea {
                result += positionDependencies.safeAreaInsets.top
            }
        case .bottom:
            result = positionDependencies.boundsHeight - result
            
            if !position.ignoresSafeArea {
                result -= positionDependencies.safeAreaInsets.bottom
            }
        }
        
        if position.point == .contentOrigin {
            result -= positionDependencies.headerHeight
        }
        
        return result
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
