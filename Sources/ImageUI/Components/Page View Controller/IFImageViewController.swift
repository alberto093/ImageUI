//
//  IFImageViewController.swift
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

class IFImageViewController: UIViewController {
    private struct Constants {
        static let minimumMaximumZoomFactor: CGFloat = 3
        static let doubleTapZoomMultiplier: CGFloat = 0.85
        static let preferredAspectFillRatio: CGFloat = 0.9
    }
    
    // MARK: - View
    private let scrollView: UIScrollView = {
        let view = UIScrollView()
        view.showsVerticalScrollIndicator = false
        view.showsHorizontalScrollIndicator = false
        view.translatesAutoresizingMaskIntoConstraints = false
        view.contentInsetAdjustmentBehavior = .never
        return view
    }()
    
    private let imageView: UIImageView = {
        let view = UIImageView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.isUserInteractionEnabled = true
        return view
    }()
    
    // MARK: - Public properties
    let imageManager: IFImageManager
    var displayingImageIndex: Int {
        didSet {
            guard displayingImageIndex != oldValue else { return }
            update()
        }
    }
    
    // MARK: - Accessory properties
    private var aspectFillZoom: CGFloat = 1
    private var needsFirstLayout = true
    
    // MARK: - Initializer
    public init(imageManager: IFImageManager, displayingImageIndex: Int? = nil) {
        self.imageManager = imageManager
        self.displayingImageIndex = displayingImageIndex ?? imageManager.displayingImageIndex
        super.init(nibName: nil, bundle: nil)
    }
    
    public required init?(coder: NSCoder) {
        self.imageManager = IFImageManager(images: [])
        self.displayingImageIndex = 0
        super.init(coder: coder)
    }
    
    // MARK: - Lifecycle
    override func loadView() {
        view = UIView()
        view.addSubview(scrollView)
        scrollView.addSubview(imageView)
        
        NSLayoutConstraint.activate([
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.topAnchor.constraint(equalTo: view.topAnchor),
            imageView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            imageView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            imageView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            imageView.topAnchor.constraint(equalTo: scrollView.topAnchor)])
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setup()
        update()
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        scrollView.zoomScale = scrollView.minimumZoomScale
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        if needsFirstLayout {
            needsFirstLayout = false
            updateScrollView()
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
    
    private func setup() {
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(imageViewDidDoubleTap))
        tapGesture.numberOfTapsRequired = 2
        imageView.addGestureRecognizer(tapGesture)
        scrollView.delegate = self
        scrollView.decelerationRate = .fast
        scrollView.contentInsetAdjustmentBehavior = .never
    }
    
    private func update() {
        guard isViewLoaded else { return }
        UIView.performWithoutAnimation {
            imageManager.loadImage(at: displayingImageIndex, options: IFImage.LoadOptions(kind: .original), sender: imageView) { [weak self] _ in
                self?.updateScrollView()
            }
        }
    }
    
    private func updateScrollView(resetZoom: Bool = true) {
        guard let image = imageView.image, image.size.width > 0, image.size.height > 0, view.frame != .zero else {
            return
        }
        
        let aspectFitZoom = min(view.frame.width / image.size.width, view.frame.height / image.size.height)
        aspectFillZoom = max(view.frame.width / image.size.width, view.frame.height / image.size.height)
        let zoomMultiplier = (scrollView.zoomScale - scrollView.minimumZoomScale) / (scrollView.maximumZoomScale - scrollView.minimumZoomScale)

        let minimumZoomScale: CGFloat
        if imageManager.prefersAspectFillZoom, aspectFitZoom / aspectFillZoom >= Constants.preferredAspectFillRatio {
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
        guard let image = imageView.image else { return }
        scrollView.contentInset.top = max((scrollView.frame.height - image.size.height * scrollView.zoomScale) / 2, 0)
        scrollView.contentInset.left = max((scrollView.frame.width - image.size.width * scrollView.zoomScale) / 2, 0)
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
    
    // MARK: - UI Actions
    @objc private func imageViewDidDoubleTap(_ sender: UITapGestureRecognizer) {
        switch scrollView.zoomScale {
        case scrollView.minimumZoomScale:
            let tapLocation = sender.location(in: imageView)
            let targetZoomScale = max(aspectFillZoom, scrollView.maximumZoomScale * Constants.doubleTapZoomMultiplier)
            let zoomWidth = scrollView.bounds.width / targetZoomScale
            let zoomHeight = scrollView.bounds.height / targetZoomScale
            let zoomRect = CGRect(x: tapLocation.x - zoomWidth / 2, y: tapLocation.y - zoomHeight / 2, width: zoomWidth, height: zoomHeight)
            scrollView.zoom(to: zoomRect, animated: true)
        default:
            scrollView.setZoomScale(scrollView.minimumZoomScale, animated: true)
        }
    }
}

extension IFImageViewController: UIScrollViewDelegate {
    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        imageView
    }
    
    func scrollViewDidZoom(_ scrollView: UIScrollView) {
        updateContentInset()
    }
}

extension IFImageViewController: IFImageContainerProvider {
    var imageContainerView: UIView {
        scrollView
    }
}
