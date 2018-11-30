import UIKit

public extension CardView {
    
    /// It is compatible with
    /// - UIScrollView with UIScrollViewDelegate
    /// - UITableView with UITableViewDelegate
    /// - UICollectionView with UICollectionViewDelegate and UICollectionViewDelegateFlowLayout
    /// Do not use scrollView.delegate. It would be overwritten.
    public convenience init(scrollView: UIScrollView, delegate: UIScrollViewDelegate, headerView: UIView) {
        self.init(content: ScrollShadeViewContent(scrollView: scrollView, delegate: delegate), headerView: headerView)
    }
    
}

public extension ShadeView {
    
    /// It is compatible with
    /// - UIScrollView with UIScrollViewDelegate
    /// - UITableView with UITableViewDelegate
    /// - UICollectionView with UICollectionViewDelegate and UICollectionViewDelegateFlowLayout
    /// Do not use scrollView.delegate. It would be overwritten.
    public convenience init(scrollView: UIScrollView, delegate: UIScrollViewDelegate, headerView: UIView) {
        self.init(content: ScrollShadeViewContent(scrollView: scrollView, delegate: delegate), headerView: headerView)
    }
    
}
