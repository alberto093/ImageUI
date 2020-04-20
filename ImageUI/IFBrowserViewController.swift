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

import Nuke

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
    
    private let toolbar: UIToolbar = {
        let toolbar = UIToolbar()
        toolbar.translatesAutoresizingMaskIntoConstraints = false
        return toolbar
    }()
    
    private let collectionContainerView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    // MARK: - Public properties
    public weak var delegate: IFBrowserViewControllerDelegate?
    public var actions: [Action] = []
    
    public override var prefersStatusBarHidden: Bool {
        collectionContainerView.alpha == 0 || collectionContainerView.isHidden
    }
    
    public override var prefersHomeIndicatorAutoHidden: Bool {
        collectionContainerView.alpha == 0 || collectionContainerView.isHidden
    }
    
    // MARK: - Accessory properties
    private let imageManager: IFImageManager
    private var initialTitle: String?
    
    private lazy var tapGesture = UITapGestureRecognizer(target: self, action: #selector(gestureRecognizerDidChange))
    private lazy var doubleTapGesture: UITapGestureRecognizer = {
        let gesture = UITapGestureRecognizer(target: self, action: #selector(gestureRecognizerDidChange))
        gesture.numberOfTapsRequired = 2
        return gesture
    }()
    private lazy var pinchGesture = UIPinchGestureRecognizer(target: self, action: #selector(gestureRecognizerDidChange))
    private lazy var pageViewController = IFPageViewController(imageManager: imageManager)
    private lazy var collectionViewController = IFCollectionViewController(imageManager: imageManager)
    
    private var shouldShowCancelButton: Bool {
        navigationController.map { $0.presentingViewController != nil && $0.viewControllers.first === self } ?? false
    }
    
    private var shouldShowCollectionView: Bool {
        imageManager.images.count > 1
    }
    
    private var isToolbarEnabled: Bool {
        traitCollection.verticalSizeClass != .compact
    }
    
    private var hidingViews: [UIView] {
        (navigationController.map { [$0.navigationBar, $0.toolbar] } ?? []) + [toolbar, collectionContainerView]
    }
    
    private var defaultBackgroundColor: UIColor {
        if #available(iOS 13.0, *) {
            return .systemBackground
        } else {
            return .white
        }
    }
    
    // MARK: - Initializer
    public init(images: [IFImage], initialImageIndex: Int = 0) {
        imageManager = IFImageManager(images: images, initialImageIndex: initialImageIndex)
        super.init(nibName: nil, bundle: nil)
    }
    
    public required init?(coder: NSCoder) {
        imageManager = IFImageManager(images: [])
        super.init(nibName: nil, bundle: nil)
    }
    
    // MARK: - Lifecycle
    public override func loadView() {
        view = UIView()
        view.backgroundColor = defaultBackgroundColor
        
        [pageContainerView, toolbar, collectionContainerView].forEach(view.addSubview)
        
        NSLayoutConstraint.activate([
            pageContainerView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            pageContainerView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            pageContainerView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            pageContainerView.topAnchor.constraint(equalTo: view.topAnchor),
            toolbar.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
            toolbar.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            toolbar.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            collectionContainerView.centerXAnchor.constraint(equalTo: toolbar.centerXAnchor),
            collectionContainerView.centerYAnchor.constraint(equalTo: toolbar.centerYAnchor),
            collectionContainerView.widthAnchor.constraint(equalTo: toolbar.widthAnchor),
            collectionContainerView.heightAnchor.constraint(equalTo: toolbar.heightAnchor)])
    }
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        setup()
        update()
        setupBars()
    }
    
    public override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        setupBars()
    }
    
    // MARK: - Style
    private func setup() {
        if shouldShowCancelButton, navigationItem.leftBarButtonItem == nil {
            navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .cancel, target: self, action: #selector(cancelButtonDidTap))
        }
        initialTitle = title
        
        [tapGesture, doubleTapGesture, pinchGesture].forEach {
            $0.delegate = self
            view.addGestureRecognizer($0)
        }
        navigationController?.toolbar.setShadowImage(UIImage(), forToolbarPosition: .bottom)
        toolbar.barTintColor = navigationController?.toolbar.barTintColor

        addChild(pageViewController)
        pageViewController.progressDelegate = self
        pageContainerView.addSubview(pageViewController.view)
        pageViewController.view.frame = pageContainerView.bounds
        pageViewController.view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        
        addChild(collectionViewController)
        collectionViewController.delegate = self
        collectionContainerView.addSubview(collectionViewController.view)
        collectionViewController.view.frame = collectionContainerView.bounds
        collectionViewController.view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
    }
        
    private func setupBars() {
        let barButtonItems = actions.map { $0.barButtonItem(target: self, action: #selector(actionButtonDidTap)) }
        
        switch traitCollection.verticalSizeClass {
        case .compact:
            navigationItem.setRightBarButtonItems(barButtonItems.reversed(), animated: true)
            setToolbarItems([], animated: true)
        default:
            navigationItem.setRightBarButtonItems([], animated: true)
            let toolbarItems = barButtonItems.isEmpty ? [] : (0..<barButtonItems.count * 2 - 1).map {
                $0.isMultiple(of: 2) ? barButtonItems[$0 / 2] : UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
            }
            setToolbarItems(toolbarItems, animated: true)
        }
        toolbar.invalidateIntrinsicContentSize()
        updateBars(toggle: false)
    }
    
    private func updateBars(toggle: Bool) {
        let isHidden = collectionContainerView.isHidden
        let isToolbarHidden = !isToolbarEnabled || isHidden
        guard toggle else {
            navigationController?.setToolbarHidden(isToolbarHidden, animated: true)
            return
        }
        
        if isHidden {
            navigationController?.setNavigationBarHidden(false, animated: false)
            navigationController?.setToolbarHidden(!isToolbarEnabled, animated: false)
            [toolbar, collectionContainerView].forEach {
                $0.isHidden = false
            }
            hidingViews.forEach { $0.alpha = 0 }
        }

        UIView.animate(
            withDuration: TimeInterval(UINavigationController.hideShowBarDuration),
            animations: { [weak self] in
                self?.view.backgroundColor = isHidden ? self?.defaultBackgroundColor : .black
                self?.hidingViews.forEach { $0.alpha = isHidden ? 1 : 0 }
                self?.setNeedsStatusBarAppearanceUpdate()
                self?.setNeedsUpdateOfHomeIndicatorAutoHidden()
            },
            completion: { [weak self] _ in
                let isToolbarHidden = self?.isToolbarEnabled == false || !isHidden
                self?.navigationController?.setNavigationBarHidden(!isHidden, animated: false)
                self?.navigationController?.setToolbarHidden(isToolbarHidden, animated: false)
                [self?.toolbar, self?.collectionContainerView].forEach {
                    $0?.isHidden = !isHidden
                }
        })
    }
    
    private func update() {
        guard isViewLoaded else { return }
        toolbar.isHidden = !shouldShowCollectionView
        collectionContainerView.isHidden = !shouldShowCollectionView
    }
    
    // MARK: - UI Actions
    @objc private func gestureRecognizerDidChange(_ sender: UIGestureRecognizer) {
        switch sender {
        case tapGesture:
            updateBars(toggle: true)
        case doubleTapGesture where !collectionContainerView.isHidden:
            updateBars(toggle: true)
        case pinchGesture where sender.state == .began && !collectionContainerView.isHidden:
            updateBars(toggle: true)
        default:
            break
        }
    }
    
    @objc private func cancelButtonDidTap() {
        dismiss(animated: true)
    }
    
    @objc private func actionButtonDidTap(_ sender: UIBarButtonItem) {
        guard let actionIndex = toolbarItems?.firstIndex(of: sender), let action = actions[safe: actionIndex] else { return }
        switch action {
        case .share:
            guard let image = imageManager.images[safe: imageManager.dysplaingImageIndex] else { return }
            ImagePipeline.shared.loadImage(with: image.url) { [weak self] result in
                guard case .success(let response) = result else { return }
                let item = IFSharingImage(source: image, image: response.image)
                let viewController = UIActivityViewController(activityItems: [item], applicationActivities: nil)
                self?.present(viewController, animated: true)
            }
        case .delete:
            #warning("Add implementation")
            break
        case .custom(let identifier, _):
            delegate?.browserViewController(self, didSelectActionWith: identifier, forImageAt: imageManager.dysplaingImageIndex)
        }
    }
}

extension IFBrowserViewController: UIGestureRecognizerDelegate {
    public func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        switch (gestureRecognizer, otherGestureRecognizer) {
        case (doubleTapGesture, is UITapGestureRecognizer), (pinchGesture, is UIPinchGestureRecognizer):
            return true
        default:
            return false
        }
    }
    
    
    public func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        guard gestureRecognizer === tapGesture else { return true }
        return collectionContainerView.isHidden || !collectionContainerView.frame.contains(touch.location(in: view))
    }
    
    public func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRequireFailureOf otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        gestureRecognizer === tapGesture && otherGestureRecognizer === doubleTapGesture
    }
}

extension IFBrowserViewController: IFPageViewControllerDelegate {
    func pageViewController(_ pageViewController: IFPageViewController, didScrollFrom startIndex: Int, direction: UIPageViewController.NavigationDirection, progress: CGFloat) {
        let endIndex = direction == .forward ? startIndex + 1 : startIndex - 1
        collectionViewController.scroll(toItemAt: endIndex, progress: progress)
        let imageIndex = min(max(endIndex, 0), imageManager.images.count - 1)
        title = initialTitle ?? imageManager.images[safe: progress >= 0.5 ? imageIndex : startIndex]?.title
    }
}

extension IFBrowserViewController: IFCollectionViewControllerDelegate {
    func collectionViewController(_ collectionViewController: IFCollectionViewController, didSelectItemAt index: Int) {
        pageViewController.updateVisibleImage(index: index)
        title = initialTitle ?? imageManager.images[safe: index]?.title
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
