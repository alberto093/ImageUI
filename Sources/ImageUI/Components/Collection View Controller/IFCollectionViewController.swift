//
//  IFCollectionViewController.swift
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
import Nuke
import Photos
import Combine

protocol IFCollectionViewControllerDelegate: AnyObject {
    func collectionViewController(_ collectionViewController: IFCollectionViewController, didSelectItemAt index: Int)
    func collectionViewControllerWillBeginScrolling(_ collectionViewController: IFCollectionViewController)
    func collectionViewControllerWillBeginSeekVideo(_ collectionViewController: IFCollectionViewController)
    func collectionViewControllerDidEndSeekVideo(_ collectionViewController: IFCollectionViewController)
}

class IFCollectionViewController: UIViewController {
    private struct Constants {
        static let carouselScrollingTransitionDuration: TimeInterval = 0.34
        static let carouselTransitionDuration: TimeInterval = 0.16
        static let carouselSelectionDuration: TimeInterval = 0.22
        static let flowTransitionDuration: TimeInterval = 0.24
        static let videoScrollingDampingFactor: CGFloat = 0.5
    }
    
    enum PendingInvalidation {
        case bouncing
        case dragging(targetIndexPath: IndexPath)
    }
    
    // MARK: - View
    private lazy var collectionView: UICollectionView = {
        let initialIndexPath = IndexPath(item: mediaManager.displayingMediaIndex, section: 0)
        let layout = IFCollectionViewFlowLayout(mediaManager: mediaManager, centerIndexPath: initialIndexPath, needsInitialContentOffset: true)
        let view = IFCollectionView(frame: .zero, collectionViewLayout: layout)
        view.backgroundColor = .clear
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private var horizontalConstraints: [NSLayoutConstraint] = []
    
    // MARK: - Public properties
    weak var delegate: IFCollectionViewControllerDelegate?
    let mediaManager: IFMediaManager
    
    // MARK: - Accessory properties
    private let prefetcher = ImagePrefetcher()
    private let bouncer = IFScrollViewBouncingManager()
    private var pendingInvalidation: PendingInvalidation?
    private lazy var videoHandler = IFCollectionViewPanGestureHandler(collectionView: collectionView)
    private var isSeekingVideo = false
    
    private var bag: Set<AnyCancellable> = []
    
    private var collectionViewLayout: IFCollectionViewFlowLayout {
        // swiftlint:disable:next force_cast
        collectionView.collectionViewLayout as! IFCollectionViewFlowLayout
    }
    
    // MARK: - Initializer
    init(mediaManager: IFMediaManager) {
        self.mediaManager = mediaManager
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        self.mediaManager = IFMediaManager(media: [])
        super.init(coder: coder)
    }
    
    deinit {
        prefetcher.stopPrefetching()
    }
    
    // MARK: - Lifecycle
    override func loadView() {
        view = UIView()
        view.clipsToBounds = true
        view.addSubview(collectionView)
        let leading = collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor)
        let bottom = view.bottomAnchor.constraint(equalTo: collectionView.bottomAnchor)
        let trailing = view.trailingAnchor.constraint(equalTo: collectionView.trailingAnchor)
        let top = collectionView.topAnchor.constraint(equalTo: view.topAnchor)
        horizontalConstraints = [leading, trailing]
        NSLayoutConstraint.activate([leading, bottom, trailing, top])
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setup()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        update()
    }
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        collectionViewLayout.invalidateLayout()
        super.viewWillTransition(to: size, with: coordinator)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        collectionView.prefetchDataSource = nil
        prefetcher.stopPrefetching()
    }
    
    // MARK: - Public methods
    func scroll(from sourceIndex: Int, to destinationIndex: Int, progress: CGFloat) {
        guard isViewLoaded else { return }

        if collectionView.isDecelerating {
            updateCollectionViewLayout(style: .carousel)
        } else {
            let sourceIndexPath = IndexPath(item: sourceIndex, section: 0)
            let destinationIndexPath = IndexPath(item: destinationIndex, section: 0)
            let isSourceVideo = mediaManager.media[safe: sourceIndex]?.mediaType.isVideo == true
            let isDestinationVideo = mediaManager.media[safe: destinationIndex]?.mediaType.isVideo

            switch (isSourceVideo, isDestinationVideo) {
            case (false, false), (false, .none): // image -> image, image -> out of bounds
                updateCollectionViewLayout(transitionIndexPath: destinationIndexPath, progress: progress)
            case (false, true): // image -> video
                let isPlayingVideo = collectionViewLayout.centerIndexPath.item == destinationIndex
                
                if isPlayingVideo {
                    if progress < 0.5 {
                        updateCollectionViewLayout(transitionIndexPath: sourceIndexPath, progress: progress)
                        collectionViewLayout.update(centerIndexPath: sourceIndexPath)
                        collectionView.reloadItems(at: [destinationIndexPath])
                    }
                } else {
                    updateCollectionViewLayout(transitionIndexPath: destinationIndexPath, progress: progress > 0.5 ? 1 : progress)
                }
            case (true, false): // video -> image
                let isPlayingVideo = collectionViewLayout.centerIndexPath.item == sourceIndex
                
                if isPlayingVideo {
                    if progress > 0.5 {
                        updateCollectionViewLayout(transitionIndexPath: destinationIndexPath, progress: progress)
                        collectionViewLayout.update(centerIndexPath: destinationIndexPath)
                        collectionView.reloadItems(at: [sourceIndexPath])
                    }
                } else {
                    updateCollectionViewLayout(transitionIndexPath: sourceIndexPath, progress: progress < 0.5 ? 1 : (1 - progress))
                }
            case (true, true): // video -> video
                if progress > 0.5, collectionViewLayout.centerIndexPath.item != destinationIndex {
                    updateCollectionViewLayout(transitionIndexPath: destinationIndexPath, progress: 1)
                    collectionView.reloadItems(at: [sourceIndexPath])
                } else if progress < 0.5, collectionViewLayout.centerIndexPath.item != sourceIndex {
                    updateCollectionViewLayout(transitionIndexPath: sourceIndexPath, progress: 1)
                    collectionView.reloadItems(at: [destinationIndexPath])
                }
            default:
                return
            }
        }
    }
    
    func scrollToDisplayingMediaIndex() {
        guard collectionViewLayout.isTransitioning || collectionViewLayout.centerIndexPath.item != mediaManager.displayingMediaIndex else { return }
        updateCollectionViewLayout(style: .carousel)
    }
    
    func removeDisplayingMedia(completion: (() -> Void)? = nil) {
        guard let cell = collectionView.cellForItem(at: collectionViewLayout.centerIndexPath) else { return }
        let currentIndexPath = collectionViewLayout.centerIndexPath
        collectionViewLayout.update(centerIndexPath: IndexPath(item: mediaManager.displayingMediaIndex, section: 0))
        
        let removingAnimation = {
            self.collectionView.performBatchUpdates({
                self.collectionView.deleteItems(at: [currentIndexPath])
            }, completion: { _ in
                let targetContentOffset = self.collectionViewLayout.targetContentOffset(forProposedContentOffset: self.collectionView.contentOffset)
                self.collectionView.setContentOffset(targetContentOffset, animated: false)
                completion?()
            })
        }
        
        if let cell = cell as? IFImageContainerProvider {
            cell.prepareForRemove {
                if self.mediaManager.media.isEmpty {
                    completion?()
                } else {
                    removingAnimation()
                }
            }
        } else {
            removingAnimation()
        }
    }
    
    // MARK: - Private methods
    private func setup() {
        collectionView.register(IFCollectionViewCell.self, forCellWithReuseIdentifier: IFCollectionViewCell.identifier)
        collectionView.showsVerticalScrollIndicator = false
        collectionView.showsHorizontalScrollIndicator = false
        collectionView.dataSource = self
        collectionView.prefetchDataSource = self
        collectionView.delegate = self
        collectionView.alwaysBounceHorizontal = true
        collectionView.panGestureRecognizer.addTarget(self, action: #selector(pangestureDidChange))
        videoHandler.dataSource = self
        videoHandler.delegate = self
        
        bouncer.startObserving(scrollView: collectionView, bouncingDirections: [.left, .right])
        bouncer.delegate = self
        
        mediaManager.videoStatus
            .dropFirst()
            .scan(nil) { (oldValue: $0?.1, newValue: $1) }
            .compactMap { $0 }
            .filter { [weak self] _ in
                guard let self else { return false }
                return self.mediaManager.media[self.collectionViewLayout.centerIndexPath.item].mediaType.isVideo && self.collectionViewLayout.style == .carousel
            }
            .sink { [weak self] status in
                guard let self else { return }
                
                if status.newValue.isAutoplay || (status.newValue == .play && status.oldValue != .pause) || (status.newValue == .pause && status.oldValue != .play) {
                    self.collectionView.performBatchUpdates(
                        {
                            self.collectionView.reloadItems(at: [self.collectionViewLayout.centerIndexPath, self.collectionViewLayout.transition.indexPath])
                            
                            if status.newValue.isAutoplay {
                                self.collectionViewLayout.update(centerIndexPath: self.collectionViewLayout.centerIndexPath, shouldInvalidate: true)
                            }
                        }, completion: { _ in
                            self.videoHandler.invalidateDataSource()
                        }
                    )
                } 
                
                if (status.newValue == .play && status.oldValue == .pause) || (status.newValue == .pause && status.oldValue == .play) {
                    self.videoHandler.invalidateDataSource()
                    self.collectionView.setContentOffset(self.collectionView.contentOffset, animated: false)
                }
            }
            .store(in: &bag)
        
        mediaManager.videoPlayback
            .combineLatest(mediaManager.videoStatus) { (playback: $0, status: $1) }
            .filter { [weak self] _ in
                self?.collectionViewLayout.style == .carousel
            }
            .sink { [weak self] video in
                guard
                    let self,
                    let cell = self.collectionView.cellForItem(at: self.collectionViewLayout.centerIndexPath) as? IFCollectionViewCell,
                    self.collectionViewLayout.isPlayingVideo
                else { return }
                
                if let playback = video.playback {
                    cell.configureVideo(
                        playback: playback,
                        showVideoIndicator: video.status != .autoplayEnded && video.status != .autoplayPause,
                        showPlaybackTime: self.isSeekingVideo)
                    
                    if video.status == .play, !self.collectionView.isDragging, !self.collectionView.isDecelerating {
                        self.collectionViewLayout.setupCellWidthAutoScroll(progress: playback.progress)
                    }
                }
            }
            .store(in: &bag)
    }
    
    private func update() {
        if collectionView.bounds.width < view.bounds.width + collectionViewLayout.preferredOffBoundsPadding {
            horizontalConstraints.forEach {
                $0.constant = -collectionViewLayout.preferredOffBoundsPadding
            }
            collectionView.layoutIfNeeded()
            collectionViewLayout.invalidateLayout()
        }
    }
    
    @discardableResult private func updatedisplayingMediaIndexIfNeeded(with index: Int) -> Bool {
        guard mediaManager.displayingMediaIndex != index else { return false }
        mediaManager.updatedisplayingMedia(index: index)
        collectionViewLayout.update(centerIndexPath: IndexPath(item: index, section: 0))
        delegate?.collectionViewController(self, didSelectItemAt: index)
        return true
    }

    private func updateCollectionViewLayout(style: IFCollectionViewFlowLayout.Style) {
        let indexPath = IndexPath(item: mediaManager.displayingMediaIndex, section: 0)
        let layout = IFCollectionViewFlowLayout(mediaManager: mediaManager, style: style, centerIndexPath: indexPath)
        let duration: TimeInterval
        
        switch pendingInvalidation {
        case .dragging:
            duration = Constants.carouselScrollingTransitionDuration
        default:
            duration = style == .carousel ? Constants.carouselTransitionDuration : Constants.flowTransitionDuration
        }
        
        pendingInvalidation = nil
        mediaManager.allowsMediaPlay = style == .carousel
        
        UIView.transition(
            with: collectionView,
            duration: duration,
            options: .curveEaseOut,
            animations: {
                if style == .flow, self.collectionViewLayout.isPlayingVideo {
                    self.collectionView.reloadItems(at: [self.collectionViewLayout.centerIndexPath])
                    self.videoHandler.invalidateDataSource()
                }
                
                if style == .flow || (self.collectionViewLayout.isPlayingVideo && !self.mediaManager.videoStatus.value.isAutoplay) {
                    let contentOffset = self.collectionView.contentOffset
                    self.collectionView.setCollectionViewLayout(layout, animated: true)
                    let updatedContentOffset = self.collectionView.contentOffset
                    self.collectionView.panGestureRecognizer.setTranslation(CGPoint(x: contentOffset.x - updatedContentOffset.x, y: 0), in: self.collectionView)
                } else {
                    self.collectionView.setCollectionViewLayout(layout, animated: true)
                }
                
                if style == .flow {
                    self.delegate?.collectionViewControllerWillBeginScrolling(self)
                }
        })
    }
    
    private func updateCollectionViewLayout(transitionIndexPath: IndexPath, progress: CGFloat) {
        let layout = IFCollectionViewFlowLayout(mediaManager: mediaManager, centerIndexPath: collectionViewLayout.centerIndexPath)
        layout.style = collectionViewLayout.style
        layout.setupTransition(to: transitionIndexPath, progress: progress)
        
        collectionView.setCollectionViewLayout(layout, animated: false)
    }
    
    private func updateCollectionViewLayout(forPreferredSizeAt indexPath: IndexPath) {
        guard
            collectionViewLayout.shouldInvalidateLayout(forPreferredItemSizeAt: indexPath),
            !collectionView.isDragging,
            !collectionView.isDecelerating else { return }
        updateCollectionViewLayout(style: .carousel)
    }
    
    private func beginSeekVideo(gestureLocation: CGPoint) {
        guard
            collectionViewLayout.isPlayingVideo,
            let cell = collectionView.cellForItem(at: collectionViewLayout.centerIndexPath) as? IFCollectionViewCell
        else { return }
        
        if cell.frame.containsIncludingBorders(gestureLocation) {
            if mediaManager.videoStatus.value == .autoplay {
                mediaManager.videoStatus.value = .play
            }
        } else if mediaManager.videoStatus.value.isAutoplay {
            videoHandler.isInvalidated = true
        }
        
        isSeekingVideo = true
        
        if let playback = mediaManager.videoPlayback.value {
            cell.configureVideo(
                playback: playback,
                showVideoIndicator: mediaManager.videoStatus.value != .autoplayEnded && mediaManager.videoStatus.value != .autoplayPause,
                showPlaybackTime: true)
        }
        
        delegate?.collectionViewControllerWillBeginSeekVideo(self)
    }
    
    @objc private func pangestureDidChange(_ sender: UIPanGestureRecognizer) {
        switch sender.state {
        case .began:
            if collectionViewLayout.isTransitioning {
                updateCollectionViewLayout(style: .carousel)
                delegate?.collectionViewControllerWillBeginScrolling(self)
            } else if collectionViewLayout.isPlayingVideo {
                beginSeekVideo(gestureLocation: sender.location(in: collectionView))
            }
        case .cancelled, .ended:
            if !collectionViewLayout.isPlayingVideo, pendingInvalidation == nil {
                updateCollectionViewLayout(style: .carousel)
            }
        default:
            break
        }
    }
}

// MARK: - UICollectionViewDataSource
extension IFCollectionViewController: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        mediaManager.media.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: IFCollectionViewCell.identifier, for: indexPath)
        
        if let cell = cell as? IFCollectionViewCell {
            cell.mediaManager = mediaManager
            
            switch mediaManager.media[indexPath.item].mediaType {
            case .image:
                mediaManager.loadImage(
                    at: indexPath.item,
                    options: IFImage.LoadOptions(preferredSize: collectionViewLayout.itemSize, kind: .thumbnail),
                    sender: cell) { [weak self] result in
                        guard let self = self, case .success = result else { return }
                        self.updateCollectionViewLayout(forPreferredSizeAt: indexPath)
                    }
            case .video:
                mediaManager.loadVideoCover(at: indexPath.item) { [weak self, weak cell] image in
                    cell?.nuke_display(image: image, data: nil)
                    self?.updateCollectionViewLayout(forPreferredSizeAt: indexPath)
                }
                
                if indexPath == collectionViewLayout.centerIndexPath, collectionViewLayout.isPlayingVideo {
                    mediaManager.videoThumbnailGenerator(at: indexPath.item) { [weak self] generator in
                        guard let self else { return }

                        switch self.mediaManager.videoStatus.value {
                        case .autoplay:
                            if let generator {
                                generator.generateAutoplayLastThumbnail { [weak self, weak cell] thumb in
                                    self?.mediaManager.loadVideoCover(at: indexPath.item) { [weak cell] cover in
                                        guard let self, let cell else { return }
                                        cell.configureVideo(thumbnails: [cover, thumb ?? cover], videoStatus: self.mediaManager.videoStatus.value)
                                        self.updateCollectionViewLayout(forPreferredSizeAt: indexPath)
                                    }
                                }
                            } else {
                                self.mediaManager.loadVideoCover(at: indexPath.item) { [weak self, weak cell] image in
                                    guard let self, let cell else { return }
                                    cell.configureVideo(thumbnails: [image, image], videoStatus: self.mediaManager.videoStatus.value)
                                    self.updateCollectionViewLayout(forPreferredSizeAt: indexPath)
                                }
                            }
                        case .autoplayPause, .autoplayEnded:
                            self.mediaManager.loadVideoCover(at: indexPath.item) { [weak self, weak cell] cover in
                                guard let self, let cell else { return }
                                
                                cell.configureVideo(thumbnails: [cover], videoStatus: self.mediaManager.videoStatus.value)
                                self.updateCollectionViewLayout(forPreferredSizeAt: indexPath)
                            }
                        case .play, .pause:
                            self.mediaManager.loadVideoCover(at: indexPath.item) { [weak self, weak cell] cover in
                                guard let self else { return }
                                if let generator {
                                    generator.generateImages(currentTime: .zero) { [weak self, weak cell] thumbnails in
                                        guard let self, let cell else { return }
                                        let thumbnails = (0..<generator.numberOfThumbnails).map { thumbnails[$0] ?? cover }
                                        cell.configureVideo(thumbnails: thumbnails, videoStatus: self.mediaManager.videoStatus.value)
                                        self.updateCollectionViewLayout(forPreferredSizeAt: indexPath)
                                    }
                                } else if let cell {
                                    cell.configureVideo(thumbnails: [cover, cover].compactMap { $0 }, videoStatus: self.mediaManager.videoStatus.value)
                                    self.updateCollectionViewLayout(forPreferredSizeAt: indexPath)
                                }
                            }
                        }
                    }
                }
            case .pdf:
                break
            }
            
        }
        
        return cell
    }
}

// MARK: - UICollectionViewDataSourcePrefetching
extension IFCollectionViewController: UICollectionViewDataSourcePrefetching {
    func collectionView(_ collectionView: UICollectionView, prefetchItemsAt indexPaths: [IndexPath]) {
        guard collectionView.isDragging || collectionView.isDecelerating else { return }
        var urls: [URL] = []
        var assets: [PHAsset] = []
        
        for indexPath in indexPaths {
            guard let media = mediaManager.media[safe: indexPath.item] else { continue }
            
            switch media.mediaType {
            case .image(let image):
                switch image[.thumbnail] {
                case .asset(let asset):
                    assets.append(asset)
                case .url(let url):
                    urls.append(url)
                case .image:
                    break
                }
            case .video:
                mediaManager.loadVideoCover(at: indexPath.item)
            case .pdf:
                break
            }
        }
        
        let request = PHImageRequestOptions()
        request.isNetworkAccessAllowed = true
        
        mediaManager.photosManager.startCachingImages(for: assets, targetSize: collectionViewLayout.itemSize, contentMode: .aspectFit, options: request)
        prefetcher.startPrefetching(with: urls)
    }
    
    func collectionView(_ collectionView: UICollectionView, cancelPrefetchingForItemsAt indexPaths: [IndexPath]) {
        var urls: [URL] = []
        var assets: [PHAsset] = []
        
        for indexPath in indexPaths {
            guard let media = mediaManager.media[safe: indexPath.item] else { continue }
            
            switch media.mediaType {
            case .image(let image):
                switch image[.thumbnail] {
                case .asset(let asset):
                    assets.append(asset)
                case .url(let url):
                    urls.append(url)
                case .image:
                    break
                }
            case .video:
                break
            case .pdf:
                break
            }
        }
        
        let request = PHImageRequestOptions()
        request.isNetworkAccessAllowed = true
        
        mediaManager.photosManager.stopCachingImages(for: assets, targetSize: collectionViewLayout.itemSize, contentMode: .aspectFit, options: request)
        prefetcher.stopPrefetching(with: urls)
    }
}

// MARK: - UICollectionViewDelegate
extension IFCollectionViewController: UICollectionViewDelegate {
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        guard !collectionViewLayout.isTransitioning else { return }

        if collectionViewLayout.isPlayingVideo {
            if videoHandler.isInvalidated {
                if let centerIndexPath = collectionView.indexPathForItem(at: CGPoint(x: collectionView.bounds.midX, y: collectionView.bounds.midY)), centerIndexPath != collectionViewLayout.centerIndexPath {
                    collectionView.reloadItems(at: [collectionViewLayout.centerIndexPath])
                    updatedisplayingMediaIndexIfNeeded(with: centerIndexPath.item)
                    mediaManager.videoStatus.value = .autoplay
                    updateCollectionViewLayout(style: .flow)
                }
            } else if 
                let playback = mediaManager.videoPlayback.value,
                let videoCell = collectionView.cellForItem(at: collectionViewLayout.centerIndexPath) as? IFCollectionViewCell,
                videoCell.videoStatus?.isAutoplay == false,
                !mediaManager.videoStatus.value.isAutoplay
            {
                let cursor = collectionView.contentOffset.x + collectionView.frame.width / 2
                let progress = ((cursor - videoCell.frame.minX) / (videoCell.frame.maxX - videoCell.frame.minX)).clamped(to: 0...1)
                mediaManager.videoPlayback.value?.currentTime = CMTimeMultiplyByFloat64(playback.totalDuration, multiplier: Float64(progress))
                
                if progress == 0 || progress == 1 {
                    let cellBouncingDistance = (progress == 0 ? videoCell.frame.minX : videoCell.frame.maxX) - collectionView.frame.width / 2 - collectionView.contentOffset.x
                    mediaManager.videoPlaybackLabel.frame.origin.x = mediaManager.videoPlaybackLabel.defaultOrigin.x + cellBouncingDistance
                } else {
                    mediaManager.videoPlaybackLabel.resetToDefaultPosition()
                }
            }
        } else if
            collectionView.isDragging,
            let centerIndexPath = collectionView.indexPathForItem(at: CGPoint(x: collectionView.bounds.midX, y: collectionView.bounds.midY)),
            updatedisplayingMediaIndexIfNeeded(with: centerIndexPath.item),
            case .dragging(let targetIndexPath) = pendingInvalidation,
            targetIndexPath == centerIndexPath {
            
            updateCollectionViewLayout(style: .carousel)
            videoHandler.isInvalidated = true
        }
    }
    
    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        pendingInvalidation = nil

        if collectionViewLayout.isPlayingVideo, let videoPlayback = mediaManager.videoPlayback.value {
            collectionViewLayout.setupCellWidthAutoScroll(progress: videoPlayback.progress)
        }
        
        if !collectionViewLayout.isPlayingVideo, collectionViewLayout.style == .carousel {
            updateCollectionViewLayout(style: .flow)
        }
    }
    
    func scrollViewWillEndDragging(_ scrollView: UIScrollView, withVelocity velocity: CGPoint, targetContentOffset: UnsafeMutablePointer<CGPoint>) {
        if collectionViewLayout.isPlayingVideo {
            videoHandler.isInvalidated = false
            
            if velocity.x == 0 {
                isSeekingVideo = false
                delegate?.collectionViewControllerDidEndSeekVideo(self)
            }
        } else if velocity.x != 0 {
            let minimumContentOffsetX = -scrollView.contentInset.left.rounded(.up)
            let maximumContentOffsetX = (scrollView.contentSize.width - scrollView.bounds.width + scrollView.contentInset.right).rounded(.down)
            if targetContentOffset.pointee.x > minimumContentOffsetX, targetContentOffset.pointee.x < maximumContentOffsetX {
                let targetIndexPath = collectionViewLayout.indexPath(forContentOffset: targetContentOffset.pointee)
                pendingInvalidation = .dragging(targetIndexPath: targetIndexPath)
            } else {
                pendingInvalidation = .bouncing
            }
        }
    }
    
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        guard !collectionViewLayout.isPlayingVideo, pendingInvalidation != nil else { return }
        
        let centerIndexPath = collectionViewLayout.indexPath(forContentOffset: collectionView.contentOffset)
        updatedisplayingMediaIndexIfNeeded(with: centerIndexPath.item)
        updateCollectionViewLayout(style: .carousel)
    }
    
    func scrollViewDidEndScrollingAnimation(_ scrollView: UIScrollView) {
        isSeekingVideo = false
        delegate?.collectionViewControllerDidEndSeekVideo(self)
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard updatedisplayingMediaIndexIfNeeded(with: indexPath.item) else { return }

        UIView.transition(
            with: collectionView,
            duration: Constants.carouselSelectionDuration,
            options: .curveEaseOut,
            animations: {
                self.collectionViewLayout.setupTransition(to: indexPath, progress: 1)
                self.collectionViewLayout.invalidateLayout()
                self.collectionView.layoutIfNeeded()
            })
    }
}

// MARK: - IFScrollViewBouncingDelegate
extension IFCollectionViewController: IFScrollViewBouncingDelegate {
    func scrollView(_ scrollView: UIScrollView, didReverseBouncing direction: UIScrollView.BouncingDirection) {
        guard !collectionViewLayout.isPlayingVideo else { return }
        
        let indexPath: IndexPath
        
        switch direction {
        case .left:
            indexPath = IndexPath(item: 0, section: 0)
        case .right:
            indexPath = IndexPath(item: mediaManager.media.count - 1, section: 0)
        default:
            return
        }
        updatedisplayingMediaIndexIfNeeded(with: indexPath.item)
        updateCollectionViewLayout(style: .carousel)
    }
}

// MARK: - IFCollectionViewPanGestureHandlerDataSource
extension IFCollectionViewController: IFCollectionViewPanGestureHandlerDataSource {
    func collectionViewPanGestureHandlerRubberBounds(_ collectionViewPanGestureHandler: IFCollectionViewPanGestureHandler) -> CGRect? {
        guard 
            collectionViewLayout.isPlayingVideo,
            !mediaManager.videoStatus.value.isAutoplay,
            let cell = collectionView.cellForItem(at: collectionViewLayout.centerIndexPath)
        else { return nil }
        
        return CGRect(
            x: cell.frame.origin.x - collectionView.frame.width / 2,
            y: 0,
            width: cell.frame.width,
            height: collectionView.frame.height
        )
    }
}

extension IFCollectionViewController: IFCollectionViewPanGestureHandlerDelegate {
    func collectionViewPanGestureHandlerDidEndDecelerating(_ collectionViewPanGestureHandler: IFCollectionViewPanGestureHandler) {
        guard 
            collectionViewLayout.isPlayingVideo,
            let cell = collectionView.cellForItem(at: collectionViewLayout.centerIndexPath) as? IFCollectionViewCell
        else { return }
        
        isSeekingVideo = false
        
        if let playback = mediaManager.videoPlayback.value {
            cell.configureVideo(
                playback: playback,
                showVideoIndicator: mediaManager.videoStatus.value != .autoplayEnded && mediaManager.videoStatus.value != .autoplayPause,
                showPlaybackTime: false)
        }
        
        delegate?.collectionViewControllerDidEndSeekVideo(self)
    }
}

extension IFCollectionViewController: IFCollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, touchesBegan location: CGPoint) {
        beginSeekVideo(gestureLocation: location)
    }
    
    func collectionView(_ collectionView: UICollectionView, touchesEnded location: CGPoint) {
        guard
            collectionViewLayout.isPlayingVideo,
            let cell = collectionView.cellForItem(at: collectionViewLayout.centerIndexPath) as? IFCollectionViewCell,
            cell.frame.containsIncludingBorders(location)
        else { return }

        isSeekingVideo = false
        
        if let playback = mediaManager.videoPlayback.value {
            cell.configureVideo(
                playback: playback,
                showVideoIndicator: mediaManager.videoStatus.value != .autoplayEnded && mediaManager.videoStatus.value != .autoplayPause,
                showPlaybackTime: false)
        }
        
        delegate?.collectionViewControllerDidEndSeekVideo(self)
    }
}
