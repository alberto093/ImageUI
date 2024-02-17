//
//  IFCollectionViewPanGestureHandler.swift
//
//
//  Created by Alberto Saltarelli on 22/01/24.
//

import Foundation
import UIKit

protocol IFCollectionViewPanGestureHandlerDataSource: AnyObject {
    func collectionViewPanGestureHandlerRubberBounds(_ collectionViewPanGestureHandler: IFCollectionViewPanGestureHandler) -> CGRect?
}

protocol IFCollectionViewPanGestureHandlerDelegate: AnyObject {
    func collectionViewPanGestureHandlerDidEndDecelerating(_ collectionViewPanGestureHandler: IFCollectionViewPanGestureHandler)
}

class IFCollectionViewPanGestureHandler {
    private struct Constants {
        static let autoInvalidationInset: CGFloat = 10
    }
    
    weak var dataSource: IFCollectionViewPanGestureHandlerDataSource?
    weak var delegate: IFCollectionViewPanGestureHandlerDelegate?
    
    private weak var collectionView: UICollectionView?
    
    private var rubberBounds: CGRect?
    private var initialContentOffset: CGPoint = .zero
    private var videoContentOffset: CGPoint = .zero
    private var lastPanGestureDate: Date?
    
    var isInvalidated = false
    private var allowsAutoInvalidation = true
    
    var isDecelerating: Bool {
        contentOffsetAnimation?.isRunning == true
    }
    
    private var contentOffsetAnimation: IFTimerAnimation? {
        didSet {
            oldValue?.invalidate()
        }
    }
    
    init(collectionView: UICollectionView) {
        self.collectionView = collectionView
        collectionView.panGestureRecognizer.addTarget(self, action: #selector(panGestureDidChange))
    }
    
    deinit {
        contentOffsetAnimation = nil
    }
    
    func invalidateDataSource() {
        guard let collectionView else { return }
        
        contentOffsetAnimation = nil
        initialContentOffset = collectionView.contentOffset
        rubberBounds = dataSource?.collectionViewPanGestureHandlerRubberBounds(self)
        allowsAutoInvalidation = true
    }
    
    private func completeGesture(velocity: CGPoint) {
        guard let collectionView, let rubberBounds else { return }
        if rubberBounds.containsIncludingBorders(collectionView.contentOffset) {
            decelerate(velocity: velocity)
        } else {
            bounce(velocity: velocity)
        }
    }
    
    private func decelerate(velocity: CGPoint) {
        guard let collectionView, let rubberBounds else { return }
        
        let parameters = DecelerationTimingParameters(
            initialValue: collectionView.contentOffset,
            initialVelocity: CGPoint(x: velocity.x, y: 0),
            decelerationRate: UIScrollView.DecelerationRate.normal.rawValue,
            threshold: 0.5)
        
        let destination = parameters.destination
        let intersection = intersection(rect: rubberBounds, segment: (collectionView.contentOffset, destination))
        
        let duration: TimeInterval
        
        if let intersection = intersection, let intersectionDuration = parameters.duration(to: intersection) {
            duration = intersectionDuration
        } else {
            duration = parameters.duration
        }
        
        contentOffsetAnimation = IFTimerAnimation(
            duration: duration,
            animations: { [weak collectionView] _, time in
                collectionView?.contentOffset.x = parameters.value(at: time).x
            },
            completion: { [weak self] completed in
                guard let self, completed else { return }
                
                if intersection != nil {
                    let velocity = parameters.velocity(at: duration)
                    self.bounce(velocity: velocity)
                } else {
                    self.delegate?.collectionViewPanGestureHandlerDidEndDecelerating(self)
                }
            })
    }
    
    private func bounce(velocity: CGPoint) {
        guard let collectionView, let rubberBounds else { return }
        
        let restOffset = collectionView.contentOffset.clamped(to: rubberBounds)
        let displacement = collectionView.contentOffset - restOffset
        let threshold = 0.5 / UIScreen.main.scale
        let spring = IFSpring(mass: 1, stiffness: 100, dampingRatio: 1)
        
        let parameters = IFSpringTimingParameters(
            spring: spring,
            displacement: displacement,
            initialVelocity: velocity,
            threshold: threshold)
        
        contentOffsetAnimation = IFTimerAnimation(
            duration: parameters.duration,
            animations: { [weak collectionView] _, time in
                collectionView?.contentOffset.x = (restOffset + parameters.value(at: time)).x
            },
            completion: { [weak self] completed in
                guard let self, completed else { return }
                self.delegate?.collectionViewPanGestureHandlerDidEndDecelerating(self)
            })
    }
    
    @objc private func panGestureDidChange(_ sender: UIPanGestureRecognizer) {
        guard let collectionView, sender.state == .began || rubberBounds != nil else { return }
        
        let panDate = Date()
        
        switch sender.state {
        case .began:
            invalidateDataSource()
            
            if let rubberBounds {
                isInvalidated = initialContentOffset.x < rubberBounds.minX || initialContentOffset.x > rubberBounds.maxX
            } else {
                isInvalidated = true
            }
        case .changed:
            if let rubberBounds {
                let translation = sender.translation(in: collectionView)
                let proposedContentOffset = CGPoint(x: initialContentOffset.x - translation.x, y: initialContentOffset.y)
                let autoInvalidationFrame = rubberBounds.insetBy(dx: Constants.autoInvalidationInset, dy: 0)
                
                if allowsAutoInvalidation {
                    if initialContentOffset.x < autoInvalidationFrame.minX, proposedContentOffset.x < autoInvalidationFrame.minX {
                        isInvalidated = true
                    } else if initialContentOffset.x > autoInvalidationFrame.maxX, proposedContentOffset.x > autoInvalidationFrame.maxX {
                        isInvalidated = true
                    } else {
                        allowsAutoInvalidation = false
                        isInvalidated = initialContentOffset.x < rubberBounds.minX || initialContentOffset.x > rubberBounds.maxX
                    }
                } else {
                    isInvalidated = initialContentOffset.x < rubberBounds.minX || initialContentOffset.x > rubberBounds.maxX
                }
                
                if !isInvalidated {
                    let rubberBand = IFRubberBand(dims: rubberBounds.size, bounds: rubberBounds)
                    collectionView.contentOffset.x = rubberBand.clamp(proposedContentOffset).x
                }
            } else {
                isInvalidated = true
            }
        case .ended, .cancelled:
            if !isInvalidated {
                collectionView.setContentOffset(collectionView.contentOffset, animated: false)
                
                let dragDidStop = panDate.timeIntervalSince(lastPanGestureDate ?? panDate) >= 0.1
                let velocity = dragDidStop ? .zero : sender.velocity(in: collectionView)
                
                completeGesture(velocity: -velocity)
            }
        case  .possible, .failed, .recognized:
            break
        @unknown default:
            fatalError()
        }
        
        lastPanGestureDate = panDate
    }
}

private extension IFCollectionViewPanGestureHandler {
    func intersection(segment1: (CGPoint, CGPoint), segment2: (CGPoint, CGPoint)) -> CGPoint? {
        let p1 = segment1.0
        let p2 = segment1.1
        let p3 = segment2.0
        let p4 = segment2.1
        let d = (p2.x - p1.x) * (p4.y - p3.y) - (p2.y - p1.y) * (p4.x - p3.x)
        
        if d == 0 {
            return nil // parallel lines
        }
        
        let u = ((p3.x - p1.x) * (p4.y - p3.y) - (p3.y - p1.y) * (p4.x - p3.x)) / d
        let v = ((p3.x - p1.x) * (p2.y - p1.y) - (p3.y - p1.y) * (p2.x - p1.x)) / d
        
        if u < 0.0 || u > 1.0 {
            return nil // intersection point is not between p1 and p2
        }
        
        if v < 0.0 || v > 1.0 {
            return nil // intersection point is not between p3 and p4
        }
        
        return CGPoint(x: p1.x + u * (p2.x - p1.x), y: p1.y + u * (p2.y - p1.y))
    }
    
    func intersection(rect: CGRect, segment: (CGPoint, CGPoint)) -> CGPoint? {
        let rMinMin = CGPoint(x: rect.minX, y: rect.minY)
        let rMinMax = CGPoint(x: rect.minX, y: rect.maxY)
        let rMaxMin = CGPoint(x: rect.maxX, y: rect.minY)
        let rMaxMax = CGPoint(x: rect.maxX, y: rect.maxY)
        
        if let point = intersection(segment1: (rMinMin, rMinMax), segment2: segment) {
            return point
        }
        if let point = intersection(segment1: (rMinMin, rMaxMin), segment2: segment) {
            return point
        }
        if let point = intersection(segment1: (rMinMax, rMaxMax), segment2: segment) {
            return point
        }
        if let point = intersection(segment1: (rMaxMin, rMaxMax), segment2: segment) {
            return point
        }
        return nil
    }
}
