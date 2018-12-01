import UIKit

public extension CardView {
    
    /// It is compatible with any type of UIScrollView and UIScrollViewDelegate:
    /// (e.g. UITableViewDelegate, UICollectionViewDelegateFlowLayout and any other custom type).
    /// Do not overwrite scrollView.delegate, it will be used by ScrollShadeViewContent.
    public convenience init(scrollView: UIScrollView, delegate: UIScrollViewDelegate?, headerView: UIView) {
        self.init(content: ScrollShadeViewContent(scrollView: scrollView, delegate: delegate), headerView: headerView)
    }
    
}

public extension ShadeView {
    
    /// It is compatible with any type of UIScrollView and UIScrollViewDelegate:
    /// (e.g. UITableViewDelegate, UICollectionViewDelegateFlowLayout and any other custom type).
    /// Do not overwrite scrollView.delegate, it will be used by ScrollShadeViewContent.
    public convenience init(scrollView: UIScrollView, delegate: UIScrollViewDelegate?, headerView: UIView) {
        self.init(content: ScrollShadeViewContent(scrollView: scrollView, delegate: delegate), headerView: headerView)
    }
    
}
