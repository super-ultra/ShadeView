import UIKit
import ShadeView

final class ShapeViewController: UIViewController {

    private struct Layout {
        static let topInsetPortrait: CGFloat = 36
        static let topInsetLandscape: CGFloat = 20
        static let middleInsetFromBottom: CGFloat = 280
        static let headerHeight: CGFloat = 64
        static let cornerRadius: CGFloat = 16
        static let shadowRadius: CGFloat = 4
        static let shadowOpacity: Float = 0.2
        static let shadowOffset = CGSize.zero
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = UIColor(white: 0.9, alpha: 1.0)
        
        let headerView = ShapeHeaderView()
        headerView.translatesAutoresizingMaskIntoConstraints = false
        headerView.heightAnchor.constraint(equalToConstant: Layout.headerHeight).isActive = true
        
        tableView.backgroundColor = .white
        tableView.dataSource = self
        tableView.register(ShapeCell.self, forCellReuseIdentifier: "\(ShapeCell.self)")
        if #available(iOS 11.0, *) {
            tableView.contentInsetAdjustmentBehavior = .never
        }
        
        cardView = CardView(scrollView: tableView, delegate: self, headerView: headerView)
        cardView.middlePosition = .fromBottom(Layout.middleInsetFromBottom)
        cardView.cornerRadius = Layout.cornerRadius
        cardView.containerView.backgroundColor = .white
        cardView.layer.shadowRadius = Layout.shadowRadius
        cardView.layer.shadowOpacity = Layout.shadowOpacity
        cardView.layer.shadowOffset = Layout.shadowOffset

        view.addSubview(cardView)
        
        setupButtons()
        setupLayout()
        
        cardView.setState(.middle, animated: false)
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        updateLayoutWithCurrentOrientation()
    }
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        
        let prevCardState = cardView.state
        
        updateLayoutWithCurrentOrientation()
        
        coordinator.animate(alongsideTransition: { [weak self] context in
            let newCardState: CardView.State = (prevCardState == .bottom) ? .bottom : .top
            self?.cardView.setState(newCardState, animated: context.isAnimated)
        })
    }
    
    @available(iOS 11.0, *)
    override func viewSafeAreaInsetsDidChange() {
        super.viewSafeAreaInsetsDidChange()
        tableView.contentInset.bottom = view.safeAreaInsets.bottom
    }
    
    // MARK: - Private
    
    private let tableView = UITableView()
    private var cardView: CardView!
    private let cellInfos = ShapeCell.makeDefaultInfos()
    var portraitConstraints: [NSLayoutConstraint] = []
    var landscapeConstraints: [NSLayoutConstraint] = []
    
    private func setupLayout() {
        cardView.translatesAutoresizingMaskIntoConstraints = false
    
        portraitConstraints = [
            cardView.topAnchor.constraint(equalTo: view.topAnchor),
            cardView.leftAnchor.constraint(equalTo: view.leftAnchor),
            cardView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            cardView.rightAnchor.constraint(equalTo: view.rightAnchor)
        ]
        
        let landscapeLeftAnchor: NSLayoutXAxisAnchor
        if #available(iOS 11.0, *) {
            landscapeLeftAnchor = view.safeAreaLayoutGuide.leftAnchor
        } else {
            landscapeLeftAnchor = view.leftAnchor
        }
        
        landscapeConstraints = [
            cardView.topAnchor.constraint(equalTo: view.topAnchor),
            cardView.leftAnchor.constraint(equalTo: landscapeLeftAnchor, constant: 16),
            cardView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            cardView.widthAnchor.constraint(equalToConstant: 320)
        ]
        
        updateLayoutWithCurrentOrientation()
    }
    
    private func updateLayoutWithCurrentOrientation() {
        let orientation = UIDevice.current.orientation
        
        if orientation.isLandscape {
            portraitConstraints.forEach { $0.isActive = false }
            landscapeConstraints.forEach { $0.isActive = true }
            cardView.topPosition = .fromTop(Layout.topInsetLandscape)
            cardView.availableStates = [.top, .bottom]
        } else if orientation.isPortrait {
            landscapeConstraints.forEach { $0.isActive = false }
            portraitConstraints.forEach { $0.isActive = true }
            cardView.topPosition = .fromTop(Layout.topInsetPortrait)
            cardView.availableStates = [.top, .middle, .bottom]
        }
    }

}

extension ShapeViewController: UITableViewDelegate, UITableViewDataSource {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return cellInfos.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "\(ShapeCell.self)", for: indexPath)
        
        if let cell = cell as? ShapeCell {
            cell.update(with: cellInfos[indexPath.row])
        }
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableView.automaticDimension
    }
    
    func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        return ShapeCell.Layout.estimatedHeight
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
}

extension ShapeViewController {

    // MARK: - Buttons
    
    private func setupButtons() {
        func addButton(withTitle title: String, action: Selector, topPosition: CGFloat) {
            let button = UIButton(type: .system)
            view.addSubview(button)
            button.backgroundColor = .darkGray
            button.titleLabel?.font = .boldSystemFont(ofSize: UIFont.systemFontSize)
            button.tintColor = .white
            button.layer.cornerRadius = 8
            button.layer.masksToBounds = true
            
            button.setTitle(title, for: .normal)
            button.addTarget(self, action: action, for: .touchUpInside)
            
            button.translatesAutoresizingMaskIntoConstraints = false
            let rightAnchor: NSLayoutXAxisAnchor
            let topAnchor: NSLayoutYAxisAnchor
            if #available(iOS 11.0, *) {
                rightAnchor = view.safeAreaLayoutGuide.rightAnchor
                topAnchor = view.safeAreaLayoutGuide.topAnchor
            } else {
                rightAnchor = view.rightAnchor
                topAnchor = view.topAnchor
            }
            
            button.rightAnchor.constraint(equalTo: rightAnchor, constant: -8).isActive = true
            button.widthAnchor.constraint(equalToConstant: 128).isActive = true
            button.topAnchor.constraint(equalTo: topAnchor, constant: topPosition).isActive = true
        }
    
        addButton(withTitle: "Hide", action: #selector(handleHideButton), topPosition: 32)
        addButton(withTitle: "Show", action: #selector(handleShowButton), topPosition: 64 + 32)
        addButton(withTitle: "Middle", action: #selector(handleMiddleButton), topPosition: 2 * 64 + 32)
    }
    
    @objc private func handleHideButton() {
        cardView.setState(.bottom, animated: true)
    }
    
    @objc private func handleShowButton() {
        cardView.setState(.top, animated: true)
    }
    
    @objc private func handleMiddleButton() {
        cardView.setState(.middle, animated: true)
    }
    
}
