//
//  IFSpringTimeParameters.swift
//
//
//  Created by Alberto Saltarelli on 22/01/24.
//

import Foundation

/// https://en.wikipedia.org/wiki/Harmonic_oscillator
///
/// System's equation of motion:
///
/// 0 < dampingRatio < 1:
/// x(t) = exp(-beta * t) * (c1 * sin(w' * t) + c2 * cos(w' * t))
/// c1 = x0
/// c2 = (v0 + beta * x0) / w'
///
/// dampingRatio == 1:
/// x(t) = exp(-beta * t) * (c1 + c2 * t)
/// c1 = x0
/// c2 = (v0 + beta * x0)
///
/// x0 - initial displacement
/// v0 - initial velocity
/// beta = damping / (2 * mass)
/// w0 = sqrt(stiffness / mass) - natural frequency
/// w' = sqrt(w0 * w0 - beta * beta) - damped natural frequency

struct IFSpring {
    var mass: CGFloat
    var stiffness: CGFloat
    var dampingRatio: CGFloat
    
    init(mass: CGFloat, stiffness: CGFloat, dampingRatio: CGFloat) {
        self.mass = mass
        self.stiffness = stiffness
        self.dampingRatio = dampingRatio
    }
}

extension IFSpring {
    
    var `default`: IFSpring {
        IFSpring(mass: 1, stiffness: 200, dampingRatio: 1)
    }
}

extension IFSpring {
    
    var damping: CGFloat {
        2 * dampingRatio * sqrt(mass * stiffness)
    }
    
    var beta: CGFloat {
        damping / (2 * mass)
    }
    
    var dampedNaturalFrequency: CGFloat {
        sqrt(stiffness / mass) * sqrt(1 - dampingRatio * dampingRatio)
    }
}

protocol IFTimingParameters {
    var duration: TimeInterval { get }
    func value(at time: TimeInterval) -> CGPoint
}

struct IFSpringTimingParameters {
    let spring: IFSpring
    let displacement: CGPoint
    let initialVelocity: CGPoint
    let threshold: CGFloat
    private let impl: IFTimingParameters
        
    init(spring: IFSpring, displacement: CGPoint, initialVelocity: CGPoint, threshold: CGFloat) {
        self.spring = spring
        self.displacement = displacement
        self.initialVelocity = initialVelocity
        self.threshold = threshold
        
        if spring.dampingRatio == 1 {
            impl = IFCriticallyDampedSpringTimingParameters(
                spring: spring,
                displacement: displacement,
                initialVelocity: initialVelocity,
                threshold: threshold)
        } else if spring.dampingRatio > 0 && spring.dampingRatio < 1 {
            impl = IFUnderdampedSpringTimingParameters(
                spring: spring,
                displacement: displacement,
                initialVelocity: initialVelocity,
                threshold: threshold)
        } else {
            fatalError("dampingRatio should be greater than 0 and less than or equal to 1")
        }
    }
}

extension IFSpringTimingParameters: IFTimingParameters {
    
    var duration: TimeInterval {
        impl.duration
    }
    
    func value(at time: TimeInterval) -> CGPoint {
        impl.value(at: time)
    }
}

// MARK: - Private Impl

 
private struct IFUnderdampedSpringTimingParameters {
    let spring: IFSpring
    let displacement: CGPoint
    let initialVelocity: CGPoint
    let threshold: CGFloat
}

extension IFUnderdampedSpringTimingParameters: IFTimingParameters {
    
    var duration: TimeInterval {
        if displacement.length == 0 && initialVelocity.length == 0 {
            return 0
        }
        
        return TimeInterval(log((c1.length + c2.length) / threshold) / spring.beta)
    }
    
    func value(at time: TimeInterval) -> CGPoint {
        let t = CGFloat(time)
        let wd = spring.dampedNaturalFrequency
        return exp(-spring.beta * t) * (c1 * cos(wd * t) + c2 * sin(wd * t))
    }

    // MARK: - Private
    
    private var c1: CGPoint {
        displacement
    }
    
    private var c2: CGPoint {
        (initialVelocity + spring.beta * displacement) / spring.dampedNaturalFrequency
    }
    
}

private struct IFCriticallyDampedSpringTimingParameters {
    let spring: IFSpring
    let displacement: CGPoint
    let initialVelocity: CGPoint
    let threshold: CGFloat
}

extension IFCriticallyDampedSpringTimingParameters: IFTimingParameters {
    
    var duration: TimeInterval {
        if displacement.length == 0 && initialVelocity.length == 0 {
            return 0
        }
        
        let b = spring.beta
        let e = CGFloat(M_E)
         
        let t1 = 1 / b * log(2 * c1.length / threshold)
        let t2 = 2 / b * log(4 * c2.length / (e * b * threshold))
        
        return TimeInterval(max(t1, t2))
    }
    
    func value(at time: TimeInterval) -> CGPoint {
        let t = CGFloat(time)
        return exp(-spring.beta * t) * (c1 + c2 * t)
    }

    // MARK: - Private
    
    private var c1: CGPoint {
        displacement
    }
    
    private var c2: CGPoint {
        initialVelocity + spring.beta * displacement
    }
}

