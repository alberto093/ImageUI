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
}

class IFPageViewController: UIPageViewController {
    private struct Constants {
        static let interPageSpacing: CGFloat = 32
    }
    // MARK: - View
    private var scrollView: UIScrollView? {
        view.subviews.first { $0 is UIScrollView } as? UIScrollView
    }
    
    // MARK: - Public properties
    weak var progressDelegate: IFPageViewControllerDelegate?
    let imageManager: IFImageManager
    
    // MARK: - Accessory properties
    private var beforeViewController: IFImageViewController?
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
        guard
            isViewLoaded,
            let imageViewController = viewControllers?.first as? IFImageViewController,
            imageViewController.displayingImageIndex != index,
            scrollView?.isDragging == false else { return }
        
        imageViewController.displayingImageIndex = index
        beforeViewController?.displayingImageIndex = index - 1
        afterViewController?.displayingImageIndex = index + 1
    }
    
    // MARK: - Private methods
    private func setup() {
        dataSource = self
        delegate = self
        scrollView?.delegate = self
        let initialViewController = IFImageViewController(imageManager: imageManager)
        setViewControllers([initialViewController], direction: .forward, animated: false)
    }
}

extension IFPageViewController: UIPageViewControllerDataSource {
    func pageViewController(_ pageViewController: UIPageViewController, viewControllerBefore viewController: UIViewController) -> UIViewController? {
        let previousIndex = imageManager.dysplaingImageIndex - 1
        guard imageManager.images.indices.contains(previousIndex) else { return nil }
        let viewController = IFImageViewController(imageManager: imageManager, displayingImageIndex: previousIndex)
        beforeViewController = viewController
        return viewController
    }
    
    func pageViewController(_ pageViewController: UIPageViewController, viewControllerAfter viewController: UIViewController) -> UIViewController? {
        let nextIndex = imageManager.dysplaingImageIndex + 1
        guard imageManager.images.indices.contains(nextIndex) else { return nil }
        let viewController = IFImageViewController(imageManager: imageManager, displayingImageIndex: nextIndex)
        afterViewController = viewController
        return viewController
    }
}

extension IFPageViewController: UIPageViewControllerDelegate {
    func pageViewController(_ pageViewController: UIPageViewController, didFinishAnimating finished: Bool, previousViewControllers: [UIViewController], transitionCompleted completed: Bool) {
        guard completed, let imageViewController = viewControllers?.first as? IFImageViewController else { return }
        imageManager.dysplaingImageIndex = imageViewController.displayingImageIndex
        
        switch viewControllers?.first {
        case afterViewController:
            beforeViewController = previousViewControllers.first as? IFImageViewController
            afterViewController = nil
        case beforeViewController:
            beforeViewController = nil
            afterViewController = previousViewControllers.first as? IFImageViewController
        default:
            break
        }
    }
}

extension IFPageViewController: UIScrollViewDelegate {
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        let progress = (scrollView.contentOffset.x - scrollView.bounds.width) / scrollView.bounds.width
        let direction: UIPageViewController.NavigationDirection = progress < 0 ? .reverse : .forward
        let normalizedProgress = min(max(abs(progress), 0), 1)
        progressDelegate?.pageViewController(self, didScrollFrom: imageManager.dysplaingImageIndex, direction: direction, progress: normalizedProgress)
    }
}
