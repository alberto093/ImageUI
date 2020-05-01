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

class IFCollectionViewFlowLayout: UICollectionViewFlowLayout {
    enum Style {
        case preview
        case normal
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
    var style: Style = .preview
    var centerIndexPath: IndexPath
    var verticalPadding: CGFloat = 1
    var minimumItemWidthMultiplier: CGFloat = 0.5
    var maximumItemWidthMultiplier: CGFloat = 34 / 9
    var maximumLineSpacingMultiplier: CGFloat = 0.28
    
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
    
    // MARK: - Accessory properties
    var transition: Transition
    private var animatedLayoutAttributes: [IndexPath: UICollectionViewLayoutAttributes] = [:]
    private var preferredItemSizes: [IndexPath: CGSize] = [:]
    private lazy var maximumLineSpacing = minimumLineSpacing
    var needsInitialContentOffset = true
    
    // MARK: - Overrides
    init(centerIndexPath: IndexPath) {
        self.centerIndexPath = centerIndexPath
        transition = Transition(indexPath: centerIndexPath)
        super.init()
        setup()
    }
    
    required init?(coder: NSCoder) {
        centerIndexPath = IndexPath(item: 0, section: 0)
        transition = Transition(indexPath: centerIndexPath)
        super.init(coder: coder)
        setup()
    }
    
    private func setup() {
        minimumLineSpacing = 1
        scrollDirection = .horizontal
    }
    
    override func prepare() {
        update()
        setInitialContentOffsetIfNeeded()
        super.prepare()
    }
    
    override func prepare(forAnimatedBoundsChange oldBounds: CGRect) {
        defer { super.prepare(forAnimatedBoundsChange: oldBounds) }
        guard let collectionView = collectionView, oldBounds.size != collectionView.bounds.size else { return }
        update()
        let rect = collectionView.bounds.union(oldBounds)
        animatedLayoutAttributes = layoutAttributesForElements(in: rect)?.reduce(into: [:]) { $0[$1.indexPath] = $1 } ?? [:]
    }
    
    override func layoutAttributesForElements(in rect: CGRect) -> [UICollectionViewLayoutAttributes]? {
        guard let superAttributes = super.layoutAttributesForElements(in: rect) else { return nil }
        
        var layoutAttributes: [UICollectionViewLayoutAttributes] = []
        for superAttribute in superAttributes {
            guard let layoutAttribute = superAttribute.copy() as? UICollectionViewLayoutAttributes else { continue }
            layoutAttribute.size = size(forItemAt: layoutAttribute.indexPath)
            layoutAttribute.frame.origin = CGPoint(x: originX(forItemAt: layoutAttribute.indexPath), y: verticalPadding)
            layoutAttributes.append(layoutAttribute)
//            layoutAttributesCache[layoutAttribute.indexPath] = layoutAttribute
        }
        
        return layoutAttributes
    }
  
    override func layoutAttributesForItem(at indexPath: IndexPath) -> UICollectionViewLayoutAttributes? {
        guard let superAttributes = super.layoutAttributesForItem(at: indexPath) else { return nil }
        guard let layoutAttributes = superAttributes.copy() as? UICollectionViewLayoutAttributes else { return superAttributes }
        layoutAttributes.size = size(forItemAt: layoutAttributes.indexPath)
        layoutAttributes.frame.origin = CGPoint(x: originX(forItemAt: layoutAttributes.indexPath), y: verticalPadding)
        return layoutAttributes
    }
    
    override func targetContentOffset(forProposedContentOffset proposedContentOffset: CGPoint) -> CGPoint {
        let centerItemOffsetX = contentOffsetX(forItemAt: centerIndexPath)
        let transitionItemOffsetX = contentOffsetX(forItemAt: transition.indexPath)
        let targetOffsetX = centerItemOffsetX - transition.progress * (centerItemOffsetX - transitionItemOffsetX)
        return CGPoint(x: targetOffsetX, y: proposedContentOffset.y)
    }
    
    override func targetContentOffset(forProposedContentOffset proposedContentOffset: CGPoint, withScrollingVelocity velocity: CGPoint) -> CGPoint {
        guard let collectionView = collectionView else { return proposedContentOffset }
        let minimumContentOffsetX = -collectionView.contentInset.left.rounded(.up)
        let maximumContentOffsetX = (collectionView.contentSize.width - collectionView.bounds.width + collectionView.contentInset.right).rounded(.down)
        if proposedContentOffset.x <= minimumContentOffsetX || proposedContentOffset.x >= maximumContentOffsetX {
            return proposedContentOffset
        } else {
            let targetIndexPath = indexPath(forContentOffset: proposedContentOffset)
            return CGPoint(x: contentOffsetX(forItemAt: targetIndexPath), y: proposedContentOffset.y)
        }
    }
    
    override func shouldInvalidateLayout(
        forPreferredLayoutAttributes preferredAttributes: UICollectionViewLayoutAttributes,
        withOriginalAttributes originalAttributes: UICollectionViewLayoutAttributes) -> Bool {
        guard
            originalAttributes.indexPath == preferredAttributes.indexPath,
            preferredItemSizes[preferredAttributes.indexPath] != preferredAttributes.size else { return false }
        
        preferredItemSizes[preferredAttributes.indexPath] = preferredAttributes.size
        return false
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
        attribute?.size = size(forItemAt: itemIndexPath)
        attribute?.frame.origin = CGPoint(x: originX(forItemAt: itemIndexPath), y: verticalPadding)
        return attribute
    }
    
    override func finalizeAnimatedBoundsChange() {
        animatedLayoutAttributes = [:]
        super.finalizeAnimatedBoundsChange()
    }
    
    override func shouldInvalidateLayout(forBoundsChange newBounds: CGRect) -> Bool {
        collectionView?.bounds.size != newBounds.size
    }

    override func prepareForTransition(to newLayout: UICollectionViewLayout) {
        defer { super.prepareForTransition(to: newLayout) }
        guard let flowLayout = newLayout as? IFCollectionViewFlowLayout else { return }
        flowLayout.needsInitialContentOffset = false
        updatePreferredItemSize(forItemIndexPaths: [centerIndexPath, flowLayout.centerIndexPath])
        flowLayout.preferredItemSizes = preferredItemSizes
    }
    
    // MARK: - Public methods
    func indexPath(forContentOffset contentOffset: CGPoint) -> IndexPath {
        let itemsRange = (0...(collectionView.map { $0.numberOfItems(inSection: 0) - 1 } ?? 0))
        let itemIndex = (contentOffset.x - minimumLineSpacing / 2) / (itemSize.width + minimumLineSpacing)
        let normalizedIndex = min(max(Int(itemIndex), itemsRange.lowerBound), itemsRange.upperBound)
        return IndexPath(item: normalizedIndex, section: 0)
    }

    func invalidateLayoutIfNeeded(forTransitionIndexPath indexPath: IndexPath, progress: CGFloat) {
        let progress = min(max(progress, 0), 1)
        transition = Transition(indexPath: indexPath, progress: progress)
        updatePreferredItemSize()
        if progress == 1 {
            centerIndexPath = indexPath
        }
        
        guard let collectionView = collectionView else { return }
        
        let context = UICollectionViewFlowLayoutInvalidationContext()
        let initialOffsetX = contentOffsetX(forItemAt: centerIndexPath)
        let finalOffsetX = contentOffsetX(forItemAt: indexPath)
        
        switch progress {
        case 0, 1:
            context.contentOffsetAdjustment.x = contentOffsetX(forItemAt: centerIndexPath) - collectionView.contentOffset.x
        default:
            let targetOffsetX = initialOffsetX - progress * (initialOffsetX - finalOffsetX)
            context.contentOffsetAdjustment.x = targetOffsetX - collectionView.contentOffset.x
        }
        
        invalidateLayout(with: context)
    }
    
    func invalidateLayout(with style: Style, centerIndexPath: IndexPath) {
        guard let collectionView = collectionView else { return }
        self.style = style
        self.centerIndexPath = centerIndexPath
        self.transition = Transition(indexPath: centerIndexPath)
        updatePreferredItemSize()
        
        let context = UICollectionViewFlowLayoutInvalidationContext()
        context.contentOffsetAdjustment.x = contentOffsetX(forItemAt: centerIndexPath) - collectionView.contentOffset.x
        invalidateLayout(with: context)
    }
    
    private func size(forItemAt indexPath: IndexPath) -> CGSize {
        guard style == .preview, indexPath == centerIndexPath || indexPath == transition.indexPath else { return itemSize }

        let preferredWidth = preferredSize(forItemAt: indexPath).width
        let sizeMultiplier = indexPath == transition.indexPath ? transition.progress : (1 - transition.progress)
        let width = itemSize.width + (preferredWidth - itemSize.width) * sizeMultiplier
        return CGSize(width: width, height: itemSize.height)
    }
    
    private func preferredSize(forItemAt indexPath: IndexPath) -> CGSize {
        guard style == .preview, let preferredItemSize = preferredItemSizes[indexPath] else { return itemSize }
        let widthRange = itemSize.width...maximumItemWidth
        let preferredWidth = min(max(preferredItemSize.width, widthRange.lowerBound), widthRange.upperBound)
        return CGSize(width: preferredWidth, height: itemSize.height)
    }
    
    ///  [][][][][][]  [  ]  [][][]    [   ]    [][][][]
    /// |   before   |  min | mid  |    max    |  over  |
    ///
    /// - Parameter indexPath:
    /// - Returns:
    private func originX(forItemAt indexPath: IndexPath) -> CGFloat {
        let minimumPreviewingIndexPath = min(centerIndexPath, transition.indexPath)
        let maximumPreviewingIndexPath = max(centerIndexPath, transition.indexPath)

        guard style == .preview, indexPath >= minimumPreviewingIndexPath else { // before
            return CGFloat(indexPath.item) * minimumLineSpacing + CGFloat(indexPath.item) * itemSize.width + sectionInset.left
        }

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
            let previousItemsMaxX = beforeItemsMaxX + minimumPreviewingLineSpacing * 2 + minimumPreviewingWidth + numberOfMiddleItems * itemSize.width + numberOfMiddleSpaces * minimumLineSpacing
            itemPositionX = previousItemsMaxX + maximumPreviewingLineSpacing
        default: // over
            let minimumPreviewingOffset = beforeItemsMaxX + minimumPreviewingLineSpacing * 2 + minimumPreviewingWidth
            let middleItemsOffset = numberOfMiddleItems * itemSize.width + numberOfMiddleSpaces * minimumLineSpacing
            let maximumPreviewingOffset = transition.indexPath != centerIndexPath ? maximumPreviewingLineSpacing * 2 + maximumPreviewingWidth : 0
            let overItemsMultiplier = CGFloat(indexPath.item - maximumPreviewingIndexPath.item - 1)
            itemPositionX = minimumPreviewingOffset + middleItemsOffset + maximumPreviewingOffset + overItemsMultiplier * itemSize.width + overItemsMultiplier * minimumLineSpacing
        }
        
//        itemPositionCache[indexPath] = itemPositionX
        return itemPositionX
    }
    
    private func contentOffsetX(forItemAt indexPath: IndexPath) -> CGFloat {
        let previousItemOffset = CGFloat(indexPath.item) * itemSize.width + CGFloat(indexPath.item - 1) * minimumLineSpacing

        switch style {
        case .normal:
            return previousItemOffset + minimumLineSpacing + itemSize.width / 2
        case .preview:
            return previousItemOffset + maximumLineSpacing + preferredSize(forItemAt: indexPath).width / 2
        }
    }
    
    private func update() {
        guard let collectionView = collectionView else { return }
        let height = collectionView.bounds.height - verticalPadding * 2
        itemSize = CGSize(width: height * minimumItemWidthMultiplier, height: height)
        let horizontalPadding = collectionView.bounds.width / 2
        sectionInset = UIEdgeInsets(top: verticalPadding, left: horizontalPadding, bottom: verticalPadding, right: horizontalPadding)
        maximumLineSpacing = height * maximumLineSpacingMultiplier
    }
    
    private func setInitialContentOffsetIfNeeded() {
        guard needsInitialContentOffset else { return }
        needsInitialContentOffset = false
        collectionView?.contentOffset.x = contentOffsetX(forItemAt: centerIndexPath)
    }
    
    private func updatePreferredItemSize(forItemIndexPaths indexPaths: [IndexPath]? = nil) {
        let preferredIndexPaths: [IndexPath]
        if let indexPaths = indexPaths {
            preferredIndexPaths = indexPaths
        } else {
            preferredIndexPaths = centerIndexPath == transition.indexPath ? [centerIndexPath] : [centerIndexPath, transition.indexPath]
        }
        
        preferredIndexPaths.forEach {
            guard
                let collectionView = collectionView,
                let layoutAttribute = layoutAttributesForItem(at: $0),
                let cell = collectionView.cellForItem(at: $0) else { return }
            
            let preferredAttribute = cell.preferredLayoutAttributesFitting(layoutAttribute)
            preferredItemSizes[$0] = preferredAttribute.size
        }
    }
}
