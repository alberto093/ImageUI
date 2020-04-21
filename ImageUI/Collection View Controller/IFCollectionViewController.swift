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

import Nuke

protocol IFCollectionViewControllerDelegate: class {
    func collectionViewController(_ collectionViewController: IFCollectionViewController, didSelectItemAt index: Int)
}

class IFCollectionViewController: UIViewController {
    // MARK: - View
    private struct Constants {
        static let layoutTransitionDuration: TimeInterval = 0.24
        static let layoutTransitionRate: UIScrollView.DecelerationRate = .normal
    }
    
    private let collectionView: UICollectionView = {
        let view = UICollectionView(frame: .zero, collectionViewLayout: IFCollectionViewFlowLayout())
        view.backgroundColor = .clear
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private var horizontalConstraints: [NSLayoutConstraint] = []
    
    // MARK: - Public properties
    weak var delegate: IFCollectionViewControllerDelegate?
    let imageManager: IFImageManager
    
    // MARK: - Accessory properties
    private let prefetcher = ImagePreheater()
    private var needsInitialContentOffset = true
    private var pendingLayoutInvalidation: DispatchWorkItem? {
        didSet { oldValue?.cancel() }
    }
    
    private var flowLayout: IFCollectionViewFlowLayout {
        collectionView.collectionViewLayout as! IFCollectionViewFlowLayout
    }
    
    // MARK: - Initializer
    init(imageManager: IFImageManager) {
        self.imageManager = imageManager
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        self.imageManager = IFImageManager(images: [])
        super.init(coder: coder)
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
        horizontalConstraints.forEach {
            $0.constant = -flowLayout.preferredOffBoundsPadding
        }
    }
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        flowLayout.invalidateLayout()
        super.viewWillTransition(to: size, with: coordinator)
    }
    
    // MARK: - Public methods
    func scroll(toItemAt index: Int, progress: CGFloat) {
        guard isViewLoaded else { return }
        
        if collectionView.isDecelerating {
            collectionView.setContentOffset(collectionView.contentOffset, animated: false)
            invalidateLayout(style: .preview)
        } else {
            flowLayout.invalidateLayoutIfNeeded(forTransitionIndexPath: IndexPath(item: index, section: 0), progress: progress)
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
        flowLayout.centerIndexPath = IndexPath(item: imageManager.dysplaingImageIndex, section: 0)
    }

    private func invalidateLayout(style: IFCollectionViewFlowLayout.Style) {
        pendingLayoutInvalidation = nil

        UIView.transition(
            with: collectionView,
            duration: Constants.layoutTransitionDuration,
            options: [.curveEaseInOut, .allowUserInteraction, .beginFromCurrentState],
            animations: { [weak self] in
                guard let self = self else { return }
                let centerIndexPath = IndexPath(item: self.imageManager.dysplaingImageIndex, section: 0)
                self.flowLayout.invalidateLayout(with: style, centerIndexPath: centerIndexPath)
            }, completion: nil)
    }
    
    private func invalidateLayout(with indexPath: IndexPath, delay: TimeInterval = 0) {
        let pendingLayoutInvalidation = DispatchWorkItem { [weak self] in
            self?.imageManager.dysplaingImageIndex = indexPath.item
            self?.invalidateLayout(style: .preview)
        }
        
        if delay > 0 {
            self.pendingLayoutInvalidation = pendingLayoutInvalidation
            DispatchQueue.main.asyncAfter(deadline: .now() + delay, execute: pendingLayoutInvalidation)
        } else {
            DispatchQueue.main.async(execute: pendingLayoutInvalidation)
        }
    }
}

extension IFCollectionViewController: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        imageManager.images.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: IFCollectionViewCell.identifier, for: indexPath)
        if let cell = cell as? IFCollectionViewCell, let url = imageManager.images[safe: indexPath.item]?.url {
            let request = ImageRequest(
                url: url,
                processors: [ImageProcessor.Resize(size: flowLayout.itemSize)],
                priority: indexPath.item == imageManager.dysplaingImageIndex ? .high : .normal)
            var options = ImageLoadingOptions(transition: .fadeIn(duration: 0.1))
            options.pipeline = imageManager.pipeline
            loadImage(with: request, options: options, into: cell.imageView) { [weak self] result in
                guard
                    case .success = result,
                    let index = collectionView.indexPath(for: cell)?.item,
                    self?.imageManager.dysplaingImageIndex == index,
                    self?.flowLayout.style == .preview else { return }
                self?.invalidateLayout(style: .preview)
            }
        }
        return cell
    }
}

extension IFCollectionViewController: UICollectionViewDataSourcePrefetching {
    func collectionView(_ collectionView: UICollectionView, prefetchItemsAt indexPaths: [IndexPath]) {
        let urls = indexPaths.compactMap { imageManager.images[safe: $0.item]?.url }
        prefetcher.startPreheating(with: urls)
    }
    
    func collectionView(_ collectionView: UICollectionView, cancelPrefetchingForItemsAt indexPaths: [IndexPath]) {
        let urls = indexPaths.compactMap { imageManager.images[safe: $0.item]?.url }
        prefetcher.stopPreheating(with: urls)
    }
}

extension IFCollectionViewController: UICollectionViewDelegate {
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        guard collectionView.isDragging else { return }
        let centerIndexPath = flowLayout.indexPath(forContentOffset: collectionView.contentOffset)
        guard imageManager.dysplaingImageIndex != centerIndexPath.item else { return }
        imageManager.dysplaingImageIndex = centerIndexPath.item
        delegate?.collectionViewController(self, didSelectItemAt: centerIndexPath.item)
    }
    
    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        pendingLayoutInvalidation = nil
        invalidateLayout(style: .normal)
    }
    
    func scrollViewWillEndDragging(_ scrollView: UIScrollView, withVelocity velocity: CGPoint, targetContentOffset: UnsafeMutablePointer<CGPoint>) {
        let offsetX = CGFloat(signOf: velocity.x, magnitudeOf: flowLayout.itemSize.width)
        let preferredContentOffset = CGPoint(x: targetContentOffset.pointee.x + offsetX, y: targetContentOffset.pointee.y)
        let targetIndexPath = flowLayout.indexPath(forContentOffset: preferredContentOffset)
        let scrollDuration = collectionView.scrollDuration(velocity: velocity)
        let transitionOffset = (1 - TimeInterval(Constants.layoutTransitionRate.rawValue)) * Constants.layoutTransitionDuration
        let delay = scrollDuration - (Constants.layoutTransitionDuration + transitionOffset)
        invalidateLayout(with: targetIndexPath, delay: collectionView.isBouncingHorizontally ? 0 : delay)
    }
    
    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        guard !decelerate, pendingLayoutInvalidation == nil else { return }
        let targetIndexPath = flowLayout.indexPath(forContentOffset: collectionView.contentOffset)
        invalidateLayout(with: targetIndexPath)
    }
    
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        guard pendingLayoutInvalidation != nil else { return }
        let targetIndexPath = flowLayout.indexPath(forContentOffset: collectionView.contentOffset)
        invalidateLayout(with: targetIndexPath)
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard imageManager.dysplaingImageIndex != indexPath.item else { return }
        invalidateLayout(with: indexPath)
        delegate?.collectionViewController(self, didSelectItemAt: indexPath.item)
    }
}
