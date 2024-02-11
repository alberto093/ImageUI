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
    
    private(set) var videoStatus: IFVideo.Status?
    
    // MARK: - Lifecycle
    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        imageContainerView.alpha = 1
        imageContainerView.transform = .identity
        stackView.arrangedSubviews.forEach { $0.removeFromSuperview() }
        videoIndicatorView.isHidden = true
        videoIndicatorView.frame.origin.x = -videoIndicatorView.frame.size.width / 2.0
        videoStatus = nil
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        videoIndicatorView.frame.size.height = bounds.height - Constants.videoIndicatorBorderWidth
        videoIndicatorViewBorderLayer.frame.size.height = bounds.height + Constants.videoIndicatorBorderWidth
    }
    
    override func preferredLayoutAttributesFitting(_ layoutAttributes: UICollectionViewLayoutAttributes) -> UICollectionViewLayoutAttributes {
        switch videoStatus {
        case .autoplay:
            layoutAttributes.size.width = Constants.videoAutoplayThumbnailWidth * 2
        case .play, .pause:
            let thumbWidth = layoutAttributes.size.height * Constants.videoPlayThumbnailAspectRatio
            layoutAttributes.size.width = thumbWidth * CGFloat(stackView.arrangedSubviews.count)
        case .autoplayPause, .autoplayEnded, .none:
            if let image = (stackView.arrangedSubviews.first as? UIImageView)?.image, image.size.height != 0 {
                let imageRatio = image.size.width / image.size.height
                layoutAttributes.size.width = layoutAttributes.size.height * imageRatio
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
    
    func configureVideo(thumbnails: [UIImage], videoStatus: IFVideo.Status) {
        prepareStackView(numberOfImages: thumbnails.count)
        
        thumbnails.enumerated().forEach { tuple in
            guard let imageView = stackView.arrangedSubviews[safe: tuple.offset] as? UIImageView else { return }
            
            UIView.transition(
                with: imageView,
                duration: Constants.videoThumbnailTransitionDuration,
                options: .transitionCrossDissolve,
                animations: {
                    imageView.image = tuple.element
                },
                completion: nil)
        }
        
        self.videoStatus = videoStatus
    }
    
    func configureVideoIndicator(progress: Double, isHidden: Bool) {
        videoIndicatorView.frame.origin.x = bounds.width * CGFloat(progress) - videoIndicatorView.frame.size.width / 2
        videoIndicatorView.isHidden = isHidden
    }
}

extension IFCollectionViewCell: Nuke_ImageDisplaying {
    func nuke_display(image: Nuke.PlatformImage?, data: Data?) {
        prepareStackView(numberOfImages: 1)
        (stackView.arrangedSubviews.first as? UIImageView)?.image = image
        videoIndicatorView.isHidden = true
    }
}

extension IFCollectionViewCell: IFImageContainerProvider {
    var imageContainerView: UIView {
        contentView
    }
}
