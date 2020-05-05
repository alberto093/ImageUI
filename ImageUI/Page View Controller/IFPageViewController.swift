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

protocol IFPageViewControllerDelegate: class {
    func pageViewController(_ pageViewController: IFPageViewController, didScrollFrom startIndex: Int, direction: UIPageViewController.NavigationDirection, progress: CGFloat)
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
        beforeViewController?.displayingImageIndex = index - 1
        afterViewController?.displayingImageIndex = index + 1
        visibleViewController.displayingImageIndex = index
    }
    
    func invalidateDataSourceIfNeeded() {
        guard let scrollView = scrollView, scrollView.isDragging || scrollView.isDecelerating else { return }
        invalidateDataSource()
    }
    
    /// Disable the gesture-based navigation.
    private func invalidateDataSource() {
        dataSource = nil
        dataSource = self
    }
    
    // MARK: - Private methods
    private func setup() {
        dataSource = self
        delegate = self
        contentOffsetObservation = scrollView?.observe(\.contentOffset, options: .old) { [weak self] scrollView, change in
            guard change.oldValue != scrollView.contentOffset else { return }
            self?.handleContentOffset()
        }
        
        let initialViewController = IFImageViewController(imageManager: imageManager)
        setViewControllers([initialViewController], direction: .forward, animated: false)
    }
    
    private func handleContentOffset() {
        guard let scrollView = scrollView else { return }
        
        switch scrollView.panGestureRecognizer.state {
        case .cancelled:
            DispatchQueue.main.async {
                self.invalidateDataSource()
                self.progressDelegate?.pageViewControllerDidResetScroll(self)
            }
        default:
            guard scrollView.isDragging || scrollView.isDecelerating else { break }
            
            let progress = (scrollView.contentOffset.x - scrollView.bounds.width) / scrollView.bounds.width
            let direction: NavigationDirection = progress < 0 ? .reverse : .forward
            let normalizedProgress = min(max(abs(progress), 0), 1)
            print("progress: \(normalizedProgress)")
            progressDelegate?.pageViewController(self, didScrollFrom: imageManager.displayingImageIndex, direction: direction, progress: normalizedProgress)
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
