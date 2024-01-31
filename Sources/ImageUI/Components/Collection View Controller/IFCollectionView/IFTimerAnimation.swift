//
//  IFTimerAnimation.swift
//
//
//  Created by Alberto Saltarelli on 22/01/24.
//

import Foundation
import QuartzCore

final class IFTimerAnimation {

    typealias Animations = (_ progress: Double, _ time: TimeInterval) -> Void
    typealias Completion = (_ finished: Bool) -> Void
    
    init(duration: TimeInterval, animations: @escaping Animations, completion: Completion? = nil) {
        self.duration = duration
        self.animations = animations
        self.completion = completion

        firstFrameTimestamp = CACurrentMediaTime()
        
        let displayLink = CADisplayLink(target: self, selector: #selector(handleFrame(_:)))
        displayLink.add(to: .main, forMode: RunLoop.Mode.common)
        self.displayLink = displayLink
    }

    deinit {
        invalidate()
    }
    
    func invalidate() {
        guard isRunning else { return }
        isRunning = false
        completion?(false)
        displayLink?.invalidate()
    }

    private let duration: TimeInterval
    private let animations: Animations
    private let completion: Completion?
    private weak var displayLink: CADisplayLink?

    private(set) var isRunning: Bool = true

    private let firstFrameTimestamp: CFTimeInterval

    @objc private func handleFrame(_ displayLink: CADisplayLink) {
        guard isRunning else { return }
        let elapsed = CACurrentMediaTime() - firstFrameTimestamp
        if elapsed >= duration {
            animations(1, duration)
            isRunning = false
            completion?(true)
            displayLink.invalidate()
        } else {
            animations(elapsed / duration, elapsed)
        }
    }
}
