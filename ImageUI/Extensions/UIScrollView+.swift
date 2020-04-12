//
//  UIScrollView+.swift
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

extension UIScrollView {
    var isBouncingHorizontally: Bool {
        let minimumContentOffsetX = -contentInset.left
        let maximumContentOffsetX = contentSize.width + contentInset.left + contentInset.right - bounds.width
        return contentOffset.x <= minimumContentOffsetX || contentOffset.x >= maximumContentOffsetX
    }
    
    var isBouncingVertically: Bool {
        let minimumContentOffsetY = -contentInset.top
        let maximumContentOffsetY = contentSize.height + contentInset.top + contentInset.bottom - bounds.height
        return contentOffset.y <= minimumContentOffsetY || contentOffset.y >= maximumContentOffsetY
    }
    
    /// Returns the time in which scroll view stops its scrolling.
    /// - Parameter velocity: The velocity of the scroll view (in points).
    /// - Parameter threshold: The smallest amount of point to use in the Euler transform.
    /// - Returns: The time in in which scroll view stops its scrolling based on `velocity` parameter.
    ///
    /// The right function is a consequence of the decomposition of the natural logarithm in the Taylor series using the Euler transform:
    ///
    /// T = log(-1000 • ε • log(d) / v) / (1000 • log(d))
    func scrollDuration(velocity: CGPoint, threshold: CGFloat = 0.01) -> TimeInterval {
        let velocityLenght = sqrt(velocity.x * velocity.x + velocity.y * velocity.y)
        guard velocityLenght != 0 else { return 0 }

        let decelerationRate = min(max(self.decelerationRate.rawValue, 0), 1)
        let decelerationMultiplier = 1000 * log(decelerationRate)
        return TimeInterval(log(-decelerationMultiplier * threshold / velocityLenght ) / decelerationMultiplier)
    }
    
    func targetContentOffset(of contentOffset: CGPoint? = nil, velocity: CGPoint) -> CGPoint {
        let decelerationRate = min(max(self.decelerationRate.rawValue, 0), 1)
        let decelerationMultiplier = 1000 * log(decelerationRate) * 0.01
        let offset = contentOffset ?? self.contentOffset
        return CGPoint(x: offset.x - velocity.x / decelerationMultiplier, y: offset.y - velocity.y / decelerationMultiplier)
    }
}
