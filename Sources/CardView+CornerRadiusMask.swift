import UIKit

public extension CardView {

    public var cornerRadius: CGFloat {
        set {
            if newValue > 0 {
                containerView.mask = CornerRadiusMaskView(radius: newValue, maskedView: containerView)
            } else {
                containerView.mask = nil
            }
        }
        get {
            return (containerView.mask as? CornerRadiusMaskView)?.radius ?? 0
        }
    }
    
    // MARK: - Private
    
    private final class CornerRadiusMaskView: UIImageView {
    
        let radius: CGFloat
        
        private var boundsObservation: NSKeyValueObservation? = nil
    
        init(radius: CGFloat, maskedView: UIView) {
            self.radius = radius
            
            super.init(frame: .zero)
            
            frame = maskedView.bounds
            image = UIImage.make(byRoundingCorners: [.topLeft, .topRight], radius: radius)
            boundsObservation = maskedView.observe(\.bounds, options: .new) { [weak self] _, change in
                self?.frame = change.newValue ?? .zero
            }
        }
    
        deinit {
            // https://bugs.swift.org/browse/SR-5816
            boundsObservation = nil
        }
        
        required init?(coder aDecoder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
        
    }

}
