//
//  IFPageViewController.swift
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

protocol IFPageViewControllerDelegate: AnyObject {
    func pageViewController(_ pageViewController: IFPageViewController, didScrollFrom startIndex: Int, direction: UIPageViewController.NavigationDirection, progress: CGFloat)
    func pageViewController(_ pageViewController: IFPageViewController, didUpdatePage index: Int)
    func pageViewControllerDidResetScroll(_ pageViewController: IFPageViewController)
}

class IFPageViewController: UIPageViewController {
    private struct Constants {
        static let interPageSpacing: CGFloat = 40
    }
    // MARK: - View
    private var scrollView: UIScrollView? {
        view.subviews.first { $0 is UIScrollView } as? UIScrollView
    }
    
    // MARK: - Public properties
    weak var progressDelegate: IFPageViewControllerDelegate?
    let imageManager: IFImageManager
    
    // MARK: - Accessory properties
    private var contentOffsetObservation: NSKeyValueObservation?
    private var isRemovingPage = false
    private var beforeViewController: IFImageViewController?
    private var visibleViewController: IFImageViewController? {
        viewControllers?.first as? IFImageViewController
    }
    private var afterViewController: IFImageViewController?
    
    // MARK: - Initializer
    init(imageManager: IFImageManager) {
        self.imageManager = imageManager
        super.init(transitionStyle: .scroll, navigationOrientation: .horizontal, options: [.interPageSpacing: Constants.interPageSpacing])
    }
    
    required init?(coder: NSCoder) {
        self.imageManager = IFImageManager(images: [])
        super.init(coder: coder)
    }
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setup()
    }
    
    // MARK: - Public methods
    func updateVisibleImage(index: Int) {
        guard isViewLoaded, let visibleViewController = visibleViewController else { return }
        reloadDataSourceIfNeeded(forImageAt: index)
        beforeViewController?.displayingImageIndex = index - 1
        afterViewController?.displayingImageIndex = index + 1
        visibleViewController.displayingImageIndex = index
    }
    
    func removeDisplayingImage(completion: (() -> Void)? = nil) {
        guard let displayingImageIndex = visibleViewController?.displayingImageIndex else { return }
        let removingDirection: NavigationDirection = displayingImageIndex > imageManager.displayingImageIndex ? .reverse : .forward
        let viewController = IFImageViewController(imageManager: imageManager)
        isRemovingPage = true
        visibleViewController?.prepareForRemove { [weak self] in
            if self?.imageManager.images.isEmpty == true {
                self?.isRemovingPage = false
                completion?()
            } else {
                self?.setViewControllers([viewController], direction: removingDirection, animated: true) { _ in
                    self?.isRemovingPage = false
                    completion?()
                }
            }
        }
    }
    
    func invalidateDataSourceIfNeeded() {
        guard let scrollView = scrollView, scrollView.isDragging || scrollView.isDecelerating else { return }
        invalidateDataSource()
    }
    
    /// Disable the gesture-based navigation.
    private func invalidateDataSource() {
        dataSource = nil
        [beforeViewController, afterViewController].forEach { $0?.removeFromParent() }
        beforeViewController = nil
        afterViewController = nil
        dataSource = self
    }
    
    private func reloadDataSourceIfNeeded(forImageAt index: Int) {
        switch (visibleViewController?.displayingImageIndex, index) {
        case (0, _), (imageManager.images.count - 1, _), (_, 0), (_, imageManager.images.count - 1):
            invalidateDataSource()
        default:
            break
        }
    }
    
    // MARK: - Private methods
    private func setup() {
        dataSource = self
        delegate = self
        contentOffsetObservation = scrollView?.observe(\.contentOffset, options: .old) { [weak self] scrollView, change in
            guard let oldValue = change.oldValue, oldValue != scrollView.contentOffset else { return }
            self?.handleContentOffset(in: scrollView, oldValue: oldValue)
        }
        
        let initialViewController = IFImageViewController(imageManager: imageManager)
        setViewControllers([initialViewController], direction: .forward, animated: false)
    }
    
    private func handleContentOffset(in scrollView: UIScrollView, oldValue: CGPoint) {
        switch scrollView.panGestureRecognizer.state {
        case .cancelled:
            DispatchQueue.main.async {
                self.invalidateDataSource()
                self.progressDelegate?.pageViewControllerDidResetScroll(self)
            }
        default:
            guard isRemovingPage || scrollView.isDragging || scrollView.isDecelerating else { break }
            
            let oldProgress = (oldValue.x - scrollView.bounds.width) / scrollView.bounds.width
            let oldNormalizedProgress = min(max(abs(oldProgress), 0), 1)
            let progress = (scrollView.contentOffset.x - scrollView.bounds.width) / scrollView.bounds.width
            let normalizedProgress = min(max(abs(progress), 0), 1)
            
            let direction: NavigationDirection = progress < 0 ? .reverse : .forward
            if !isRemovingPage {
                progressDelegate?.pageViewController(self, didScrollFrom: imageManager.displayingImageIndex, direction: direction, progress: normalizedProgress)
            }
            
            switch (oldNormalizedProgress, normalizedProgress) {
            case (CGFloat(0.nextUp)..<0.5, 0.5..<1):
                let index: Int
                if isRemovingPage {
                    index = imageManager.displayingImageIndex
                } else {
                    index = direction == .forward ? imageManager.displayingImageIndex + 1 : imageManager.displayingImageIndex - 1
                }
                progressDelegate?.pageViewController(self, didUpdatePage: index)
            case (CGFloat(0.5.nextUp)..<1, CGFloat(0.nextUp)...0.5):
                progressDelegate?.pageViewController(self, didUpdatePage: imageManager.displayingImageIndex)
            default:
                break
            }
        }
    }
}

extension IFPageViewController: UIPageViewControllerDataSource {
    func pageViewController(_ pageViewController: UIPageViewController, viewControllerBefore viewController: UIViewController) -> UIViewController? {
        let previousIndex = imageManager.displayingImageIndex - 1
        guard imageManager.images.indices.contains(previousIndex) else { return nil }
        beforeViewController = IFImageViewController(imageManager: imageManager, displayingImageIndex: previousIndex)
        return beforeViewController
    }
    
    func pageViewController(_ pageViewController: UIPageViewController, viewControllerAfter viewController: UIViewController) -> UIViewController? {
        let nextIndex = imageManager.displayingImageIndex + 1
        guard imageManager.images.indices.contains(nextIndex) else { return nil }
        afterViewController = IFImageViewController(imageManager: imageManager, displayingImageIndex: nextIndex)
        return afterViewController
    }
}

extension IFPageViewController: UIPageViewControllerDelegate {
    func pageViewController(_ pageViewController: UIPageViewController, didFinishAnimating finished: Bool, previousViewControllers: [UIViewController], transitionCompleted completed: Bool) {
        guard
            completed,
            let previousViewController = previousViewControllers.first as? IFImageViewController,
            let visibleViewController = visibleViewController else { return }
        
        switch visibleViewController {
        case afterViewController:
            beforeViewController = previousViewController
        case beforeViewController:
            afterViewController = previousViewController
        default:
            break
        }
        imageManager.updatedisplayingImage(index: visibleViewController.displayingImageIndex)
    }
}
