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

protocol IFCollectionViewControllerDelegate: class {
    func collectionViewController(_ collectionViewController: IFCollectionViewController, didSelectItemAt index: Int)
    func collectionViewControllerWillBeginScrolling(_ collectionViewController: IFCollectionViewController)
}

class IFCollectionViewController: UIViewController {
    private struct Constants {
        static let carouselScrollingTransitionDuration: TimeInterval = 0.34
        static let carouselTransitionDuration: TimeInterval = 0.16
        static let carouselSelectionDuration: TimeInterval = 0.22
        static let flowTransitionDuration: TimeInterval = 0.24
    }
    
    enum PendingInvalidation {
        case bouncing
        case dragging(targetIndexPath: IndexPath)
    }
    
    // MARK: - View
    private lazy var collectionView: IFCollectionView = {
        let initialIndexPath = IndexPath(item: imageManager.displayingImageIndex, section: 0)
        let layout = IFCollectionViewFlowLayout(centerIndexPath: initialIndexPath, needsInitialContentOffset: true)
        let view = IFCollectionView(frame: .zero, collectionViewLayout: layout)
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
    private let bouncer = IFScrollViewBouncingManager()
    private var pendingInvalidation: PendingInvalidation?
    
    private var collectionViewLayout: IFCollectionViewFlowLayout {
        //swiftlint:disable:next force_cast
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
    
    deinit {
        prefetcher.stopPreheating()
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
        prefetcher.stopPreheating()
    }
    
    // MARK: - Public methods
    func scroll(toItemAt index: Int, progress: CGFloat = 1) {
        guard isViewLoaded else { return }
        
        if collectionView.isDecelerating {
            updateCollectionViewLayout(style: .carousel)
        } else {
            let transitionIndexPath = IndexPath(item: index, section: 0)
            updateCollectionViewLayout(transitionIndexPath: transitionIndexPath, progress: progress)
        }
    }
    
    func scroll(toItemAt index: Int, animated: Bool) {
        guard collectionViewLayout.isTransitioning || collectionViewLayout.centerIndexPath.item != index else { return }
        updateCollectionViewLayout(style: .carousel)
    }
    
    func removeDisplayingImage() {
        guard let cell = collectionView.cellForItem(at: collectionViewLayout.centerIndexPath) else { return }
        let currentIndexPath = collectionViewLayout.centerIndexPath
        collectionViewLayout.update(centerIndexPath: IndexPath(item: imageManager.displayingImageIndex, section: 0))
        
        if let cell = cell as? IFImageContainerProvider {
            cell.prepareForRemove { self.collectionView.deleteItems(at: [currentIndexPath]) }
        } else {
            collectionView.deleteItems(at: [currentIndexPath])
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
        bouncer.startObserving(scrollView: collectionView, bouncingDirections: [.left, .right])
        bouncer.delegate = self
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
    
    @discardableResult private func updatedisplayingImageIndexIfNeeded(with index: Int) -> Bool {
        guard imageManager.displayingImageIndex != index else { return false }
        imageManager.updatedisplayingImage(index: index)
        collectionViewLayout.update(centerIndexPath: IndexPath(item: index, section: 0))
        delegate?.collectionViewController(self, didSelectItemAt: index)
        return true
    }

    private func updateCollectionViewLayout(style: IFCollectionViewFlowLayout.Style) {
        let indexPath = IndexPath(item: imageManager.displayingImageIndex, section: 0)
        let layout = IFCollectionViewFlowLayout(style: style, centerIndexPath: indexPath)
        let duration: TimeInterval
        
        switch pendingInvalidation {
        case .dragging:
            duration = Constants.carouselScrollingTransitionDuration
        default:
            duration = style == .carousel ? Constants.carouselTransitionDuration : Constants.flowTransitionDuration
        }
        
        pendingInvalidation = nil
        UIView.transition(
            with: collectionView,
            duration: duration,
            options: .curveEaseOut,
            animations: {
                if #available(iOS 13.0, *) {
                    self.collectionView.setCollectionViewLayout(layout, animated: true)
                } else {
                    self.collectionView.setCollectionViewLayout(layout, animated: true)
                    self.collectionView.layoutIfNeeded()
                }
        })
    }
    
    private func updateCollectionViewLayout(transitionIndexPath: IndexPath, progress: CGFloat) {
        let indexPath = IndexPath(item: imageManager.displayingImageIndex, section: 0)
        let layout = IFCollectionViewFlowLayout(centerIndexPath: indexPath)
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
    
    @objc private func pangestureDidChange(_ sender: UIPanGestureRecognizer) {
        switch sender.state {
        case .cancelled,
             .ended where pendingInvalidation == nil:
            updateCollectionViewLayout(style: .carousel)
        default:
            break
        }
    }
}

extension IFCollectionViewController: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        imageManager.images.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: IFCollectionViewCell.identifier, for: indexPath)
        if let cell = cell as? IFCollectionViewCell {
            imageManager.loadImage(
                at: indexPath.item,
                options: IFImage.LoadOptions(preferredSize: collectionViewLayout.itemSize, kind: .thumbnail),
                sender: cell) { [weak self] result in
                    guard let self = self, case .success = result else { return }
                    self.updateCollectionViewLayout(forPreferredSizeAt: indexPath)
            }
        }
        return cell
    }
}

extension IFCollectionViewController: UICollectionViewDataSourcePrefetching {
    func collectionView(_ collectionView: UICollectionView, prefetchItemsAt indexPaths: [IndexPath]) {
        guard collectionView.isDragging || collectionView.isDecelerating else { return }
        let urls = indexPaths.compactMap { imageManager.images[safe: $0.item]?.thumbnail?.url }
        prefetcher.startPreheating(with: urls)
    }
    
    func collectionView(_ collectionView: UICollectionView, cancelPrefetchingForItemsAt indexPaths: [IndexPath]) {
        let urls = indexPaths.compactMap { imageManager.images[safe: $0.item]?.thumbnail?.url }
        prefetcher.stopPreheating(with: urls)
    }
}

extension IFCollectionViewController: IFCollectionViewDelegate {
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        guard scrollView.isDragging, !collectionViewLayout.isTransitioning else { return }
        let centerIndexPath = collectionViewLayout.indexPath(forContentOffset: collectionView.contentOffset)
        guard
            updatedisplayingImageIndexIfNeeded(with: centerIndexPath.item),
            case .dragging(let targetIndexPath) = pendingInvalidation,
            targetIndexPath == centerIndexPath else { return }
        updateCollectionViewLayout(style: .carousel)
    }
    
    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        pendingInvalidation = nil
        guard collectionViewLayout.style == .carousel else { return }
        let contentOffset = collectionView.contentOffset
        updateCollectionViewLayout(style: .flow)
        let updatedContentOffset = collectionView.contentOffset
        collectionView.panGestureRecognizer.setTranslation(CGPoint(x: contentOffset.x - updatedContentOffset.x, y: 0), in: collectionView)
        delegate?.collectionViewControllerWillBeginScrolling(self)
    }
    
    func scrollViewWillEndDragging(_ scrollView: UIScrollView, withVelocity velocity: CGPoint, targetContentOffset: UnsafeMutablePointer<CGPoint>) {
        guard velocity.x != 0 else { return }
        let minimumContentOffsetX = -scrollView.contentInset.left.rounded(.up)
        let maximumContentOffsetX = (scrollView.contentSize.width - scrollView.bounds.width + scrollView.contentInset.right).rounded(.down)
        if targetContentOffset.pointee.x > minimumContentOffsetX, targetContentOffset.pointee.x < maximumContentOffsetX {
            let targetIndexPath = collectionViewLayout.indexPath(forContentOffset: targetContentOffset.pointee)
            pendingInvalidation = .dragging(targetIndexPath: targetIndexPath)
        } else {
            pendingInvalidation = .bouncing
        }
    }
    
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        guard pendingInvalidation != nil else { return }
        let centerIndexPath = collectionViewLayout.indexPath(forContentOffset: collectionView.contentOffset)
        updatedisplayingImageIndexIfNeeded(with: centerIndexPath.item)
        updateCollectionViewLayout(style: .carousel)
    }
    
    func collectionView(_ collectionView: UICollectionView, touchBegan itemIndexPath: IndexPath?) {
        guard collectionViewLayout.isTransitioning else { return }
        updateCollectionViewLayout(style: .carousel)
        delegate?.collectionViewControllerWillBeginScrolling(self)
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard updatedisplayingImageIndexIfNeeded(with: indexPath.item) else { return }

        UIView.transition(
            with: collectionView,
            duration: Constants.carouselSelectionDuration,
            options: .curveEaseOut,
            animations: {
                self.collectionViewLayout.setupTransition(to: indexPath)
                self.collectionViewLayout.invalidateLayout()
                self.collectionView.layoutIfNeeded()
            })
    }
}

extension IFCollectionViewController: IFScrollViewBouncingDelegate {
    func scrollView(_ scrollView: UIScrollView, didReverseBouncing direction: UIScrollView.BouncingDirection) {
        let indexPath: IndexPath
        switch direction {
        case .left:
            indexPath = IndexPath(item: 0, section: 0)
        case .right:
            indexPath = IndexPath(item: imageManager.images.count - 1, section: 0)
        default:
            return
        }
        updatedisplayingImageIndexIfNeeded(with: indexPath.item)
        updateCollectionViewLayout(style: .carousel)
    }
}
