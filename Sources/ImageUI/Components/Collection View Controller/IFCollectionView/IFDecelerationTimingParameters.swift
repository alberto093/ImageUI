//
//  IFDecelerationTimingParameters.swift
//  
//
//  Created by Alberto Saltarelli on 22/01/24.
//

import Foundation

struct DecelerationTimingParameters {
    var initialValue: CGPoint
    var initialVelocity: CGPoint
    var decelerationRate: CGFloat
    var threshold: CGFloat
    
    init(initialValue: CGPoint, initialVelocity: CGPoint, decelerationRate: CGFloat, threshold: CGFloat) {
        assert(decelerationRate > 0 && decelerationRate < 1)
        
        self.initialValue = initialValue
        self.initialVelocity = initialVelocity
        self.decelerationRate = decelerationRate
        self.threshold = threshold
    }
}

extension DecelerationTimingParameters {
    
    var destination: CGPoint {
        let dCoeff = 1000 * log(decelerationRate)
        return initialValue - initialVelocity / dCoeff
    }
    
    var duration: TimeInterval {
        guard initialVelocity.length > 0 else { return 0 }
        
        let dCoeff = 1000 * log(decelerationRate)
        return TimeInterval(log(-dCoeff * threshold / initialVelocity.length) / dCoeff)
    }
    
    func value(at time: TimeInterval) -> CGPoint {
        let dCoeff = 1000 * log(decelerationRate)
        return initialValue + (pow(decelerationRate, CGFloat(1000 * time)) - 1) / dCoeff * initialVelocity
    }
    
    func duration(to value: CGPoint) -> TimeInterval? {
        guard value.distance(toSegment: (initialValue, destination)) < threshold else { return nil }
        
        let dCoeff = 1000 * log(decelerationRate)
        return TimeInterval(log(1.0 + dCoeff * (value - initialValue).length / initialVelocity.length) / dCoeff)
    }
    
    func velocity(at time: TimeInterval) -> CGPoint {
        initialVelocity * pow(decelerationRate, CGFloat(1000 * time))
    }
}

struct XDecelerationTimingParameters {
    var initialValue: CGFloat
    var initialVelocity: CGFloat
    var decelerationRate: CGFloat
    var threshold: CGFloat
    
    init(initialValue: CGFloat, initialVelocity: CGFloat, decelerationRate: CGFloat, threshold: CGFloat) {
        assert(decelerationRate > 0 && decelerationRate < 1)
        
        self.initialValue = initialValue
        self.initialVelocity = initialVelocity
        self.decelerationRate = decelerationRate
        self.threshold = threshold
    }
}

extension XDecelerationTimingParameters {
    
    var destination: CGFloat {
        let dCoeff = 1000 * log(decelerationRate)
        return initialValue - initialVelocity / dCoeff
    }
    
    var duration: TimeInterval {
        guard initialVelocity.magnitude > 0 else { return 0 }
        
        let dCoeff = 1000 * log(decelerationRate)
        return TimeInterval(log(-dCoeff * threshold / initialVelocity.magnitude) / dCoeff)
    }
    
    func value(at time: TimeInterval) -> CGFloat {
        let dCoeff = 1000 * log(decelerationRate)
        return initialValue + (pow(decelerationRate, CGFloat(1000 * time)) - 1) / dCoeff * initialVelocity
    }
    
    func duration(to value: CGFloat) -> TimeInterval? {
        guard abs(value - initialValue) < threshold else { return nil }
        
        let dCoeff = 1000 * log(decelerationRate)
        return TimeInterval(log(1.0 + dCoeff * abs(value - initialValue) / initialVelocity.magnitude) / dCoeff)
    }
    
    func velocity(at time: TimeInterval) -> CGFloat {
        initialVelocity * pow(decelerationRate, CGFloat(1000 * time))
    }
}
