//
//  IFBrowserViewController.swift
//
//  Copyright © 2020 ImageUI - Alberto Saltarelli
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.
//

public protocol IFBrowserViewControllerDelegate: class {
    func browserViewController(_ browserViewController: IFBrowserViewController, didSelectActionWith identifier: String, forImageAt index: Int)
}

public class IFBrowserViewController: UIViewController {
    // MARK: - View
    public enum Action: Hashable {
        case share
        case delete
        case custom(identifier: String, image: UIImage)
        
        public func hash(into hasher: inout Hasher) {
            switch self {
            case .share, .delete:
                hasher.combine(String(describing: self))
            case .custom(let identifier, _):
                hasher.combine(identifier)
            }
        }
    }
    
    private let pageContainerView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private let collectionContainerView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private var collectionContainerViewHeightConstraint: NSLayoutConstraint?
    
    // MARK: - Public properties
    public weak var delegate: IFBrowserViewControllerDelegate?
    public var actions: [Action] = [] {
        didSet { barButtonItems = actions.map { $0.barButtonItem(target: self, action: #selector(actionButtonDidTap)) } }
    }
    
    // MARK: - Accessory properties
    private let imageManager: IFImageManager
    
    private lazy var pageViewController = IFPageViewController(imageManager: imageManager)
    private lazy var collectionViewController = IFCollectionViewController(imageManager: imageManager)
    private var barButtonItems: [UIBarButtonItem] = []
    
    private var shouldShowCancelButton: Bool {
        navigationController.map { $0.presentingViewController != nil && $0.viewControllers.first === self } ?? false
    }
    
    private var shouldShowCollectionView: Bool {
        imageManager.imageURLs.count > 1
    }
    
    // MARK: - Initializer
    public init(imageURLs: [URL], initialImageIndex: Int = 0) {
        imageManager = IFImageManager(imageURLs: imageURLs, initialImageIndex: initialImageIndex)
        super.init(nibName: nil, bundle: nil)
    }
    
    public required init?(coder: NSCoder) {
        imageManager = IFImageManager(imageURLs: [])
        super.init(nibName: nil, bundle: nil)
    }
    
    // MARK: - Lifecycle
    public override func loadView() {
        view = UIView()
        if #available(iOS 13.0, *) {
            view.backgroundColor = .systemBackground
        } else {
            view.backgroundColor = .white
        }
        
        [pageContainerView, collectionContainerView].forEach(view.addSubview)
        collectionContainerViewHeightConstraint = collectionContainerView.heightAnchor.constraint(equalToConstant: 0)
        NSLayoutConstraint.activate([
            pageContainerView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            pageContainerView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            pageContainerView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            pageContainerView.topAnchor.constraint(equalTo: view.topAnchor),
            collectionContainerView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            collectionContainerView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
            collectionContainerView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            collectionContainerViewHeightConstraint!])
    }
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        setup()
        update()
        updateToolbars()
    }
    
    public override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        updateToolbars()
    }
    
    public override func preferredContentSizeDidChange(forChildContentContainer container: UIContentContainer) {
        guard container === collectionViewController else { return }
        collectionContainerViewHeightConstraint?.constant = container.preferredContentSize.height
    }
    
    // MARK: - Style
    private func setup() {
        if shouldShowCancelButton, navigationItem.leftBarButtonItem == nil {
            navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .cancel, target: self, action: #selector(cancelButtonDidTap))
        }
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(viewDidTap))
        tapGesture.delegate = self
        view.addGestureRecognizer(tapGesture)
        navigationController?.toolbar.setShadowImage(UIImage(), forToolbarPosition: .bottom)

        addChild(pageViewController)
        pageViewController.progressDelegate = collectionViewController
        pageContainerView.addSubview(pageViewController.view)
        pageViewController.view.frame = pageContainerView.bounds
        pageViewController.view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        
        addChild(collectionViewController)
        collectionViewController.delegate = pageViewController
        collectionContainerView.addSubview(collectionViewController.view)
        collectionViewController.view.frame = collectionContainerView.bounds
        collectionViewController.view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
    }
        
    private func updateToolbars() {
        navigationItem.rightBarButtonItems = traitCollection.verticalSizeClass == .compact ? barButtonItems.reversed() : []
        
        if traitCollection.verticalSizeClass == .regular {
            toolbarItems = barButtonItems.isEmpty ? [] : (0..<barButtonItems.count * 2 - 1).map {
                $0.isMultiple(of: 2) ? barButtonItems[$0 / 2] : UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
            }
        } else {
            toolbarItems = []
        }
        
        navigationController?.isToolbarHidden = traitCollection.verticalSizeClass == .compact
    }
    
    private func update() {
        guard isViewLoaded else { return }
        collectionContainerView.isHidden = !shouldShowCollectionView
    }
    
    // MARK: - UI Actions
    @objc private func viewDidTap() {

    }
    
    @objc private func cancelButtonDidTap() {
        dismiss(animated: true)
    }
    
    @objc private func actionButtonDidTap(_ sender: UIBarButtonItem) {
        guard let actionIndex = toolbarItems?.firstIndex(of: sender), let action = actions[safe: actionIndex] else { return }
        switch action {
        case .share:
            #warning("Add implementation")
            let viewController = UIActivityViewController(activityItems: [], applicationActivities: nil)
            present(viewController, animated: true)
        case .delete:
            #warning("Add implementation")
            break
        case .custom(let identifier, _):
            delegate?.browserViewController(self, didSelectActionWith: identifier, forImageAt: imageManager.dysplaingImageIndex)
        }
    }
}

extension IFBrowserViewController: UIGestureRecognizerDelegate {
    public func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        !collectionContainerView.frame.contains(touch.location(in: view))
    }
}

extension IFBrowserViewController.Action {
    func barButtonItem(target: Any?, action: Selector?) -> UIBarButtonItem {
        switch self {
        case .share:
            return UIBarButtonItem(barButtonSystemItem: .action, target: target, action: action)
        case .delete:
            return UIBarButtonItem(barButtonSystemItem: .trash, target: target, action: action)
        case .custom(_, let image):
            return UIBarButtonItem(image: image, style: .plain, target: target, action: action)
        }
    }
}
