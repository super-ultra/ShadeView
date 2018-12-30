import UIKit

public protocol ShadeViewContent: class {
    /// View should be immutable
    var view: UIView { get }
    var contentOffset: CGPoint { get set }
    var contentSize: CGSize { get }
    var contentInset: UIEdgeInsets { get }
    func addListener(_ listener: ShadeViewContentListener)
    func removeListener(_ listener: ShadeViewContentListener)
}

public protocol ShadeViewContentListener: class {
    func shadeViewContentDidScroll(_ shadeViewContent: ShadeViewContent)
    
    func shadeViewContentWillBeginDragging(_ shadeViewContent: ShadeViewContent)
    
    func shadeViewContentWillEndDragging(_ shadeViewContent: ShadeViewContent, withVelocity velocity: CGPoint,
        targetContentOffset: UnsafeMutablePointer<CGPoint>)
}
