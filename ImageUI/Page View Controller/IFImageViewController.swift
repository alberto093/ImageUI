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

import Nuke

class IFImageViewController: UIViewController {
    private struct Constants {
        static let minimumMaximumZoomFactor: CGFloat = 3
        static let doubleTapZoomMultiplier: CGFloat = 0.85
        static let maxImageSize: CGSize = {
            let maxSize = max(UIScreen.main.nativeBounds.width, UIScreen.main.nativeBounds.height)
            return CGSize(width: maxSize, height: maxSize)
        }()
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
        didSet { update() }
    }
    
    // MARK: - Accessory properties
    private var aspectFillZoom: CGFloat = 1
    
    // MARK: - Initializer
    public init(imageManager: IFImageManager, displayingImageIndex: Int? = nil) {
        self.imageManager = imageManager
        self.displayingImageIndex = displayingImageIndex ?? imageManager.dysplaingImageIndex
        super.init(nibName: nil, bundle: nil)
    }
    
    public required init?(coder: NSCoder) {
        self.imageManager = IFImageManager(images: [])
        self.displayingImageIndex = 0
        super.init(nibName: nil, bundle: nil)
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
        updateScrollView()
    }
    
    private func setup() {
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(imageViewDidDoubleTap))
        tapGesture.numberOfTapsRequired = 2
        imageView.addGestureRecognizer(tapGesture)
        scrollView.delegate = self
        scrollView.decelerationRate = .fast
    }
    
    private func update() {
        guard isViewLoaded, let url = imageManager.images[safe: displayingImageIndex]?.url else { return }
        let request = ImageRequest(url: url, processors: [], priority: .veryHigh)
        var options = ImageLoadingOptions(transition: .fadeIn(duration: 0.1))
        options.pipeline = imageManager.pipeline
        loadImage(with: request, options: options, into: imageView) { [weak self] result in
            self?.updateScrollView()
        }
    }
    
    private func updateScrollView() {
        guard let image = imageView.image else { return }
        let aspectFitZoom = min(scrollView.frame.width / image.size.width, scrollView.frame.height / image.size.height)
        aspectFillZoom = max(scrollView.frame.width / image.size.width, scrollView.frame.height / image.size.height)
        scrollView.minimumZoomScale = aspectFitZoom
        scrollView.maximumZoomScale = max(aspectFitZoom * Constants.minimumMaximumZoomFactor, aspectFillZoom, 1 / UIScreen.main.scale)
        UIView.performWithoutAnimation {
            scrollView.zoomScale = aspectFitZoom
            scrollView.contentInset.top = (scrollView.frame.height - image.size.height * aspectFitZoom) / 2
            scrollView.contentInset.left = (scrollView.frame.width - image.size.width * aspectFitZoom) / 2
        }
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
        scrollView.contentInset.top = max((scrollView.frame.height - imageView.frame.height) / 2, 0)
        scrollView.contentInset.left = max((scrollView.frame.width - imageView.frame.width) / 2, 0)
    }
}
