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
    func collectionViewControllerWillBeginScrolling(_ collectionViewController: IFCollectionViewController)
}

#warning("Add constants to allow property animator timing and duration")
class IFCollectionViewController: UIViewController {
    private struct Constants {
        static let layoutTransitionDuration = 0.28
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
            $0.constant = -collectionViewLayout.preferredOffBoundsPadding
        }
    }
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        collectionViewLayout.invalidateLayout()
        super.viewWillTransition(to: size, with: coordinator)
    }
    
    // MARK: - Public methods
    func scroll(toItemAt index: Int, progress: CGFloat = 1) {
        guard isViewLoaded else { return }
        
        if collectionView.isDecelerating {
            invalidateLayout(style: .carousel)
        } else {
            let transitionIndexPath = IndexPath(item: index, section: 0)
            invalidateLayout(transitionIndexPath: transitionIndexPath, progress: progress)
        }
        print("pageViewController invalidation")
    }
    
    func scroll(toItemAt index: Int, animated: Bool) {
        guard collectionViewLayout.isTransitioning || collectionViewLayout.centerIndexPath.item != index else { return }
        invalidateLayout(style: .carousel)
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
    
    @discardableResult private func updatedisplayingImageIndexIfNeeded(with index: Int) -> Bool {
        guard imageManager.displayingImageIndex != index else { return false }
        imageManager.updatedisplayingImage(index: index)
        collectionViewLayout.update(centerIndexPath: IndexPath(item: index, section: 0))
        delegate?.collectionViewController(self, didSelectItemAt: index)
        return true
    }

    private func invalidateLayout(style: IFCollectionViewFlowLayout.Style) {
        pendingInvalidation = nil
        let indexPath = IndexPath(item: imageManager.displayingImageIndex, section: 0)
        let layout = IFCollectionViewFlowLayout(centerIndexPath: indexPath)
        layout.style = style
        UIView.transition(
            with: collectionView,
            duration: Constants.layoutTransitionDuration,
            options: .curveEaseOut,
            animations: { self.collectionView.setCollectionViewLayout(layout, animated: true) },
            completion: nil)
    }
    
    private func invalidateLayout(transitionIndexPath: IndexPath, progress: CGFloat) {
        let indexPath = IndexPath(item: imageManager.displayingImageIndex, section: 0)
        let layout = IFCollectionViewFlowLayout(centerIndexPath: indexPath)
        layout.style = collectionViewLayout.style
        layout.setupTransition(to: transitionIndexPath, progress: progress)
        collectionView.setCollectionViewLayout(layout, animated: false)
    }
    
    private func invalidateLayout(forPreferredImageAt index: Int) {
        guard
            pendingInvalidation == nil,
            imageManager.displayingImageIndex == index,
            collectionViewLayout.style == .carousel,
            collectionViewLayout.isTransitioning == false else { return }
        invalidateLayout(style: .carousel)
        print("cellForItemAt invalidation")
    }
    
    @objc private func pangestureDidChange(_ sender: UIPanGestureRecognizer) {
        switch sender.state {
        case .cancelled,
             .ended where pendingInvalidation == nil:
            let indexPath = IndexPath(item: imageManager.displayingImageIndex, section: 0)
            let flowLayout = IFCollectionViewFlowLayout(centerIndexPath: indexPath)
            flowLayout.style = .carousel
            UIView.transition(
                with: collectionView,
                duration: Constants.layoutTransitionDuration,
                options: .curveEaseOut,
                animations: { self.collectionView.setCollectionViewLayout(flowLayout, animated: true) },
                completion: nil)
            print("pangestureDidChange invalidation")
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
                preferredSize: collectionViewLayout.itemSize,
                kind: .thumbnail,
                sender: cell) { [weak self] result in
                    guard case .success = result else { return }
                    self?.invalidateLayout(forPreferredImageAt: indexPath.item)
            }
        }
        return cell
    }
}

extension IFCollectionViewController: UICollectionViewDataSourcePrefetching {
    func collectionView(_ collectionView: UICollectionView, prefetchItemsAt indexPaths: [IndexPath]) {
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
        invalidateLayout(style: .carousel)
        print("scrollViewDidScroll invalidation")
    }
    
    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        pendingInvalidation = nil
        guard collectionViewLayout.style == .carousel else { return }
        let contentOffset = collectionView.contentOffset
        invalidateLayout(style: .flow)
        let updatedContentOffset = collectionView.contentOffset
        collectionView.panGestureRecognizer.setTranslation(CGPoint(x: contentOffset.x - updatedContentOffset.x, y: 0), in: collectionView)
        delegate?.collectionViewControllerWillBeginScrolling(self)
        print("scrollViewWillBeginDragging invalidation")
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
        print("velocity: \(velocity)")
        #warning("Setting threshold to avoid flow layout backpressure")
//        if velocity.x > 123 {
//            animator.finishRunningAnimation(at: .end)
//        }
    }
    
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        guard pendingInvalidation != nil else { return }
        let centerIndexPath = collectionViewLayout.indexPath(forContentOffset: collectionView.contentOffset)
        updatedisplayingImageIndexIfNeeded(with: centerIndexPath.item)
        invalidateLayout(style: .carousel)
        print("didEndDecelerating invalidation")
    }
    
    func collectionView(_ collectionView: UICollectionView, touchBegan itemIndexPath: IndexPath?) {
        guard collectionViewLayout.isTransitioning else { return }
        invalidateLayout(style: .carousel)
        delegate?.collectionViewControllerWillBeginScrolling(self)
        print("touchBegan invalidation")
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard updatedisplayingImageIndexIfNeeded(with: indexPath.item) else { return }
        invalidateLayout(style: .carousel)
        print("didSelectItemAt invalidation")
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
        invalidateLayout(style: .carousel)
        print("didReverseBouncing invalidation")
    }
}
