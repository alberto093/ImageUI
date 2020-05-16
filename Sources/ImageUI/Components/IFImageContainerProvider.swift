//
//  IFImageContainerProvider.swift
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

protocol IFImageContainerProvider: class {
    var imageContainerView: UIView { get }
    func prepareForRemove(completion: (() -> Void)?)
}

extension IFImageContainerProvider {
    func prepareForRemove(completion: (() -> Void)?) {
        let blurPadding: CGFloat = 5 * UIScreen.main.scale
        let animationDuration: TimeInterval = 0.24
        let blurAnimationRate: Double = 1.5
        let alphaAnimationRate: Double = 1.38
        let scaleFactor: CGFloat = 0.18
        
        let blurView = UIVisualEffectView()
        blurView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        blurView.frame = imageContainerView.bounds.insetBy(dx: -blurPadding, dy: -blurPadding)
        blurView.clipsToBounds = false
        imageContainerView.clipsToBounds = false
        imageContainerView.addSubview(blurView)
        
        let blurAnimator = UIViewPropertyAnimator(duration: animationDuration * blurAnimationRate, curve: .easeOut) {
            blurView.effect = UIBlurEffect(style: .prominent)
        }
        
        let scaleAnimator = UIViewPropertyAnimator(duration: animationDuration, curve: .easeOut) {
            self.imageContainerView.transform = CGAffineTransform(scaleX: scaleFactor, y: scaleFactor)
        }
        
        scaleAnimator.addCompletion { _ in completion?() }
        [blurAnimator, scaleAnimator].forEach { $0.startAnimation() }

        UIView.animate(
            withDuration: animationDuration * alphaAnimationRate,
            delay: 0,
            options: .curveEaseOut,
            animations: {
                self.imageContainerView.alpha = 0
            },
            completion: { completed in
                blurAnimator.stopAnimation(true)
                blurView.removeFromSuperview()
        })
    }
}
