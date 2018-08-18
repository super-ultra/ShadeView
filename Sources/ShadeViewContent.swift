import UIKit

public protocol ShadeViewContent: class {
    var contentOffset: CGPoint { get set }
    var contentSize: CGSize { get }
    var contentInset: UIEdgeInsets { get }
    var isScrollEnabled: Bool { get set }
    func addListener(_ listener: ShadeViewContentListener)
    func removeListener(_ listener: ShadeViewContentListener)
}

public protocol ShadeViewContentListener: class {
    func shadeViewContent(_ shadeViewContent: ShadeViewContent, didChangeContentOffset contentOffset: CGPoint)
    func shadeViewContent(_ shadeViewContent: ShadeViewContent, didChangeContentSize contentSize: CGSize)
    func shadeViewContent(_ shadeViewContent: ShadeViewContent, didChangeContentInset contentInset: UIEdgeInsets)
}
