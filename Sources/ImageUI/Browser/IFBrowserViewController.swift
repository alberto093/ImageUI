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

import UIKit

public protocol IFBrowserViewControllerDelegate: class {
    func browserViewController(_ browserViewController: IFBrowserViewController, didSelectActionWith identifier: String, forImageAt index: Int)
    func browserViewController(_ browserViewController: IFBrowserViewController, willDisplayImageAt index: Int)
}

public extension IFBrowserViewControllerDelegate {
    func browserViewController(_ browserViewController: IFBrowserViewController, didSelectActionWith identifier: String, forImageAt index: Int) { }
    func browserViewController(_ browserViewController: IFBrowserViewController, willDisplayImageAt index: Int) { }
}

open class IFBrowserViewController: UIViewController {
    private struct Constants {
        static let toolbarContentInset = UIEdgeInsets(top: -1, left: 0, bottom: 0, right: 0)
    }
    
    // MARK: - View
    private let pageContainerView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private let collectionToolbar: UIToolbar = {
        let toolbar = UIToolbar()
        toolbar.translatesAutoresizingMaskIntoConstraints = false
        return toolbar
    }()

    private let toolbarMaskLayer: CALayer = {
        let layer = CALayer()
        layer.backgroundColor = UIColor.black.cgColor
        return layer
    }()
    
    private let collectionContainerView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    // MARK: - Public properties
    public weak var delegate: IFBrowserViewControllerDelegate?
    public var configuration = Configuration() {
        didSet {
            imageManager.prefersAspectFillZoom = configuration.prefersAspectFillZoom
            setupBars()
            updateBars(toggle: false)
        }
    }

    open override var prefersStatusBarHidden: Bool {
        isFullScreenMode
    }
    
    open override var prefersHomeIndicatorAutoHidden: Bool {
        isFullScreenMode
    }
    
    // MARK: - Accessory properties
    private let imageManager: IFImageManager
    private var shouldUpdateTitle = true
    
    private lazy var tapGesture = UITapGestureRecognizer(target: self, action: #selector(gestureRecognizerDidChange))
    private lazy var doubleTapGesture: UITapGestureRecognizer = {
        let gesture = UITapGestureRecognizer(target: self, action: #selector(gestureRecognizerDidChange))
        gesture.numberOfTapsRequired = 2
        return gesture
    }()
    private lazy var pinchGesture = UIPinchGestureRecognizer(target: self, action: #selector(gestureRecognizerDidChange))
    private lazy var pageViewController = IFPageViewController(imageManager: imageManager)
    private lazy var collectionViewController = IFCollectionViewController(imageManager: imageManager)
    
    private var shouldResetBarStatus = false
    private var isFullScreenMode = false
    
    private var shouldShowCancelButton: Bool {
        navigationController.map { $0.presentingViewController != nil && $0.viewControllers.first === self } ?? false
    }
    
    private var isCollectionViewEnabled: Bool {
        imageManager.images.count > 1
    }
    
    private var isNavigationBarEnabled: Bool {
        configuration.alwaysShowNavigationBar || !configuration.isNavigationBarHidden
    }
    
    private var isToolbarEnabled: Bool {
        switch (traitCollection.verticalSizeClass, traitCollection.horizontalSizeClass) {
        case (.regular, let horizontalClass) where horizontalClass != .regular:
            return configuration.alwaysShowToolbar || !configuration.actions.isEmpty
        default:
            return false
        }
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
        
        [pageContainerView, collectionToolbar, collectionContainerView].forEach(view.addSubview)
        
        NSLayoutConstraint.activate([
            pageContainerView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            pageContainerView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            pageContainerView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            pageContainerView.topAnchor.constraint(equalTo: view.topAnchor),
            collectionToolbar.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
            collectionToolbar.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            collectionToolbar.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            collectionContainerView.centerXAnchor.constraint(equalTo: collectionToolbar.centerXAnchor),
            collectionContainerView.centerYAnchor.constraint(equalTo: collectionToolbar.centerYAnchor),
            collectionContainerView.widthAnchor.constraint(equalTo: collectionToolbar.widthAnchor),
            collectionContainerView.heightAnchor.constraint(equalTo: collectionToolbar.heightAnchor)])
    }
    
    open override func viewDidLoad() {
        super.viewDidLoad()
        setup()
        updateTitleIfNeeded()
        setupBars()
    }
    
    open override func willMove(toParent parent: UIViewController?) {
        super.willMove(toParent: parent)
        shouldResetBarStatus = true
    }
    
    open override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if shouldResetBarStatus {
            shouldResetBarStatus = false
            var configuration = self.configuration
            configuration.isNavigationBarHidden = navigationController?.isNavigationBarHidden == true
            configuration.isToolbarHidden = navigationController?.isToolbarHidden == true
            self.configuration = configuration
        }
    }
    
    open override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        if shouldResetBarStatus {
            shouldResetBarStatus = false
            navigationController?.isNavigationBarHidden = configuration.isNavigationBarHidden
            navigationController?.isToolbarHidden = configuration.isToolbarHidden
        }
    }
        
    open override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        if traitCollection.verticalSizeClass != previousTraitCollection?.verticalSizeClass {
            setupBars()
            updateBars(toggle: false)
        }
    }
    
    // MARK: - Style
    private func setup() {
        if shouldShowCancelButton, navigationItem.leftBarButtonItem == nil {
            navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .cancel, target: self, action: #selector(cancelButtonDidTap))
        }
        
        shouldUpdateTitle = title == nil && navigationItem.title == nil && navigationItem.titleView == nil
        
        [tapGesture, doubleTapGesture, pinchGesture].forEach {
            $0.delegate = self
            view.addGestureRecognizer($0)
        }

        if let customShadow = navigationController?.toolbar.shadowImage(forToolbarPosition: .bottom) {
            collectionToolbar.setShadowImage(customShadow, forToolbarPosition: .bottom)
        }
        navigationController?.toolbar.setShadowImage(UIImage(), forToolbarPosition: .bottom)
        collectionToolbar.barTintColor = navigationController?.toolbar.barTintColor

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
        guard isViewLoaded else { return }
        
        let barButtonItems = configuration.actions.map { $0.barButtonItem(target: self, action: #selector(actionButtonDidTap)) }
        
        if isToolbarEnabled {
            navigationItem.setRightBarButtonItems([], animated: true)
            let toolbarItems = barButtonItems.isEmpty ? [] : (0..<barButtonItems.count * 2 - 1).map {
                $0.isMultiple(of: 2) ? barButtonItems[$0 / 2] : UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
            }
            setToolbarItems(toolbarItems, animated: true)
        } else {
            navigationItem.setRightBarButtonItems(barButtonItems.reversed(), animated: true)
            setToolbarItems([], animated: true)
        }
        
        collectionToolbar.invalidateIntrinsicContentSize()
    }
    
    private func updateBars(toggle: Bool) {
        guard isViewLoaded else { return }
        guard !toggle else {
            animateBarsToggling()
            return
        }
        
        let shouldHideToolbar = !isToolbarEnabled || isFullScreenMode
        navigationController?.setToolbarHidden(shouldHideToolbar, animated: false)
        
        if !isCollectionViewEnabled, !collectionContainerView.isHidden {
            updateToolbarMask()
            UIView.animate(
                withDuration: TimeInterval(UINavigationController.hideShowBarDuration),
                animations: { [weak self] in [self?.collectionToolbar, self?.collectionContainerView].forEach { $0?.alpha = 0 } },
                completion: { [weak self] _ in
                    [self?.collectionToolbar, self?.collectionContainerView].forEach { $0?.isHidden = true }
                    self?.collectionToolbar.layer.mask = nil
            })
        }
    }
    
    private func animateBarsToggling() {
        let isToolbarHidden = navigationController?.isToolbarHidden == true
        let isCollectionViewHidden = collectionContainerView.isHidden

        if isNavigationBarEnabled, isFullScreenMode {
            navigationController?.setNavigationBarHidden(false, animated: false)
            navigationController?.navigationBar.alpha = 0
        }
        
        if isToolbarEnabled, isToolbarHidden {
            navigationController?.isToolbarHidden = false
        }
        
        if isCollectionViewEnabled, isCollectionViewHidden {
            [collectionToolbar, collectionContainerView].forEach {
                $0.isHidden = false
                $0.alpha = 0
            }
        }
        
        updateToolbarMask()
        isFullScreenMode.toggle()
        
        DispatchQueue.main.async {
            if self.isToolbarEnabled, isToolbarHidden {
                self.navigationController?.toolbar.alpha = 0
            }
            
            UIView.animate(
            withDuration: TimeInterval(UINavigationController.hideShowBarDuration),
            animations: {
                self.view.backgroundColor = self.isFullScreenMode ? .black : self.defaultBackgroundColor
                self.navigationController?.navigationBar.alpha = self.isFullScreenMode && self.isNavigationBarEnabled ? 0 : 1
                if self.isToolbarEnabled {
                    self.navigationController?.toolbar.alpha = isToolbarHidden ? 1 : 0
                }
                
                if self.isCollectionViewEnabled {
                    [self.collectionToolbar, self.collectionContainerView].forEach { $0.alpha = isCollectionViewHidden ? 1 : 0 }
                }
                
                self.setNeedsStatusBarAppearanceUpdate()
                self.setNeedsUpdateOfHomeIndicatorAutoHidden()
            }, completion: { _ in
                if self.isFullScreenMode && self.isNavigationBarEnabled {
                    self.navigationController?.setNavigationBarHidden(true, animated: true)
                    self.navigationController?.navigationBar.alpha = 0
                }
                
                if self.isToolbarEnabled, !isToolbarHidden {
                    self.navigationController?.isToolbarHidden = true
                }
                
                if self.isCollectionViewEnabled {
                    [self.collectionToolbar, self.collectionContainerView].forEach { $0.isHidden = !isCollectionViewHidden }
                    self.collectionToolbar.layer.mask = nil
                }
            })
        }
    }
    
    private func updateTitleIfNeeded(imageIndex: Int? = nil) {
        guard shouldUpdateTitle else { return }
        title = imageManager.images[safe: imageIndex ?? imageManager.displayingImageIndex]?.title
    }
    
    private func updateToolbarMask() {
        toolbarMaskLayer.frame = CGRect(
            x: Constants.toolbarContentInset.left,
            y: Constants.toolbarContentInset.top,
            width: collectionToolbar.frame.width - (Constants.toolbarContentInset.left + Constants.toolbarContentInset.right),
            height: collectionToolbar.frame.height - (Constants.toolbarContentInset.top + Constants.toolbarContentInset.bottom))
        collectionToolbar.layer.mask = navigationController?.isToolbarHidden == true ? nil : toolbarMaskLayer
    }
    
    private func presentShareViewController(sender: UIBarButtonItem) {
        imageManager.sharingImage(forImageAt: imageManager.displayingImageIndex) { [weak self] result in
            guard case .success(let sharingImage) = result else { return }
            let viewController = UIActivityViewController(activityItems: [sharingImage], applicationActivities: nil)
            viewController.modalPresentationStyle = .popover
            viewController.popoverPresentationController?.barButtonItem = sender
            self?.present(viewController, animated: true)
        }
    }
    
    // MARK: - UI Actions
    @objc private func gestureRecognizerDidChange(_ sender: UIGestureRecognizer) {
        switch sender {
        case tapGesture,
             doubleTapGesture where !isFullScreenMode,
             pinchGesture where sender.state == .began && !isFullScreenMode:
            
            updateBars(toggle: true)
        default:
            break
        }
    }
    
    @objc private func cancelButtonDidTap() {
        dismiss(animated: true)
    }
    
    @objc private func actionButtonDidTap(_ sender: UIBarButtonItem) {
        let senderIndex: Int?
        if navigationController?.isToolbarHidden == true {
            senderIndex = navigationItem.rightBarButtonItems?.reversed().firstIndex(of: sender)
        } else {
            senderIndex = toolbarItems?.firstIndex(of: sender)
        }
        
        guard let actionIndex = senderIndex, let action = configuration.actions[safe: actionIndex] else { return }
        collectionViewController.scroll(toItemAt: imageManager.displayingImageIndex)
        pageViewController.invalidateDataSourceIfNeeded()
        
        switch action {
        case .share:
            presentShareViewController(sender: sender)
        case .delete:
            break
        case .custom(let identifier, _):
            delegate?.browserViewController(self, didSelectActionWith: identifier, forImageAt: imageManager.displayingImageIndex)
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
        collectionContainerView.isHidden || !collectionContainerView.frame.contains(touch.location(in: view))
    }
    
    public func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRequireFailureOf otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        gestureRecognizer === tapGesture && otherGestureRecognizer === doubleTapGesture
    }
}

extension IFBrowserViewController: IFPageViewControllerDelegate {
    func pageViewController(_ pageViewController: IFPageViewController, didScrollFrom startIndex: Int, direction: UIPageViewController.NavigationDirection, progress: CGFloat) {
        let endIndex = direction == .forward ? startIndex + 1 : startIndex - 1
        collectionViewController.scroll(toItemAt: endIndex, progress: progress)
    }
    
    func pageViewController(_ pageViewController: IFPageViewController, didUpdatePage index: Int) {
        updateTitleIfNeeded(imageIndex: index)
        delegate?.browserViewController(self, willDisplayImageAt: index)
    }
    
    func pageViewControllerDidResetScroll(_ pageViewController: IFPageViewController) {
        collectionViewController.scroll(toItemAt: imageManager.displayingImageIndex, animated: true)
        updateTitleIfNeeded(imageIndex: imageManager.displayingImageIndex)
        delegate?.browserViewController(self, willDisplayImageAt: imageManager.displayingImageIndex)
    }
}

extension IFBrowserViewController: IFCollectionViewControllerDelegate {
    func collectionViewController(_ collectionViewController: IFCollectionViewController, didSelectItemAt index: Int) {
        pageViewController.updateVisibleImage(index: index)
        updateTitleIfNeeded(imageIndex: index)
        delegate?.browserViewController(self, willDisplayImageAt: index)
    }
    
    func collectionViewControllerWillBeginScrolling(_ collectionViewController: IFCollectionViewController) {
        pageViewController.invalidateDataSourceIfNeeded()
    }
}

private extension IFBrowserViewController.Action {
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
