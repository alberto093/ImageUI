//
//  IFMediaViewController.swift
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

import Combine
import AVFoundation
import UIKit
import NukeVideo
import PDFKit

class IFMediaViewController: UIViewController {
    private struct Constants {
        static let minimumMaximumZoomFactor: CGFloat = 3
        static let doubleTapZoomMultiplier: CGFloat = 0.85
        static let preferredAspectFillRatio: CGFloat = 0.9
    }
    
    @IBOutlet private weak var scrollView: UIScrollView!
    @IBOutlet private weak var contentView: IFMediaContentView!
    @IBOutlet private weak var imageView: UIImageView!
    @IBOutlet private weak var videoPlayerView: VideoPlayerView!
    @IBOutlet private weak var pdfView: PDFView!
    
    // MARK: - Public properties
    let mediaManager: IFMediaManager
    var displayingMediaIndex: Int {
        didSet {
            guard displayingMediaIndex != oldValue else { return }
            update()
        }
    }
    
    // MARK: - Accessory properties
    private var aspectFillZoom: CGFloat = 1
    private var needsFirstLayout = true
    private var viewDidAppear = false
    
    private var timeObserver: Any? {
        didSet {
            if let oldValue {
                videoPlayerView.playerLayer.player?.removeTimeObserver(oldValue)
            }
        }
    }
    
    private var videoPauseTimeToken: AnyCancellable? {
        didSet {
            oldValue?.cancel()
        }
    }
    
    private var bag: Set<AnyCancellable> = []
    
    private var contentSize: CGSize {
        switch mediaManager.media[safe: displayingMediaIndex]?.mediaType {
        case .image:
            if let image = imageView.image {
                return image.size
            }
        case .video:
            if let image = imageView.image {
                return image.size
            }
        case .pdf:
            return .zero
        case .none:
            break
        }
        
        return .zero
    }
    
    // MARK: - Initializer
    public init(mediaManager: IFMediaManager, displayingMediaIndex: Int? = nil) {
        self.mediaManager = mediaManager
        self.displayingMediaIndex = displayingMediaIndex ?? mediaManager.displayingMediaIndex
        super.init(nibName: IFMediaViewController.identifier, bundle: .module)
    }
    
    public required init?(coder: NSCoder) {
        self.mediaManager = IFMediaManager(media: [])
        self.displayingMediaIndex = 0
        super.init(coder: coder)
    }
    
    deinit {
        timeObserver = nil
    }
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setup()
        update()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        guard !viewDidAppear else { return }
        
        viewDidAppear = true
        
        mediaManager.updatedisplayingMedia(index: displayingMediaIndex)
        
        if mediaManager.media[displayingMediaIndex].mediaType.isVideo {
            mediaManager.videoStatus.value = .autoplay
        }
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        viewDidAppear = false
        videoPlayerView.playerLayer.player?.pause()
        scrollView.zoomScale = scrollView.minimumZoomScale
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        if needsFirstLayout {
            needsFirstLayout = false
            updateScrollView()
//            updatePDFView()
        }
    }
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        let centerOffsetRatioX = (scrollView.contentOffset.x + scrollView.frame.width / 2) / scrollView.contentSize.width
        let centerOffsetRatioY = (scrollView.contentOffset.y + scrollView.frame.height / 2) / scrollView.contentSize.height
        
        coordinator.animate(alongsideTransition: { _ in
            self.updateScrollView(resetZoom: false)
            self.updateContentOffset(previousOffsetRatio: CGPoint(x: centerOffsetRatioX, y: centerOffsetRatioY))
        })
        super.viewWillTransition(to: size, with: coordinator)
    }
    
    func pauseMedia() {
        videoPauseTimeToken = nil
        videoPlayerView.playerLayer.player?.pause()
        timeObserver = nil
        observeVideoPauseTime()
    }
    
    func playMedia() {
        videoPauseTimeToken = nil
        
        if videoPlayerView.playerLayer.player?.isAtEnd == true {
            videoPlayerView.playerLayer.player?.seek(to: .zero)
        }
        
        videoPlayerView.playerLayer.player?.play()
        observeVideoPlayTime(forced: false)
    }
    
    private func setup() {
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(contentViewDidDoubleTap))
        tapGesture.numberOfTapsRequired = 2
        contentView.addGestureRecognizer(tapGesture)
        
        scrollView.delegate = self
        scrollView.decelerationRate = .fast
        scrollView.contentInsetAdjustmentBehavior = .never
        
        pdfView.backgroundColor = .clear
        
        videoPlayerView.isLooping = false
        videoPlayerView.animatesFrameChanges = false
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(videoDidEnd),
            name: .AVPlayerItemDidPlayToEndTime,
            object: nil
        )
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(applicationWillEnterForeground),
            name: UIApplication.willEnterForegroundNotification,
            object: nil
        )
        
        mediaManager.videoStatus
            .dropFirst()
            .filter { [weak self] _ in
                self?.viewDidAppear == true && self?.mediaManager.allowsMediaPlay == true
            }
            .sink { [weak self] status in
                self?.videoPlayerView.alpha = 1
                self?.videoPauseTimeToken = nil
                
                switch status {
                case .autoplay:
                    if let player = self?.videoPlayerView.playerLayer.player {
                        player.play()
                    } else {
                        self?.videoPlayerView.play()
                        self?.videoPlayerView.playerLayer.player?.actionAtItemEnd = .pause
                        self?.observeVideoPlayTime(forced: true)
                    }
                case .play:
                    self?.playMedia()
                case .pause:
                    self?.pauseMedia()
                case .autoplayEnded, .autoplayPause:
                    self?.videoPlayerView.playerLayer.player?.pause()
                    self?.timeObserver = nil
                }
                
                self?.videoPlayerView.playerLayer.player?.isMuted = self?.mediaManager.soundStatus.value.isEnabled == false
            }
            .store(in: &bag)
        
        mediaManager.soundStatus
            .sink { [weak self] status in
                self?.videoPlayerView.playerLayer.player?.isMuted = !status.isEnabled
            }
            .store(in: &bag)
    }
    
    private func update() {
        guard isViewLoaded else { return }
        timeObserver = nil
        videoPlayerView.asset = nil
        UIView.performWithoutAnimation {
            switch mediaManager.media[safe: displayingMediaIndex]?.mediaType {
            case .image:
                mediaManager.loadImage(at: displayingMediaIndex, options: IFImage.LoadOptions(kind: .original), sender: imageView) { [weak self] _ in
                    self?.updateScrollView()
                }
            case .video:
                imageView.image = nil
                mediaManager.loadVideoCover(at: displayingMediaIndex) { [weak self] cover in
                    self?.imageView.image = cover
                    self?.updateScrollView()
                }
                
                mediaManager.loadVideo(at: displayingMediaIndex) { [weak self] videoAsset in
                    self?.videoPlayerView.asset = videoAsset

                    if self?.viewDidAppear == true {
                        self?.mediaManager.videoStatus.value = .autoplay
                    }
                }
            case .pdf:
                break
            case .none:
                break
            }
        }
    }
    
    private func updateScrollView(resetZoom: Bool = true) {
        guard view.frame != .zero else { return }
        
        let contentSize = self.contentSize
        contentView.contentSize = contentSize
        
        guard contentSize.width > 0, contentSize.height > 0 else {
            return
        }

        let safeAreaFrame = view.safeAreaLayoutGuide.layoutFrame
        let horizontalSafeAreaInsets = view.safeAreaInsets.left + view.safeAreaInsets.right
        let verticalSafeAreaInsets = view.safeAreaInsets.top + view.safeAreaInsets.bottom
        
        let aspectFitZoom: CGFloat

        if verticalSafeAreaInsets > horizontalSafeAreaInsets {
            aspectFitZoom = min(view.frame.width / contentSize.width, safeAreaFrame.height / contentSize.height)
            aspectFillZoom = max(view.frame.width / contentSize.width, safeAreaFrame.height / contentSize.height)
        } else {
            aspectFitZoom = min(safeAreaFrame.width / contentSize.width, view.frame.height / contentSize.height)
            aspectFillZoom = max(safeAreaFrame.width / contentSize.width, view.frame.height / contentSize.height)
        }

        let zoomMultiplier = (scrollView.zoomScale - scrollView.minimumZoomScale) / (scrollView.maximumZoomScale - scrollView.minimumZoomScale)

        let minimumZoomScale: CGFloat
        if mediaManager.prefersAspectFillZoom, aspectFitZoom / aspectFillZoom >= Constants.preferredAspectFillRatio {
            minimumZoomScale = aspectFillZoom
        } else {
            minimumZoomScale = aspectFitZoom
        }

        scrollView.minimumZoomScale = minimumZoomScale
        scrollView.maximumZoomScale = max(minimumZoomScale * Constants.minimumMaximumZoomFactor, aspectFillZoom)
        
        let zoomScale = resetZoom ? minimumZoomScale : (minimumZoomScale + (scrollView.maximumZoomScale - minimumZoomScale) * zoomMultiplier)
        scrollView.zoomScale = zoomScale
        updateContentInset()
    }
    
    private func updateContentInset() {
        let contentSize = contentSize
        
        scrollView.contentInset.top = max((scrollView.frame.height - contentSize.height * scrollView.zoomScale) / 2, 0)
        scrollView.contentInset.left = max((scrollView.frame.width - contentSize.width * scrollView.zoomScale) / 2, 0)
    }
    
    private func updateContentOffset(previousOffsetRatio: CGPoint) {
        guard scrollView.contentSize.width > 0, scrollView.contentSize.height > 0 else { return }
        let proposedContentOffsetX = (previousOffsetRatio.x * scrollView.contentSize.width) - (scrollView.frame.width / 2)
        let proposedContentOffsetY = (previousOffsetRatio.y * scrollView.contentSize.height) - (scrollView.frame.height / 2)
        
        let minimumContentOffsetX = -scrollView.contentInset.left.rounded(.up)
        let maximumContentOffsetX: CGFloat
        if scrollView.contentSize.width <= scrollView.frame.width {
            maximumContentOffsetX = minimumContentOffsetX
        } else {
            maximumContentOffsetX = (scrollView.contentSize.width - scrollView.frame.width + scrollView.contentInset.right).rounded(.down)
        }
        
        let minimumContentOffsetY = -scrollView.contentInset.top.rounded(.up)
        let maximumContentOffsetY: CGFloat
        if scrollView.contentSize.height <= scrollView.frame.height {
            maximumContentOffsetY = minimumContentOffsetY
        } else {
            maximumContentOffsetY = (scrollView.contentSize.height - scrollView.frame.height + scrollView.contentInset.bottom).rounded(.down)
        }
        
        let targetContentOffsetX = min(max(proposedContentOffsetX, minimumContentOffsetX), maximumContentOffsetX)
        let targetContentOffsetY = min(max(proposedContentOffsetY, minimumContentOffsetY), maximumContentOffsetY)
        
        scrollView.contentOffset = CGPoint(x: targetContentOffsetX, y: targetContentOffsetY)
    }
    
    private func observeVideoPlayTime(forced: Bool) {
        guard forced || timeObserver == nil else { return }
        timeObserver = (videoPlayerView.asset?.duration).flatMap { assetDuration in
            let frameInterval = CMTime(value: 1, timescale: Int32(UIScreen.main.maximumFramesPerSecond))
            return videoPlayerView.playerLayer.player?.addPeriodicTimeObserver(forInterval: frameInterval, queue: DispatchQueue.main, using: { [weak self] time in
                self?.mediaManager.videoPlayback.value = IFVideo.Playback(currentTime: time, totalDuration: assetDuration)
            })
        }
    }
    
    private func observeVideoPauseTime() {
        videoPauseTimeToken = mediaManager.videoPlayback
            .dropFirst()
            .throttle(for: .seconds(1 / Double(UIScreen.main.maximumFramesPerSecond)), scheduler: DispatchQueue.main, latest: true)
            .compactMap(\.?.currentTime)
            .sink { [weak self] currentTime in
                self?.videoPlayerView.playerLayer.player?.seek(to: currentTime)
            }
    }
    
    // MARK: - UI Actions
    @objc private func contentViewDidDoubleTap(_ sender: UITapGestureRecognizer) {
        switch scrollView.zoomScale {
        case scrollView.minimumZoomScale:
            let tapLocation = sender.location(in: contentView)
            let targetZoomScale = max(aspectFillZoom, scrollView.maximumZoomScale * Constants.doubleTapZoomMultiplier)
            let zoomWidth = scrollView.bounds.width / targetZoomScale
            let zoomHeight = scrollView.bounds.height / targetZoomScale
            let zoomRect = CGRect(x: tapLocation.x - zoomWidth / 2, y: tapLocation.y - zoomHeight / 2, width: zoomWidth, height: zoomHeight)
            scrollView.zoom(to: zoomRect, animated: true)
        default:
            scrollView.setZoomScale(scrollView.minimumZoomScale, animated: true)
        }
    }
    
    @objc private func videoDidEnd(_ notification: Notification) {
        guard 
            let playerItem = notification.object as? AVPlayerItem,
            playerItem === videoPlayerView.playerLayer.player?.currentItem
        else {
            return
        }
        
        switch mediaManager.videoStatus.value {
        case .autoplay:
            mediaManager.videoStatus.value = .autoplayEnded
            if imageView.image != nil { // existing video cover
                UIView.animate(withDuration: 0.24) { [weak self] in
                    self?.videoPlayerView.alpha = 0
                } completion: { [weak self] _ in
                    self?.videoPlayerView.playerLayer.player?.seek(to: .zero)
                }
            } else {
                videoPlayerView.playerLayer.player?.seek(to: .zero)
            }
        case .play:
            mediaManager.videoStatus.value = .pause
        default:
            break
        }
    }
    
    @objc private func applicationWillEnterForeground() {
        switch mediaManager.videoStatus.value {
        case .autoplay, .play:
            videoPlayerView.playerLayer.player?.play()
        default:
            break
        }
    }
}

extension IFMediaViewController: UIScrollViewDelegate {
    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        contentView
    }
    
    func scrollViewDidZoom(_ scrollView: UIScrollView) {
        updateContentInset()
    }
}

extension IFMediaViewController: IFImageContainerProvider {
    var imageContainerView: UIView {
        scrollView
    }
}

class IFMediaContentView: UIView {
    var contentSize: CGSize = .zero {
        didSet {
            invalidateIntrinsicContentSize()
        }
    }
    
    override var intrinsicContentSize: CGSize {
        contentSize
    }
}
