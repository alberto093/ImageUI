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
    let mediaManager: IFMediaManager
    
    // MARK: - Accessory properties
    private var contentOffsetObservation: NSKeyValueObservation?
    private var isRemovingPage = false
    private var beforeViewController: IFMediaViewController?
    private var visibleViewController: IFMediaViewController? {
        viewControllers?.first as? IFMediaViewController
    }
    private var afterViewController: IFMediaViewController?
    
    // MARK: - Initializer
    init(mediaManager: IFMediaManager) {
        self.mediaManager = mediaManager
        super.init(transitionStyle: .scroll, navigationOrientation: .horizontal, options: [.interPageSpacing: Constants.interPageSpacing])
    }
    
    required init?(coder: NSCoder) {
        self.mediaManager = IFMediaManager(media: [])
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
        beforeViewController?.displayingMediaIndex = index - 1
        afterViewController?.displayingMediaIndex = index + 1
        visibleViewController.displayingMediaIndex = index
    }
    
    func removeDisplayingMedia(completion: (() -> Void)? = nil) {
        guard let displayingMediaIndex = visibleViewController?.displayingMediaIndex else { return }
        let removingDirection: NavigationDirection = displayingMediaIndex > mediaManager.displayingMediaIndex ? .reverse : .forward
        let viewController = IFMediaViewController(mediaManager: mediaManager)
        isRemovingPage = true
        visibleViewController?.prepareForRemove { [weak self] in
            if self?.mediaManager.media.isEmpty == true {
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
    
    func pauseMedia() {
        visibleViewController?.pauseMedia()
    }
    
    func playMedia() {
        visibleViewController?.playMedia()
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
        switch (visibleViewController?.displayingMediaIndex, index) {
        case (0, _), (mediaManager.media.count - 1, _), (_, 0), (_, mediaManager.media.count - 1):
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
        
        let initialViewController = IFMediaViewController(mediaManager: mediaManager)
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
                progressDelegate?.pageViewController(self, didScrollFrom: mediaManager.displayingMediaIndex, direction: direction, progress: normalizedProgress)
            }
            
            switch (oldNormalizedProgress, normalizedProgress) {
            case (CGFloat(0.nextUp)..<0.5, 0.5..<1):
                let index: Int
                if isRemovingPage {
                    index = mediaManager.displayingMediaIndex
                } else {
                    index = direction == .forward ? mediaManager.displayingMediaIndex + 1 : mediaManager.displayingMediaIndex - 1
                }
                progressDelegate?.pageViewController(self, didUpdatePage: index)
            case (CGFloat(0.5.nextUp)..<1, CGFloat(0.nextUp)...0.5):
                progressDelegate?.pageViewController(self, didUpdatePage: mediaManager.displayingMediaIndex)
            default:
                break
            }
        }
    }
}

extension IFPageViewController: UIPageViewControllerDataSource {
    func pageViewController(_ pageViewController: UIPageViewController, viewControllerBefore viewController: UIViewController) -> UIViewController? {
        let previousIndex = mediaManager.displayingMediaIndex - 1
        guard mediaManager.media.indices.contains(previousIndex) else { return nil }
        beforeViewController = IFMediaViewController(mediaManager: mediaManager, displayingMediaIndex: previousIndex)
        return beforeViewController
    }
    
    func pageViewController(_ pageViewController: UIPageViewController, viewControllerAfter viewController: UIViewController) -> UIViewController? {
        let nextIndex = mediaManager.displayingMediaIndex + 1
        guard mediaManager.media.indices.contains(nextIndex) else { return nil }
        afterViewController = IFMediaViewController(mediaManager: mediaManager, displayingMediaIndex: nextIndex)
        return afterViewController
    }
}

extension IFPageViewController: UIPageViewControllerDelegate {
    func pageViewController(_ pageViewController: UIPageViewController, didFinishAnimating finished: Bool, previousViewControllers: [UIViewController], transitionCompleted completed: Bool) {
        guard
            completed,
            let previousViewController = previousViewControllers.first as? IFMediaViewController,
            let visibleViewController = visibleViewController
        else { return }
        
        switch visibleViewController {
        case afterViewController:
            beforeViewController = previousViewController
        case beforeViewController:
            afterViewController = previousViewController
        default:
            break
        }
        
        mediaManager.updatedisplayingMedia(index: visibleViewController.displayingMediaIndex)
    }
}
