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
import Combine
import AVFoundation

#warning("Disable sound buttons (enabledSound and disabledSound) if video doesn't contains audio track")

public protocol IFBrowserViewControllerDelegate: AnyObject {
    func browserViewController(_ browserViewController: IFBrowserViewController, didSelectActionWith identifier: String, forImageAt index: Int)
    func browserViewController(_ browserViewController: IFBrowserViewController, willDeleteItemAt index: Int, completion: @escaping (Bool) -> Void)
    func browserViewController(_ browserViewController: IFBrowserViewController, didDeleteItemAt index: Int, isEmpty: Bool)
    func browserViewController(_ browserViewController: IFBrowserViewController, willDisplayImageAt index: Int)
}

public extension IFBrowserViewControllerDelegate {
    func browserViewController(_ browserViewController: IFBrowserViewController, didSelectActionWith identifier: String, forImageAt index: Int) { }
    func browserViewController(_ browserViewController: IFBrowserViewController, willDeleteItemAt index: Int, completion: @escaping (Bool) -> Void) {
        completion(true)
    }
    func browserViewController(_ browserViewController: IFBrowserViewController, didDeleteItemAt index: Int, isEmpty: Bool) { }
    func browserViewController(_ browserViewController: IFBrowserViewController, willDisplayImageAt index: Int) { }
}

open class IFBrowserViewController: UIViewController {
    private struct Constants {
        static let toolbarContentInset = UIEdgeInsets(top: -1, left: 0, bottom: 0, right: 0)
        static let soundButtonToolbarWidth: CGFloat = 40
        static let soundButtonNavigationBarWidth: CGFloat = 52
        static let playPauseButtonToolbarWidth: CGFloat = 30
        static let playPauseButtonNavigationWidth: CGFloat = 42
        static let videoPlaybackLabelBottomPadding: CGFloat = 6
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
    
    private lazy var playButton = UIBarButtonItem(image: UIImage(systemName: "play.fill"), style: .plain, target: self, action: #selector(playButtonDidTap))
    private lazy var pauseButton = UIBarButtonItem(image: UIImage(systemName: "pause.fill"), style: .plain, target: self, action: #selector(pauseButtonDidTap))
    private lazy var disabledSoundButton = UIBarButtonItem(image: UIImage(systemName: "speaker.slash.fill"), style: .plain, target: self, action: #selector(disabledSoundButtonDidTap))
    private lazy var enabledSoundButton = UIBarButtonItem(image: UIImage(systemName: "speaker.wave.2.fill"), style: .plain, target: self, action: #selector(enabledSoundButtonDidTap))
    
    // MARK: - Public properties
    public weak var delegate: IFBrowserViewControllerDelegate?
    public var configuration = Configuration() {
        didSet {
            mediaManager.prefersAspectFillZoom = configuration.prefersAspectFillZoom
            setupBars(mediaIndex: mediaManager.displayingMediaIndex)
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
    private let mediaManager: IFMediaManager
    private var shouldUpdateTitle = true
    
    private lazy var tapGesture = UITapGestureRecognizer(target: self, action: #selector(gestureRecognizerDidChange))
    private lazy var doubleTapGesture: UITapGestureRecognizer = {
        let gesture = UITapGestureRecognizer(target: self, action: #selector(gestureRecognizerDidChange))
        gesture.numberOfTapsRequired = 2
        return gesture
    }()
    private lazy var pinchGesture = UIPinchGestureRecognizer(target: self, action: #selector(gestureRecognizerDidChange))
    private lazy var pageViewController = IFPageViewController(mediaManager: mediaManager)
    private lazy var collectionViewController = IFCollectionViewController(mediaManager: mediaManager)
    
    private var shouldResetBarStatus = false
    private var isFullScreenMode = false
    
    private var soundVolumeObservation: NSKeyValueObservation?
    private var bag: Set<AnyCancellable> = []
    
    private var shouldShowCancelButton: Bool {
        navigationController.map { $0.presentingViewController != nil && $0.viewControllers.first === self } ?? false
    }
    
    private var isCollectionViewEnabled: Bool {
        mediaManager.media.count > 1
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
    
    // MARK: - Initializer
    public init(media: [IFMedia], initialIndex: Int = 0) {
        mediaManager = IFMediaManager(media: media, initialIndex: initialIndex)
        super.init(nibName: nil, bundle: nil)
    }
    
    public required init?(coder: NSCoder) {
        mediaManager = IFMediaManager(media: [])
        super.init(coder: coder)
    }
    
    // MARK: - Lifecycle
    public override func loadView() {
        view = UIView()
        view.backgroundColor = .systemBackground
        
        [pageContainerView, collectionToolbar, collectionContainerView, mediaManager.videoPlaybackLabel].forEach(view.addSubview)
        
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
        updateTitleIfNeeded(imageIndex: mediaManager.displayingMediaIndex)
        setupBars(mediaIndex: mediaManager.displayingMediaIndex)
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
            setupBars(mediaIndex: mediaManager.displayingMediaIndex)
            collectionToolbar.invalidateIntrinsicContentSize()
            updateBars(toggle: false)
        }
    }
    
    open override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        let videoPlaybackLabelOrigin = CGPoint(
            x: view.frame.midX - mediaManager.videoPlaybackLabel.frame.width / 2,
            y: collectionContainerView.frame.minY - Constants.videoPlaybackLabelBottomPadding - mediaManager.videoPlaybackLabel.frame.height)
        
        mediaManager.videoPlaybackLabel.defaultOrigin = videoPlaybackLabelOrigin
        mediaManager.videoPlaybackLabel.frame.origin = videoPlaybackLabelOrigin
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
                
        let audioSession = AVAudioSession.sharedInstance()
        try? audioSession.setCategory(.playback)
        try? audioSession.setActive(true)
    
        soundVolumeObservation = audioSession.observe(\.outputVolume, options: [.old, .new]) { [weak self] _, changes in
            guard let self, let newValue = changes.newValue, let oldValue = changes.oldValue else { return }
                
            switch self.mediaManager.soundStatus.value {
            case .disabled:
                self.mediaManager.soundStatus.value.toggle()
            case .enabled:
                break
            case .muted:
                if newValue >= oldValue {
                    self.mediaManager.soundStatus.value.toggle()
                }
            }
        }
        
        mediaManager.videoStatus
            .combineLatest(mediaManager.soundStatus)
            .dropFirst()
            .removeDuplicates { ($0.0, $0.1) == ($1.0, $1.1) }
            .sink { [weak self] _ in
                guard let self else { return }
                self.setupBars(mediaIndex: self.mediaManager.displayingMediaIndex, animated: false)
            }
            .store(in: &bag)
    }
        
    private func setupBars(mediaIndex: Int, animated: Bool = true) {
        guard isViewLoaded else { return }
        
        var barButtonItems = configuration.actions.map { $0.barButtonItem(target: self, action: #selector(actionButtonDidTap)) }
        
        if mediaManager.media[mediaIndex].mediaType.isVideo {
            barButtonItems.insert(mediaManager.soundStatus.value.isEnabled ? enabledSoundButton : disabledSoundButton, at: barButtonItems.count / 2)
            
            switch mediaManager.videoStatus.value {
            case .autoplay, .play:
                barButtonItems.insert(pauseButton, at: barButtonItems.count / 2)
            case .autoplayPause, .autoplayEnded, .pause:
                barButtonItems.insert(playButton, at: barButtonItems.count / 2)
            }
        }
        
        if isToolbarEnabled {
            enabledSoundButton.width = Constants.soundButtonToolbarWidth
            disabledSoundButton.width = Constants.soundButtonToolbarWidth
            playButton.width = Constants.playPauseButtonToolbarWidth
            pauseButton.width = Constants.playPauseButtonToolbarWidth
            
            navigationItem.setRightBarButtonItems([], animated: animated)
            
            let toolbarItems: [UIBarButtonItem]
            
            switch barButtonItems.count {
            case 0:
                toolbarItems = []
            case 1:
                toolbarItems = [
                    UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil),
                    barButtonItems[0],
                    UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
                ]
            default:
                toolbarItems = barButtonItems.isEmpty ? [] : (0..<barButtonItems.count * 2 - 1).map {
                    $0.isMultiple(of: 2) ? barButtonItems[$0 / 2] : UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
                }
            }

            setToolbarItems(toolbarItems, animated: animated)
        } else {
            enabledSoundButton.width = Constants.soundButtonNavigationBarWidth
            disabledSoundButton.width = Constants.soundButtonNavigationBarWidth
            playButton.width = Constants.playPauseButtonNavigationWidth
            pauseButton.width = Constants.playPauseButtonNavigationWidth
            
            navigationItem.setRightBarButtonItems(barButtonItems.reversed(), animated: animated)
            setToolbarItems([], animated: animated)
        }
    }
    
    private func updateBars(toggle: Bool) {
        guard isViewLoaded else { return }
        
        if toggle {
            animateBarsToggling()
        } else {
            let shouldHideToolbar = !isToolbarEnabled || isFullScreenMode
            navigationController?.setToolbarHidden(shouldHideToolbar, animated: false)
            
            if !isCollectionViewEnabled, !collectionContainerView.isHidden {
                updateToolbarMask()
                UIView.animate(
                    withDuration: TimeInterval(UINavigationController.hideShowBarDuration),
                    animations: { [weak self] in [self?.collectionToolbar, self?.collectionContainerView, self?.mediaManager.videoPlaybackLabel].forEach { $0?.alpha = 0 } },
                    completion: { [weak self] _ in
                        [self?.collectionToolbar, self?.collectionContainerView, self?.mediaManager.videoPlaybackLabel].forEach { $0?.isHidden = true }
                        self?.collectionToolbar.layer.mask = nil
                })
            }
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
            mediaManager.videoPlaybackLabel.alpha = 1
            navigationController?.isToolbarHidden = false
        }
        
        if isCollectionViewEnabled, isCollectionViewHidden {
            [collectionToolbar, collectionContainerView, mediaManager.videoPlaybackLabel].forEach {
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
                self.view.backgroundColor = self.isFullScreenMode ? .black : .systemBackground
                self.navigationController?.navigationBar.alpha = self.isFullScreenMode && self.isNavigationBarEnabled ? 0 : 1
                if self.isToolbarEnabled {
                    self.navigationController?.toolbar.alpha = isToolbarHidden ? 1 : 0
                }
                
                if self.isCollectionViewEnabled {
                    [self.collectionToolbar, self.collectionContainerView, self.mediaManager.videoPlaybackLabel].forEach { $0.alpha = isCollectionViewHidden ? 1 : 0 }
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
                    [self.collectionToolbar, self.collectionContainerView, self.mediaManager.videoPlaybackLabel].forEach { $0.isHidden = !isCollectionViewHidden }
                    self.collectionToolbar.layer.mask = nil
                }
            })
        }
    }
    
    private func updateTitleIfNeeded(imageIndex: Int) {
        guard shouldUpdateTitle else { return }
        title = mediaManager.media[safe: imageIndex]?.title
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
        mediaManager.sharingMedia(at: mediaManager.displayingMediaIndex) { [weak self] result in
            guard case .success(let sharingImage) = result else { return }
            let viewController = UIActivityViewController(activityItems: [sharingImage], applicationActivities: nil)
            viewController.modalPresentationStyle = .popover
            viewController.popoverPresentationController?.barButtonItem = sender
            self?.present(viewController, animated: true)
        }
    }
    
    private func handleRemove() {
        let removingIndex = mediaManager.displayingMediaIndex
        mediaManager.removeDisplayingMedia()
        
        let group = DispatchGroup()
        group.enter()
        pageViewController.removeDisplayingMedia { group.leave() }
        group.enter()
        collectionViewController.removeDisplayingMedia { group.leave() }
        
        let view = navigationController?.view ?? self.view
        view?.isUserInteractionEnabled = false
        group.notify(queue: .main) { [weak self, weak view] in
            view?.isUserInteractionEnabled = true
            if let self = self {
                self.delegate?.browserViewController(self, didDeleteItemAt: removingIndex, isEmpty: self.mediaManager.media.isEmpty)
            }
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
            senderIndex = toolbarItems?.firstIndex(of: sender).map { $0 / 2 }
        }
        
        guard let actionIndex = senderIndex, let action = configuration.actions[safe: actionIndex] else { return }
        collectionViewController.scrollToDisplayingMediaIndex()
        pageViewController.invalidateDataSourceIfNeeded()
        
        switch action {
        case .share:
            presentShareViewController(sender: sender)
        case .delete:
            if let delegate = delegate {
                delegate.browserViewController(self, willDeleteItemAt: mediaManager.displayingMediaIndex) { [weak self]  shouldRemove in
                    guard shouldRemove else { return }
                    self?.handleRemove()
                }
            } else {
                handleRemove()
            }
        case .custom(let identifier, _, _):
            delegate?.browserViewController(self, didSelectActionWith: identifier, forImageAt: mediaManager.displayingMediaIndex)
        }
    }
    
    @objc private func playButtonDidTap() {
        mediaManager.videoStatus.value.toggle()
    }
    
    @objc private func pauseButtonDidTap() {
        mediaManager.videoStatus.value.toggle()
    }
    
    @objc private func disabledSoundButtonDidTap() {
        mediaManager.soundStatus.value.toggle()
    }
    
    @objc private func enabledSoundButtonDidTap() {
        mediaManager.soundStatus.value.toggle()
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
        collectionViewController.scroll(from: startIndex, to: endIndex, progress: progress)
    }
    
    func pageViewController(_ pageViewController: IFPageViewController, didUpdatePage index: Int) {
        updateTitleIfNeeded(imageIndex: index)
        setupBars(mediaIndex: index, animated: false)
        delegate?.browserViewController(self, willDisplayImageAt: index)
    }
    
    func pageViewControllerDidResetScroll(_ pageViewController: IFPageViewController) {
        collectionViewController.scrollToDisplayingMediaIndex()
        updateTitleIfNeeded(imageIndex: mediaManager.displayingMediaIndex)
        setupBars(mediaIndex: mediaManager.displayingMediaIndex, animated: false)
        delegate?.browserViewController(self, willDisplayImageAt: mediaManager.displayingMediaIndex)
    }
}

extension IFBrowserViewController: IFCollectionViewControllerDelegate {
    func collectionViewController(_ collectionViewController: IFCollectionViewController, didSelectItemAt index: Int) {
        pageViewController.updateVisibleImage(index: index)
        updateTitleIfNeeded(imageIndex: index)
        setupBars(mediaIndex: index, animated: false)
        delegate?.browserViewController(self, willDisplayImageAt: index)
    }
    
    func collectionViewControllerWillBeginScrolling(_ collectionViewController: IFCollectionViewController) {
        pageViewController.invalidateDataSourceIfNeeded()
    }
    
    func collectionViewControllerWillBeginSeekVideo(_ collectionViewController: IFCollectionViewController) {
        pageViewController.pauseMedia()
    }
    
    func collectionViewControllerDidEndSeekVideo(_ collectionViewController: IFCollectionViewController) {
        switch mediaManager.videoStatus.value {
        case .autoplay, .play:
            pageViewController.playMedia()
        default:
            break
        }
    }
}

private extension IFBrowserViewController.Action {
    func barButtonItem(target: Any?, action: Selector?) -> UIBarButtonItem {
        switch self {
        case .share:
            return UIBarButtonItem(barButtonSystemItem: .action, target: target, action: action)
        case .delete:
            return UIBarButtonItem(barButtonSystemItem: .trash, target: target, action: action)
        case .custom(_, let title, let image):
            if let image = image {
                return UIBarButtonItem(image: image, style: .plain, target: target, action: action)
            } else {
                return UIBarButtonItem(title: title, style: .plain, target: target, action: action)
            }
        }
    }
}
