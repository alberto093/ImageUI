//
//  IFCollectionViewAnimator.swift
//  ImageUI
//
//  Created by Alberto Saltarelli on 29/04/2020.
//

import Foundation

class IFCollectionViewAnimator {
    private struct Constants {
        static let previewingDuration: TimeInterval = 0.28
        static let normalizingDuration: TimeInterval = 0.36
        static let previewingBezierCurvePoints = (CGPoint.zero, CGPoint(x: 0.55, y: 1))
        static let normalizingBezierCurvePoints = (CGPoint.zero, CGPoint(x: 0.51, y: 1))
    }
    
    private(set) weak var collectionView: UICollectionView?
    private var propertyAnimator: UIViewPropertyAnimator?
    
    init(collectionView: UICollectionView) {
        self.collectionView = collectionView
    }
    
    func startAnimation(flowLayout: IFCollectionViewFlowLayout) {
        let duration: TimeInterval
        let curvePoints: (CGPoint, CGPoint)
        
        switch flowLayout.style {
        case .normal:
            duration = Constants.normalizingDuration
            curvePoints = Constants.normalizingBezierCurvePoints
        case .preview:
            duration = Constants.previewingDuration
            curvePoints = Constants.previewingBezierCurvePoints
        }
        
        let animator = UIViewPropertyAnimator(duration: duration, controlPoint1: curvePoints.0, controlPoint2: curvePoints.1) {
            self.collectionView?.setCollectionViewLayout(flowLayout, animated: true)
        }
        animator.startAnimation()
        self.propertyAnimator = animator
    }
    
    @discardableResult func finishRunningAnimation(at position: UIViewAnimatingPosition) -> Bool {
        guard let animator = propertyAnimator, animator.state == .active else { return false }
        animator.stopAnimation(false)
        animator.finishAnimation(at: position)
        return true
    }
}
