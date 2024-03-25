//
//  IFCollectionViewCell.swift
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
import NukeExtensions

class IFCollectionViewCell: UICollectionViewCell {
    private enum Constants {
        static let videoIndicatorWidth: CGFloat = 2
        static let videoIndicatorBorderWidth: CGFloat = 0.75
        static let videoAutoplayThumbnailWidth: CGFloat = 50
        #warning("Missing algorithm to calculate dynamic aspect ratio")
        static let videoPlayThumbnailAspectRatio: CGFloat = 1.65
        static let videoThumbnailTransitionDuration: TimeInterval = 0.22
        static let videoPlaybackLabelShowTransitionDuration: TimeInterval = 0.1
        static let videoPlaybackLabelHideTransitionDuration: TimeInterval = 0.24
        static let videoPlaybackLabelHideTransitionDelay: TimeInterval = 0.5
    }
    
    // MARK: - View
    private let stackView: UIStackView = {
        let stackView = UIStackView()
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.axis = .horizontal
        stackView.distribution = .fillEqually
        stackView.spacing = 0
        return stackView
    }()
    
    private let videoIndicatorView: UIView = {
        let view = UIView(frame: CGRect(x: 0, y: Constants.videoIndicatorBorderWidth / 2, width: Constants.videoIndicatorWidth, height: 0))
        view.backgroundColor = .white
        view.layer.cornerRadius = Constants.videoIndicatorWidth / 2
        return view
    }()
    
    private let videoIndicatorViewBorderLayer: CALayer = {
        let layer = CALayer()
        layer.frame = CGRect(
            x: -Constants.videoIndicatorBorderWidth,
            y: -Constants.videoIndicatorBorderWidth,
            width: Constants.videoIndicatorWidth + 2 * Constants.videoIndicatorBorderWidth,
            height: 0)
        layer.borderColor = UIColor.black.withAlphaComponent(0.6).cgColor
        layer.borderWidth = Constants.videoIndicatorBorderWidth
        layer.cornerRadius = Constants.videoIndicatorWidth
        return layer
    }()
    
    weak var mediaManager: IFMediaManager?
    private var isAnimatingPlaybackLabelHidden = (isAnimating: false, hidden: false)
    private var needsVideoPlaybackLayout = true
    private var boundsObservation: NSKeyValueObservation?
    
    private weak var loadingTask: Cancellable? {
        didSet {
            oldValue?.cancel()
        }
    }
    
    // MARK: - Lifecycle
    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }
    
    deinit {
        loadingTask?.cancel()
        boundsObservation?.invalidate()
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        imageContainerView.alpha = 1
        imageContainerView.transform = .identity
        stackView.arrangedSubviews.forEach { $0.removeFromSuperview() }
        
        reset()
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        videoIndicatorView.frame.size.height = bounds.height - Constants.videoIndicatorBorderWidth
        videoIndicatorViewBorderLayer.frame.size.height = bounds.height + Constants.videoIndicatorBorderWidth
    }
    
    override func preferredLayoutAttributesFitting(_ layoutAttributes: UICollectionViewLayoutAttributes) -> UICollectionViewLayoutAttributes {
        if let image = (stackView.arrangedSubviews.first as? UIImageView)?.image, image.size.height != 0 {
            let imageRatio = image.size.width / image.size.height
            layoutAttributes.size.width = layoutAttributes.size.height * imageRatio
        }
        
        if mediaManager?.media[layoutAttributes.indexPath.item].mediaType.isVideo == true {
            switch mediaManager?.videoStatus.value {
            case .autoplay:
                layoutAttributes.size.width = Constants.videoAutoplayThumbnailWidth * 2
            case .play, .pause:
                let thumbWidth = layoutAttributes.size.height * Constants.videoPlayThumbnailAspectRatio
                layoutAttributes.size.width = thumbWidth * CGFloat(stackView.arrangedSubviews.count)
            default:
                break
            }
        }
        
        return layoutAttributes
    }
    
    // MARK: - Style
    private func setup() {
        clipsToBounds = false
        contentView.clipsToBounds = true
        contentView.addSubview(stackView)
        addSubview(videoIndicatorView)
        
        videoIndicatorView.isHidden = true
        videoIndicatorView.layer.addSublayer(videoIndicatorViewBorderLayer)
        
        NSLayoutConstraint.activate([
            stackView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            stackView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            stackView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            stackView.topAnchor.constraint(equalTo: contentView.topAnchor)])
        
        boundsObservation = observe(\.bounds, options: [.old, .new]) { [weak self] _, change in
            guard 
                let self,
                let progress = self.mediaManager?.videoPlayback.value?.progress,
                let oldWidth = change.oldValue?.width,
                let newWidth = change.newValue?.width,
                oldWidth != newWidth 
            else { return }
            
            let videoProgressCenterX = bounds.width * CGFloat(progress)
            self.videoIndicatorView.frame.origin.x = videoProgressCenterX - self.videoIndicatorView.frame.width / 2
        }
    }
    
    private func prepareStackView(numberOfImages: Int) {
        let imageView = {
            let imageView = UIImageView()
            imageView.clipsToBounds = true
            imageView.contentMode = .scaleAspectFill
            return imageView
        }
        
        if stackView.arrangedSubviews.count < numberOfImages {
            (stackView.arrangedSubviews.count..<numberOfImages).forEach { _ in
                let imageView = imageView()
                imageView.image = (stackView.arrangedSubviews[safe: stackView.arrangedSubviews.count] as? UIImageView)?.image
                stackView.addArrangedSubview(imageView)
            }
        } else if stackView.arrangedSubviews.count > numberOfImages {
            stackView.arrangedSubviews[numberOfImages...].forEach { $0.removeFromSuperview() }
        }
    }
}

private extension IFCollectionViewCell {
    // MARK: - Image
    func configureImage(_ image: UIImage) {
        prepareStackView(numberOfImages: 1)
        (stackView.arrangedSubviews.first as? UIImageView)?.image = image
    }
    
    // MARK: - Video
    func configureVideo(thumbnails: [UIImage]) {
        prepareStackView(numberOfImages: thumbnails.count)
        
        thumbnails.enumerated().forEach { tuple in
            guard let imageView = stackView.arrangedSubviews[safe: tuple.offset] as? UIImageView else { return }
            
            UIView.transition(
                with: imageView,
                duration: Constants.videoThumbnailTransitionDuration,
                options: .transitionCrossDissolve,
                animations: { [weak imageView] in
                    imageView?.image = tuple.element
                },
                completion: nil)
        }
    }
    
    func reset() {
        videoIndicatorView.isHidden = true
        videoIndicatorView.frame.origin.x = -videoIndicatorView.frame.size.width / 2.0
        isAnimatingPlaybackLabelHidden = (false, false)
        needsVideoPlaybackLayout = true
        mediaManager?.videoPlaybackLabel.alpha = 0
        loadingTask = nil
    }
}

extension IFCollectionViewCell {
    func loadMedia(at index: Int, itemSize: CGSize, isPreview: Bool, completion: (() -> Void)? = nil) {
        reset()
        
        guard let mediaManager else { return }
        switch mediaManager.media[index].mediaType {
        case .image:
            loadingTask = mediaManager.loadImage(
                at: index,
                options: IFImage.LoadOptions(preferredSize: itemSize, kind: .thumbnail),
                completion: { [weak self] container in
                    self?.configureImage(container.image)
                    completion?()
                })
        case .video:
            let nestedTask = NestedTask()
            
            let generatorTask = mediaManager.videoThumbnailGenerator(at: index) { [weak mediaManager] generator in
                guard let mediaManager else { return }
                if isPreview {
                    switch mediaManager.videoStatus.value {
                    case .autoplay:
                        if let generator {
                            generator.generateAutoplayLastThumbnail { [weak mediaManager] thumb in
                                guard !nestedTask.isCancelled else { return }
                                let coverTask = mediaManager?.loadVideoCover(at: index) { [weak self] cover in
                                    guard let self else { return }
                                    self.configureVideo(thumbnails: [cover, thumb ?? cover])
                                    completion?()
                                }
                                
                                if let coverTask {
                                    nestedTask.addSubtask(coverTask)
                                }
                            }
                        } else {
                            let coverTask = mediaManager.loadVideoCover(at: index) { [weak self] image in
                                guard let self else { return }
                                self.configureVideo(thumbnails: [image, image])
                                completion?()
                            }
                            
                            if let coverTask {
                                nestedTask.addSubtask(coverTask)
                            }
                        }
                    case .autoplayPause, .autoplayEnded:
                        generator?.cancelAllImageGeneration()
                        let coverTask = mediaManager.loadVideoCover(at: index) { [weak self] image in
                            self?.configureImage(image)
                            completion?()
                        }
                        
                        if let coverTask {
                            nestedTask.addSubtask(coverTask)
                        }
                    case .play, .pause:
                        let coverTask = mediaManager.loadVideoCover(at: index) { [weak self, weak mediaManager] cover in
                            if let generator {
                                generator.generateImages(currentTime: mediaManager?.videoPlayback.value?.currentTime ?? .zero) { thumbnails in
                                    guard let self else { return }
                                    let thumbnails = (0..<generator.numberOfThumbnails).map { thumbnails[$0] ?? cover }
                                    self.configureVideo(thumbnails: thumbnails)
                                    completion?()
                                }
                            } else if let self {
                                self.configureVideo(thumbnails: [cover, cover].compactMap { $0 })
                                completion?()
                            }
                        }
                        
                        if let coverTask {
                            nestedTask.addSubtask(coverTask)
                        }
                    }
                } else {
                    generator?.cancelAllImageGeneration()
                    
                    let coverTask = mediaManager.loadVideoCover(at: index) { [weak self] image in
                        self?.configureImage(image)
                        completion?()
                    }
                    
                    if let coverTask {
                        nestedTask.addSubtask(coverTask)
                    }
                }
            }
            
            nestedTask.addSubtask(generatorTask)
            loadingTask = nestedTask
        case .pdf:
            loadingTask = mediaManager.loadPDFThumbnail(
                at: index,
                preferredSize: itemSize,
                completion: { [weak self] image in
                    self?.configureImage(image)
                    completion?()
                })
        }
    }
    
    func configureVideo(playback: IFVideo.Playback, showVideoIndicator: Bool, showPlaybackTime: Bool) {
        let progress = CGFloat(playback.progress)
        
        if let mediaManager, needsVideoPlaybackLayout {
            mediaManager.videoPlaybackLabel.text = playback.totalDuration.formattedProgress
            let videoPlaybackLabelIntrinsicSize = mediaManager.videoPlaybackLabel.intrinsicContentSize
            let videoPlaybackLabelInsets = UIEdgeInsets(top: 2, left: 12, bottom: 2, right: 12)
            
            let videoPlaybackLabelSize = CGSize(
                width: videoPlaybackLabelIntrinsicSize.width + videoPlaybackLabelInsets.left + videoPlaybackLabelInsets.right,
                height: videoPlaybackLabelIntrinsicSize.height + videoPlaybackLabelInsets.top + videoPlaybackLabelInsets.bottom
            )
            
            mediaManager.videoPlaybackLabel.frame = CGRect(
                x: mediaManager.videoPlaybackLabel.frame.origin.x + mediaManager.videoPlaybackLabel.frame.width / 2 - videoPlaybackLabelSize.width / 2,
                y: mediaManager.videoPlaybackLabel.frame.origin.y + mediaManager.videoPlaybackLabel.frame.height - videoPlaybackLabelSize.height,
                width: videoPlaybackLabelSize.width,
                height: videoPlaybackLabelSize.height)
            
            needsVideoPlaybackLayout = false
        }
        
        let videoProgressCenterX = bounds.width * progress
        videoIndicatorView.frame.origin.x = videoProgressCenterX - videoIndicatorView.frame.width / 2
        videoIndicatorView.isHidden = !showVideoIndicator
        mediaManager?.videoPlaybackLabel.text = playback.currentTime.formattedProgress
        
        if !isAnimatingPlaybackLabelHidden.isAnimating || isAnimatingPlaybackLabelHidden.hidden == showPlaybackTime {
            isAnimatingPlaybackLabelHidden = (true, !showPlaybackTime)
            mediaManager?.videoPlaybackLabel.layer.removeAllAnimations()

            UIView.animate(
                withDuration: showPlaybackTime ? Constants.videoPlaybackLabelShowTransitionDuration : Constants.videoPlaybackLabelHideTransitionDuration,
                delay: showPlaybackTime ? 0 : Constants.videoPlaybackLabelHideTransitionDelay,
                animations: { [weak self] in
                    self?.mediaManager?.videoPlaybackLabel.alpha = showPlaybackTime ? 1 : 0
                }, completion: { [weak self] _ in
                    self?.isAnimatingPlaybackLabelHidden = (false, !showPlaybackTime)
                }
            )
        }
    }
}

extension IFCollectionViewCell: IFImageContainerProvider {
    var imageContainerView: UIView {
        contentView
    }
}
