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

#warning("Update layout attributes that are not equal to fullyVisibleIndexPath and oldFullyVisibleIndexPath based on transitionProgress. In this way there will not be lack during animations")
class IFCollectionViewFlowLayout: UICollectionViewFlowLayout {
    enum Style {
        case preview
        case normal
    }
    
    private struct Constants {
        static let verticalPadding: CGFloat = 1
        static let minimumItemWidthMultiplier: CGFloat = 0.5
        static let minimumLineSpacing: CGFloat = 1
        static let maximumLineSpacingMultiplier: CGFloat = 0.28
        static let layoutTransitionDuration: TimeInterval = 0.24
        static let layoutTransitionRate: UIScrollView.DecelerationRate = .normal
    }
    
    private struct Transition {
        let indexPath: IndexPath
        let progress: CGFloat
        
        init(indexPath: IndexPath, progress: CGFloat = 1) {
            self.indexPath = indexPath
            self.progress = progress
        }
    }
    
    // MARK: - Public properties
    var style: Style = .preview
    var centerIndexPath = IndexPath(item: 0, section: 0)
    lazy var maximumWidthMultiplier: CGFloat = 34 / 9
    lazy var maximumLineSpacing = minimumLineSpacing
    
    var isTransitioning: Bool {
        centerIndexPath != transition.indexPath && transition.progress > 0
    }
    // MARK: - Accessory properties
    private var transition: Transition
    private var visibleAttributesCache: [IndexPath: UICollectionViewLayoutAttributes] = [:]
    private var preferredItemSizes: [IndexPath: CGSize] = [:]
    
    private var maximumItemWidth: CGFloat {
        style == .normal ? itemSize.width : itemSize.width * maximumWidthMultiplier
    }
    
    override var estimatedItemSize: CGSize {
        willSet {
            if newValue != .zero {
                fatalError("UICollectionViewLayout: \(self) does not support estimated item size.")
            }
        }
    }
        
    override var scrollDirection: UICollectionView.ScrollDirection {
        willSet {
            if newValue == .vertical {
                fatalError("UICollectionViewLayout: \(self) does not support vertical scroll direction.")
            }
        }
    }
    
    // MARK: - Overrides
    override init() {
        transition = Transition(indexPath: centerIndexPath)
        super.init()
        scrollDirection = .horizontal
    }
    
    required init?(coder: NSCoder) {
        transition = Transition(indexPath: centerIndexPath)
        super.init(coder: coder)
        scrollDirection = .horizontal
    }
    
    override func prepare() {
        visibleAttributesCache = [:]
        update()
        super.prepare()
    }
    
    override func prepare(forAnimatedBoundsChange oldBounds: CGRect) {
        update()
        super.prepare(forAnimatedBoundsChange: oldBounds)
    }
    
    override func layoutAttributesForElements(in rect: CGRect) -> [UICollectionViewLayoutAttributes]? {
        guard let superAttributes = super.layoutAttributesForElements(in: rect) else { return nil }
        guard
            style == .preview,
            let layoutAttributes = NSArray(array: superAttributes, copyItems: true) as? [UICollectionViewLayoutAttributes] else { return superAttributes }
        
        visibleAttributesCache = layoutAttributes.reduce(into: [:]) { $0[$1.indexPath] = $1 }
        
        for attribute in layoutAttributes.sorted(by: { $0.indexPath < $1.indexPath }) {
            updateSizeIfNeeded(forLayoutAttribute: attribute)
            updatePositionIfNeeded(forLayoutAttribute: attribute)
        }
        
        return layoutAttributes
    }
  
    override func layoutAttributesForItem(at indexPath: IndexPath) -> UICollectionViewLayoutAttributes? {
        switch style {
        case .preview:
            guard visibleAttributesCache[indexPath] == nil else { return visibleAttributesCache[indexPath]! }
            guard let superAttribute = super.layoutAttributesForItem(at: indexPath) else { return nil }
            guard let layoutAttribute = superAttribute.copy() as? UICollectionViewLayoutAttributes else { return superAttribute }
            updateSizeIfNeeded(forLayoutAttribute: layoutAttribute)
            updatePositionIfNeeded(forLayoutAttribute: layoutAttribute)
            return layoutAttribute
        case .normal:
            return super.layoutAttributesForItem(at: indexPath)
        }
    }
    
    override func targetContentOffset(forProposedContentOffset proposedContentOffset: CGPoint) -> CGPoint {
        CGPoint(x: contentOffsetX(forItemAt: centerIndexPath), y: proposedContentOffset.y)
    }
    
    override func shouldInvalidateLayout(
        forPreferredLayoutAttributes preferredAttributes: UICollectionViewLayoutAttributes,
        withOriginalAttributes originalAttributes: UICollectionViewLayoutAttributes) -> Bool {
        guard
            originalAttributes.indexPath == preferredAttributes.indexPath,
            preferredItemSizes[preferredAttributes.indexPath] != preferredAttributes.size else { return false }
        
        preferredItemSizes[preferredAttributes.indexPath] = preferredAttributes.size
        
        switch preferredAttributes.indexPath {
        case centerIndexPath, transition.indexPath:
            return style == .preview
        default:
            return false
        }
    }
    
    override func invalidationContext(
        forPreferredLayoutAttributes preferredAttributes: UICollectionViewLayoutAttributes,
        withOriginalAttributes originalAttributes: UICollectionViewLayoutAttributes) -> UICollectionViewLayoutInvalidationContext {
      
        let context = UICollectionViewFlowLayoutInvalidationContext()
        switch originalAttributes.indexPath {
        case centerIndexPath, transition.indexPath:
            if style == .preview {
                context.contentOffsetAdjustment.x = preferredSize(forItemAt: centerIndexPath).width / 2 - itemSize.width / 2
            }
        default:
            break
        }
        
        return context
    }
    
    override func initialLayoutAttributesForAppearingItem(at itemIndexPath: IndexPath) -> UICollectionViewLayoutAttributes? {
        let attribute = layoutAttributesForItem(at: itemIndexPath)
        attribute?.alpha = 1
        return attribute
    }
    
    override func finalLayoutAttributesForDisappearingItem(at itemIndexPath: IndexPath) -> UICollectionViewLayoutAttributes? {
        let attribute = layoutAttributesForItem(at: itemIndexPath)
        attribute?.alpha = 1
        return attribute
    }
    
    override func shouldInvalidateLayout(forBoundsChange newBounds: CGRect) -> Bool {
        collectionView?.bounds.size != newBounds.size
    }
    
    // MARK: - Public methods
    func indexPath(forContentOffset contentOffset: CGPoint) -> IndexPath {
        let itemsRange = (0...(collectionView.map { $0.numberOfItems(inSection: 0) - 1 } ?? 0))
        let itemIndex = (contentOffset.x + minimumLineSpacing / 2) / (itemSize.width + minimumLineSpacing)
        let normalizedIndex = min(max(Int(itemIndex), itemsRange.lowerBound), itemsRange.upperBound)
        return IndexPath(item: normalizedIndex, section: 0)
    }

    func invalidateLayoutIfNeeded(forTransitionIndexPath indexPath: IndexPath, progress: CGFloat) {
        let progress = min(max(progress, 0), 1)
        transition = Transition(indexPath: indexPath, progress: progress)
        
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
        
        let context = UICollectionViewFlowLayoutInvalidationContext()
        context.contentOffsetAdjustment.x = contentOffsetX(forItemAt: centerIndexPath) - collectionView.contentOffset.x
        invalidateLayout(with: context)
    }

    // MARK: - Private methods
    private func updateSizeIfNeeded(forLayoutAttribute attribute: UICollectionViewLayoutAttributes) {
        guard attribute.indexPath == centerIndexPath || attribute.indexPath == transition.indexPath else { return }
        
        let preferredWidth = preferredSize(forItemAt: attribute.indexPath).width
        let sizeMultiplier = attribute.indexPath == transition.indexPath ? transition.progress : (1 - transition.progress)
        attribute.size.width = itemSize.width + (preferredWidth - itemSize.width) * sizeMultiplier
    }
    
    private func updatePositionIfNeeded(forLayoutAttribute attribute: UICollectionViewLayoutAttributes) {
        guard attribute.indexPath.item >= min(centerIndexPath.item, transition.indexPath.item) else { return }
                
        let minimumLineSpacingIndexRange = (centerIndexPath.item...centerIndexPath.item + 1)
        let maximumLineSpacingIndexRange = (transition.indexPath.item...transition.indexPath.item + 1)
        
        let previousIndexPath = IndexPath(item: attribute.indexPath.item - 1, section: 0)
        let startPositionX = visibleAttributesCache[previousIndexPath]?.frame.maxX ?? sectionInset.left
        
        guard minimumLineSpacingIndexRange.contains(attribute.indexPath.item) || maximumLineSpacingIndexRange.contains(attribute.indexPath.item) else {
            attribute.frame.origin.x = startPositionX + minimumLineSpacing
            return
        }
        
        let compressedLineSpacing = minimumLineSpacing + (maximumLineSpacing - minimumLineSpacing) * (1 - transition.progress)
        let expandedLineSpacing = minimumLineSpacing + (maximumLineSpacing - minimumLineSpacing) * transition.progress
        
        let lineSpacing: CGFloat
        switch attribute.indexPath.item {
        case transition.indexPath.item where transition.indexPath.item == centerIndexPath.item + 1,
             centerIndexPath.item where centerIndexPath.item == transition.indexPath.item + 1:
            lineSpacing = maximumLineSpacing
        case transition.indexPath.item,
             transition.indexPath.item + 1,
             centerIndexPath.item where transition.indexPath == centerIndexPath:
            lineSpacing = expandedLineSpacing
        default:
            lineSpacing = compressedLineSpacing
        }
        attribute.frame.origin.x = startPositionX + lineSpacing
    }
    
    private func preferredSize(forItemAt indexPath: IndexPath) -> CGSize {
        guard let preferredItemSize = preferredItemSizes[indexPath] else { return itemSize }
        let widthRange = itemSize.width...maximumItemWidth
        let preferredWidth = min(max(preferredItemSize.width, widthRange.lowerBound), widthRange.upperBound)
        return CGSize(width: preferredWidth, height: itemSize.height)
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
        let height = collectionView.bounds.height - Constants.verticalPadding * 2
        itemSize = CGSize(width: height * Constants.minimumItemWidthMultiplier, height: height)
        let horizontalPadding = collectionView.bounds.width / 2
        sectionInset = UIEdgeInsets(top: Constants.verticalPadding, left: horizontalPadding, bottom: Constants.verticalPadding, right: horizontalPadding)
        minimumLineSpacing = Constants.minimumLineSpacing
        maximumLineSpacing = height * Constants.maximumLineSpacingMultiplier
    }
}
