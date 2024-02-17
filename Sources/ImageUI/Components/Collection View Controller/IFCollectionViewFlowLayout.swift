//
//  IFCollectionViewFlowLayout.swift
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

class IFCollectionViewFlowLayout: UICollectionViewFlowLayout {
    enum Style {
        case carousel
        case flow
    }
    
    struct Transition {
        let indexPath: IndexPath
        let progress: CGFloat
        
        init(indexPath: IndexPath, progress: CGFloat = 1) {
            self.indexPath = indexPath
            self.progress = progress
        }
    }
    
    // MARK: - Public properties
    let mediaManager: IFMediaManager
    
    var style: Style
    private(set) var centerIndexPath: IndexPath
    var verticalPadding: CGFloat = 1
    var minimumItemWidthMultiplier: CGFloat = 0.5
    var maximumItemWidthMultiplier: CGFloat = 34 / 9
    var maximumLineSpacingMultiplier: CGFloat = 0.28
    var playingVideoLineSpacing: CGFloat = 21
    
    var maximumItemWidth: CGFloat {
        itemSize.width * maximumItemWidthMultiplier
    }
    
    var preferredOffBoundsPadding: CGFloat {
        if let collectionView = collectionView {
            return collectionView.bounds.width / 4
        } else {
            return (maximumLineSpacing - minimumLineSpacing) * 2 + (maximumItemWidth - itemSize.width)
        }
    }
    
    var isTransitioning: Bool {
        transition.progress > 0 && transition.progress < 1
    }
    
    var isPlayingVideo: Bool {
        guard style == .carousel && mediaManager.media[centerIndexPath.item].mediaType.isVideo else { return false }
        
        switch mediaManager.videoStatus.value {
        case .autoplay, .play, .pause:
            return true
        case .autoplayEnded, .autoplayPause:
            return false
        }
    }
    
    // MARK: - Accessory properties
    private(set) var transition: Transition
    private var animatedLayoutAttributes: [IndexPath: UICollectionViewLayoutAttributes] = [:]
    private var deletingIndexPath: IndexPath?
    private var centerIndexPathBeforeUpdate: IndexPath?
    private var preferredItemsRatio: [IndexPath: CGFloat] = [:]
    private lazy var maximumLineSpacing = minimumLineSpacing
    private var needsInitialContentOffset: Bool
    
    override var collectionViewContentSize: CGSize {
        var flowLayoutContentSize = super.collectionViewContentSize
        
        if style == .carousel {
            flowLayoutContentSize.width = flowLayoutContentSize.width - itemSize.width + preferredSize(forItemAt: centerIndexPath).width
        }
        
        return flowLayoutContentSize
    }
    
    init(mediaManager: IFMediaManager, style: Style = .carousel, centerIndexPath: IndexPath, needsInitialContentOffset: Bool = false) {
        self.mediaManager = mediaManager
        self.style = style
        self.centerIndexPath = centerIndexPath
        self.needsInitialContentOffset = needsInitialContentOffset
        transition = Transition(indexPath: centerIndexPath)
        super.init()
        setup()
    }
    
    required init?(coder: NSCoder) {
        mediaManager = IFMediaManager(media: [])
        style = .carousel
        centerIndexPath = IndexPath(item: 0, section: 0)
        needsInitialContentOffset = false
        transition = Transition(indexPath: centerIndexPath)
        super.init(coder: coder)
        setup()
    }
    
    private func setup() {
        minimumLineSpacing = 1
        scrollDirection = .horizontal
    }
}

extension IFCollectionViewFlowLayout {
    // MARK: - Public methods
    func indexPath(forContentOffset contentOffset: CGPoint) -> IndexPath {
        let itemsRange = (0...(collectionView.map { $0.numberOfItems(inSection: 0) - 1 } ?? 0))
        let itemIndex = (contentOffset.x + minimumLineSpacing / 2) / (itemSize.width + minimumLineSpacing)
        let normalizedIndex = Int(itemIndex).clamped(to: itemsRange)
        return IndexPath(item: normalizedIndex, section: 0)
    }
    
    func shouldInvalidateLayout(forPreferredItemSizeAt indexPath: IndexPath) -> Bool {
        guard indexPath == centerIndexPath, style == .carousel, !isTransitioning else { return false }
        let previousRatio = preferredItemsRatio[indexPath]
        updatePreferredItemSize()
        
        if let previousRatio, let newRatio = preferredItemsRatio[indexPath] {
            return abs(previousRatio - newRatio) > 0.01
        } else {
            return true
        }
    }
    
    func update(centerIndexPath: IndexPath, shouldInvalidate: Bool = false) {
        self.centerIndexPath = centerIndexPath
        self.transition = Transition(indexPath: centerIndexPath)
        updatePreferredItemSize()
        
        guard shouldInvalidate else { return }

        if let collectionView = collectionView {
            let context = UICollectionViewFlowLayoutInvalidationContext()
            context.contentOffsetAdjustment.x = contentOffsetX(forItemAt: centerIndexPath) - collectionView.contentOffset.x
            invalidateLayout(with: context)
        } else {
            invalidateLayout()
        }
    }
    
    func setupTransition(to indexPath: IndexPath, progress: CGFloat) {
        let progress = progress.clamped(to: 0...1)
        
        if progress == 1 {
            #warning("should invalidate?")
            update(centerIndexPath: indexPath)
        } else {
            transition = Transition(indexPath: indexPath, progress: progress)
            updatePreferredItemSize()
        }
    }
    
    func setupCellWidthAutoScroll(progress: Double) {
        collectionView?.contentOffset.x = contentOffsetX(forItemAt: centerIndexPath)
    }
    
    func contentOffsetX(forItemAt indexPath: IndexPath) -> CGFloat {
        let previousItemOffset = CGFloat(indexPath.item) * itemSize.width + CGFloat(indexPath.item - 1) * minimumLineSpacing

        switch style {
        case .flow:
            return previousItemOffset + minimumLineSpacing + itemSize.width / 2
        case .carousel:
            let itemOriginX = previousItemOffset + (isPlayingVideo ? playingVideoLineSpacing : maximumLineSpacing)
            let itemWidth = preferredSize(forItemAt: indexPath).width
            
            if mediaManager.videoStatus.value == .play || mediaManager.videoStatus.value == .pause, let videoProgress = mediaManager.videoPlayback.value?.progress {
                return itemOriginX + itemWidth * videoProgress
            } else {
                return itemOriginX + itemWidth / 2
            }
        }
    }
}

// MARK: - UICollectionViewFlowLayout - Overrides
extension IFCollectionViewFlowLayout {
    
    override func prepare() {
        update()
        setInitialContentOffsetIfNeeded()
        super.prepare()
    }
    
    override func layoutAttributesForElements(in rect: CGRect) -> [UICollectionViewLayoutAttributes]? {
        guard let collectionView else { return nil }
        
        var indexPaths: Set<IndexPath> = [centerIndexPath, transition.indexPath]
        
        let minimumPreviewingIndexPath = min(centerIndexPath, transition.indexPath)
        let maximumPreviewingIndexPath = max(centerIndexPath, transition.indexPath)
        let numberOfMiddleItems = abs(centerIndexPath.item - transition.indexPath.item) - 1
        
        if numberOfMiddleItems > 0 {
            for item in 1...numberOfMiddleItems {
                indexPaths.insert(IndexPath(item: minimumPreviewingIndexPath.item + item, section: 0))
            }
        }

        let cellsWidth = min(indexPaths.reduce(0) { $0 + size(forItemAt: $1).width }, collectionView.bounds.width / 2)
                
        let numberOfNormalAttributes = (collectionView.bounds.width - cellsWidth) / itemSize.width
        
        for item in 0..<Int(numberOfNormalAttributes) {
            let leftItem = minimumPreviewingIndexPath.item - item
            let rightItem = maximumPreviewingIndexPath.item + item
            
            if leftItem >= 0 {
                indexPaths.insert(IndexPath(item: leftItem, section: 0))
            }
            
            if rightItem < collectionView.numberOfItems(inSection: 0) {
                indexPaths.insert(IndexPath(item: rightItem, section: 0))
            }
        }
        
        return indexPaths.map {
            let attribute = UICollectionViewLayoutAttributes(forCellWith: $0)
            attribute.size = size(forItemAt: $0)
            attribute.frame.origin = CGPoint(x: originX(forItemAt: $0), y: verticalPadding)
            return attribute
        }
    }
    
    override func layoutAttributesForItem(at indexPath: IndexPath) -> UICollectionViewLayoutAttributes? {
        guard let superAttributes = super.layoutAttributesForItem(at: indexPath) else { return nil }
        guard let layoutAttributes = superAttributes.copy() as? UICollectionViewLayoutAttributes else { return superAttributes }
        layoutAttributes.size = size(forItemAt: layoutAttributes.indexPath)
        layoutAttributes.frame.origin = CGPoint(x: originX(forItemAt: layoutAttributes.indexPath), y: verticalPadding)
        return layoutAttributes
    }
    
    override func shouldInvalidateLayout(forBoundsChange newBounds: CGRect) -> Bool {
        let isSameSize = collectionView?.bounds.size == newBounds.size
        return !isSameSize || !animatedLayoutAttributes.isEmpty || deletingIndexPath != nil
    }
    
    override func shouldInvalidateLayout(
        forPreferredLayoutAttributes preferredAttributes: UICollectionViewLayoutAttributes,
        withOriginalAttributes originalAttributes: UICollectionViewLayoutAttributes) -> Bool {
        let oldRatio = preferredItemsRatio[preferredAttributes.indexPath]
        let newRatio = preferredAttributes.size.width / preferredAttributes.size.height
        preferredItemsRatio[preferredAttributes.indexPath] = newRatio
        return oldRatio != newRatio
    }
    
    override func invalidationContext(forPreferredLayoutAttributes preferredAttributes: UICollectionViewLayoutAttributes, withOriginalAttributes originalAttributes: UICollectionViewLayoutAttributes) -> UICollectionViewLayoutInvalidationContext {
        let context = UICollectionViewFlowLayoutInvalidationContext()
        switch originalAttributes.indexPath {
        case centerIndexPath, transition.indexPath:
            if let collectionView = collectionView, style == .carousel, !isTransitioning {
                context.contentOffsetAdjustment.x = contentOffsetX(forItemAt: centerIndexPath) - collectionView.contentOffset.x
            }
        default:
            break
        }
        
        return context
    }
    
    override func targetContentOffset(forProposedContentOffset proposedContentOffset: CGPoint, withScrollingVelocity velocity: CGPoint) -> CGPoint {
        guard let collectionView = collectionView, style == .flow else { return proposedContentOffset }
        let minimumContentOffsetX = -collectionView.contentInset.left.rounded(.up)
        let maximumContentOffsetX = (collectionView.contentSize.width - collectionView.bounds.width + collectionView.contentInset.right).rounded(.down)
        if proposedContentOffset.x <= minimumContentOffsetX || proposedContentOffset.x >= maximumContentOffsetX {
            return proposedContentOffset
        } else {
            let targetIndexPath = indexPath(forContentOffset: proposedContentOffset)
            return CGPoint(x: contentOffsetX(forItemAt: targetIndexPath), y: proposedContentOffset.y)
        }
    }
    
    override func targetContentOffset(forProposedContentOffset proposedContentOffset: CGPoint) -> CGPoint {
        if let centerIndexPathBeforeUpdate = centerIndexPathBeforeUpdate {
            let centerItemOffsetX = contentOffsetX(forItemAt: centerIndexPathBeforeUpdate)
            let contentOffsetX = centerIndexPathBeforeUpdate > centerIndexPath ? centerItemOffsetX - minimumLineSpacing - itemSize.width : centerItemOffsetX
            return CGPoint(x: contentOffsetX, y: proposedContentOffset.y)
        } else {
            let centerItemOffsetX = contentOffsetX(forItemAt: centerIndexPath)
            let transitionItemOffsetX = contentOffsetX(forItemAt: transition.indexPath)
            let targetOffsetX = centerItemOffsetX - transition.progress * (centerItemOffsetX - transitionItemOffsetX)
            return CGPoint(x: targetOffsetX, y: proposedContentOffset.y)
        }
    }
}

// MARK: - UICollectionViewFlowLayout - Updates
extension IFCollectionViewFlowLayout {
    
    override func prepare(forCollectionViewUpdates updateItems: [UICollectionViewUpdateItem]) {
        defer { super.prepare(forCollectionViewUpdates: updateItems) }
        guard let collectionView = collectionView else { return }

        if updateItems.count == 1, updateItems[0].updateAction == .delete {
            if let updateItem = updateItems.first(where: { $0.updateAction == .delete }) {
                self.deletingIndexPath = updateItem.indexPathBeforeUpdate
                if centerIndexPath == deletingIndexPath {
                    let item = min(centerIndexPath.item + 1, collectionView.numberOfItems(inSection: 0))
                    centerIndexPathBeforeUpdate = IndexPath(item: item, section: 0)
                } else {
                    centerIndexPathBeforeUpdate = centerIndexPath
                }
            }
            
            if collectionView.numberOfItems(inSection: 0) > 0 {
                updatePreferredItemSize(forItemIndexPaths: centerIndexPathBeforeUpdate.map { [$0] })
            }
        }
    }
    
    override func finalizeCollectionViewUpdates() {
        defer { super.finalizeCollectionViewUpdates() }
        
        if let deletingIndexPath = deletingIndexPath {
            preferredItemsRatio = preferredItemsRatio.reduce(into: [:]) { result, tuple in
                switch tuple.key.item {
                case (0..<deletingIndexPath.item):
                    result[tuple.key] = tuple.value
                case deletingIndexPath.item:
                    return
                default:
                    result[IndexPath(item: tuple.key.item - 1, section: tuple.key.section)] = tuple.value
                }
            }
            
            self.deletingIndexPath = nil
            centerIndexPathBeforeUpdate = nil
        }
    }
    
    override func prepare(forAnimatedBoundsChange oldBounds: CGRect) {
        defer { super.prepare(forAnimatedBoundsChange: oldBounds) }
        guard let collectionView = collectionView, oldBounds.size != collectionView.bounds.size else { return }
        update()
        let rect = collectionView.bounds.union(oldBounds)
        animatedLayoutAttributes = layoutAttributesForElements(in: rect)?.reduce(into: [:]) { $0[$1.indexPath] = $1 } ?? [:]
    }
    
    override func finalizeAnimatedBoundsChange() {
        animatedLayoutAttributes = [:]
        super.finalizeAnimatedBoundsChange()
    }
    
    override func prepareForTransition(to newLayout: UICollectionViewLayout) {
        defer { super.prepareForTransition(to: newLayout) }
        guard let flowLayout = newLayout as? IFCollectionViewFlowLayout else { return }
        updatePreferredItemSize(forItemIndexPaths: [centerIndexPath, transition.indexPath, flowLayout.centerIndexPath, flowLayout.transition.indexPath])
        flowLayout.preferredItemsRatio = preferredItemsRatio
    }
    
    override func initialLayoutAttributesForAppearingItem(at itemIndexPath: IndexPath) -> UICollectionViewLayoutAttributes? {
        guard animatedLayoutAttributes[itemIndexPath] == nil else { return animatedLayoutAttributes[itemIndexPath]! }
        let attribute = super.initialLayoutAttributesForAppearingItem(at: itemIndexPath)
        attribute?.alpha = 1
        attribute?.size = size(forItemAt: itemIndexPath)
        attribute?.frame.origin = CGPoint(x: originX(forItemAt: itemIndexPath), y: verticalPadding)
        return attribute
    }

    override func finalLayoutAttributesForDisappearingItem(at itemIndexPath: IndexPath) -> UICollectionViewLayoutAttributes? {
        let attribute = super.finalLayoutAttributesForDisappearingItem(at: itemIndexPath)
        attribute?.alpha = 1
        attribute?.size = finalLayoutAttributesSize(forItemAt: itemIndexPath)
        attribute?.frame.origin = CGPoint(x: finalLayoutAttributesOriginX(forItemAt: itemIndexPath), y: verticalPadding)
        return attribute
    }
}

// MARK: - Private methods
private extension IFCollectionViewFlowLayout {
    
    // MARK: Size
    func size(forItemAt indexPath: IndexPath) -> CGSize {
        guard style == .carousel, indexPath == centerIndexPath || indexPath == transition.indexPath else { return itemSize }

        let preferredWidth = preferredSize(forItemAt: indexPath).width
        let sizeMultiplier = indexPath == transition.indexPath ? transition.progress : (1 - transition.progress)
        let width = itemSize.width + (preferredWidth - itemSize.width) * sizeMultiplier
        return CGSize(width: width, height: itemSize.height)
    }
    
    func preferredSize(forItemAt indexPath: IndexPath) -> CGSize {
        guard style == .carousel, let preferredItemRatio = preferredItemsRatio[indexPath] else { return itemSize }
        
        switch mediaManager.videoStatus.value {
        case .autoplay, .play, .pause:
            if mediaManager.media[indexPath.item].mediaType.isVideo {
                return CGSize(width: itemSize.height * preferredItemRatio, height: itemSize.height)
            }
        default:
            break
        }
        
        let widthRange = itemSize.width...maximumItemWidth
        let preferredWidth = (itemSize.height * preferredItemRatio).clamped(to: widthRange)
        return CGSize(width: preferredWidth, height: itemSize.height)
    }
    
    func finalLayoutAttributesSize(forItemAt indexPath: IndexPath) -> CGSize {
        switch indexPath {
        case deletingIndexPath:
            return CGSize(width: 0, height: itemSize.height)
        case centerIndexPathBeforeUpdate:
            return preferredSize(forItemAt: indexPath)
        default:
            return size(forItemAt: indexPath)
        }
    }
    
    // MARK: Position
    
    /// It computes the origin's x-coordinate of a layout attribute.
    ///
    ///      [][][][][][]  [  ]  [][][]   [   ]   [][][][]
    ///     |   before   | min  | mid  |   max   |  over  |
    ///
    /// - Parameter indexPath: The layout attribute's index path
    /// - Returns: The x-coordinate of the point that specifies the coordinates of the layout attribute's origin.
    func originX(forItemAt indexPath: IndexPath) -> CGFloat {
        let minimumPreviewingIndexPath = min(centerIndexPath, transition.indexPath)
        let maximumPreviewingIndexPath = max(centerIndexPath, transition.indexPath)

        guard style == .carousel, indexPath >= minimumPreviewingIndexPath else { // before
            return CGFloat(indexPath.item) * minimumLineSpacing + CGFloat(indexPath.item) * itemSize.width + sectionInset.left
        }
        
        let maximumLineSpacing = isPlayingVideo ? playingVideoLineSpacing : maximumLineSpacing

        let centerIndexLineSpacing = minimumLineSpacing + (maximumLineSpacing - minimumLineSpacing) * (1 - transition.progress)
        let transitionIndexLineSpacing = minimumLineSpacing + (maximumLineSpacing - minimumLineSpacing) * transition.progress
        let minimumPreviewingLineSpacing = minimumPreviewingIndexPath == centerIndexPath && transition.indexPath != centerIndexPath ? centerIndexLineSpacing : transitionIndexLineSpacing
        let maximumPreviewingLineSpacing = maximumPreviewingIndexPath == centerIndexPath ? centerIndexLineSpacing : transitionIndexLineSpacing
        let minimumPreviewingWidth = size(forItemAt: minimumPreviewingIndexPath).width
        let maximumPreviewingWidth = size(forItemAt: maximumPreviewingIndexPath).width
        let numberOfMiddleItems = CGFloat(max(maximumPreviewingIndexPath.item - minimumPreviewingIndexPath.item - 1, 0))
        let numberOfMiddleSpaces = CGFloat(max(numberOfMiddleItems - 1, 0))
        let beforeItemsMaxX = CGFloat(minimumPreviewingIndexPath.item) * itemSize.width + max(CGFloat(minimumPreviewingIndexPath.item - 1), 0) * minimumLineSpacing + sectionInset.left
        
        let itemPositionX: CGFloat
        switch indexPath {
        case minimumPreviewingIndexPath: // min
            itemPositionX = beforeItemsMaxX + minimumPreviewingLineSpacing
        case let indexPath where indexPath > minimumPreviewingIndexPath && indexPath < maximumPreviewingIndexPath: // middle
            let previousItemsMaxX = beforeItemsMaxX + minimumPreviewingLineSpacing * 2
            switch indexPath.item {
            case minimumPreviewingIndexPath.item + 1:
                itemPositionX = previousItemsMaxX + minimumPreviewingWidth
            default:
                let middleItemsMultiplier = CGFloat(indexPath.item - minimumPreviewingIndexPath.item - 1)
                itemPositionX = previousItemsMaxX + minimumPreviewingWidth + middleItemsMultiplier * itemSize.width + middleItemsMultiplier * minimumLineSpacing
            }
        case maximumPreviewingIndexPath: // max
            let minimumPreviewingOffset = beforeItemsMaxX + minimumPreviewingLineSpacing * 2 + minimumPreviewingWidth
            let middleItemsOffset = numberOfMiddleItems * itemSize.width + numberOfMiddleSpaces * minimumLineSpacing
            itemPositionX = minimumPreviewingOffset + middleItemsOffset + maximumPreviewingLineSpacing
        default: // over
            let minimumPreviewingOffset = beforeItemsMaxX + minimumPreviewingLineSpacing * 2 + minimumPreviewingWidth
            let middleItemsOffset = numberOfMiddleItems * itemSize.width + numberOfMiddleSpaces * minimumLineSpacing
            let maximumPreviewingOffset = transition.indexPath != centerIndexPath ? maximumPreviewingLineSpacing * 2 + maximumPreviewingWidth : 0
            let overItemsMultiplier = CGFloat(indexPath.item - maximumPreviewingIndexPath.item - 1)
            itemPositionX = minimumPreviewingOffset + middleItemsOffset + maximumPreviewingOffset + overItemsMultiplier * itemSize.width + overItemsMultiplier * minimumLineSpacing
        }
        
        return itemPositionX
    }
    
    func finalLayoutAttributesOriginX(forItemAt indexPath: IndexPath) -> CGFloat {
        guard
            let deletingIndexPath = deletingIndexPath,
            let centerIndexPathBeforeUpdate = centerIndexPathBeforeUpdate else {
                return originX(forItemAt: indexPath)
        }
        
        let maximumLineSpacing = isPlayingVideo ? playingVideoLineSpacing : maximumLineSpacing
        
        switch indexPath {
        case deletingIndexPath:
            let defaultOriginX = originX(forItemAt: indexPath)
            if indexPath < centerIndexPathBeforeUpdate {
                return defaultOriginX - maximumLineSpacing
            } else {
                return defaultOriginX - minimumLineSpacing
            }
        case centerIndexPathBeforeUpdate:
            let defaultOriginX = originX(forItemAt: indexPath)
            
            if indexPath < deletingIndexPath {
                return defaultOriginX
            } else {
                return defaultOriginX - (preferredSize(forItemAt: deletingIndexPath).width + maximumLineSpacing)
            }
        case let indexPath where (0..<deletingIndexPath.item).contains(indexPath.item):
            return originX(forItemAt: indexPath)
        default:
            var defaultOriginX = originX(forItemAt: indexPath)
            
            if centerIndexPathBeforeUpdate > deletingIndexPath {
                let deletingSizeDelta = preferredSize(forItemAt: centerIndexPathBeforeUpdate).width - preferredSize(forItemAt: deletingIndexPath).width
                defaultOriginX += deletingSizeDelta
            }
            
            return defaultOriginX - itemSize.width - minimumLineSpacing
        }
    }
    
    func update() {
        guard let collectionView = collectionView else { return }
        let height = collectionView.bounds.height - verticalPadding * 2
        itemSize = CGSize(width: height * minimumItemWidthMultiplier, height: height)
        let horizontalPadding = collectionView.bounds.width / 2
        sectionInset = UIEdgeInsets(top: verticalPadding, left: horizontalPadding, bottom: verticalPadding, right: horizontalPadding)
        maximumLineSpacing = height * maximumLineSpacingMultiplier
    }
    
    func setInitialContentOffsetIfNeeded() {
        guard needsInitialContentOffset, let collectionView = collectionView else { return }
        needsInitialContentOffset = false
        collectionView.contentOffset.x = contentOffsetX(forItemAt: centerIndexPath)
    }
    
    func updatePreferredItemSize(forItemIndexPaths indexPaths: [IndexPath]? = nil) {
        guard let collectionView = collectionView else { return }
        let preferredIndexPaths = indexPaths ?? [centerIndexPath, transition.indexPath]
        var processedIndices: Set<IndexPath> = []
        
        for preferredIndexPath in preferredIndexPaths where !processedIndices.contains(preferredIndexPath) {
            defer { processedIndices.insert(preferredIndexPath) }
            
            guard
                let layoutAttribute = layoutAttributesForItem(at: preferredIndexPath),
                let cell = collectionView.cellForItem(at: preferredIndexPath) else { continue }
            
            let preferredAttribute = cell.preferredLayoutAttributesFitting(layoutAttribute)
            preferredItemsRatio[preferredIndexPath] = preferredAttribute.size.width / preferredAttribute.size.height
        }
    }
}
