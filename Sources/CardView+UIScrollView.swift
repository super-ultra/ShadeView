import UIKit

public extension CardView {
    
    /// It is compatible with
    /// - UIScrollView and UIScrollViewDelegate
    /// - UITableView and UITableViewDelegate
    /// - UICollectionView and UICollectionViewDelegate
    /// Do not use scrollView.delegate. It would be overwritten.
    public convenience init(scrollView: UIScrollView, delegate: UIScrollViewDelegate, headerView: UIView) {
        self.init(content: ScrollShadeViewContent(scrollView: scrollView, delegate: delegate), headerView: headerView)
    }
    
}

public extension ShadeView {
    
    /// It is compatible with
    /// - UIScrollView and UIScrollViewDelegate
    /// - UITableView and UITableViewDelegate
    /// - UICollectionView and UICollectionViewDelegate
    /// Do not use scrollView.delegate. It would be overwritten.
    public convenience init(scrollView: UIScrollView, delegate: UIScrollViewDelegate, headerView: UIView) {
        self.init(content: ScrollShadeViewContent(scrollView: scrollView, delegate: delegate), headerView: headerView)
    }
    
}
