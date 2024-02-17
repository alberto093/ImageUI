//
//  IFCollectionView.swift
//
//
//  Created by Alberto Saltarelli on 26/01/24.
//

import Foundation
import UIKit

protocol IFCollectionViewDelegate: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, touchesBegan location: CGPoint)
    func collectionView(_ collectionView: UICollectionView, touchesEnded location: CGPoint)
}

class IFCollectionView: UICollectionView {
    
    private(set) lazy var videoHandler = IFCollectionViewPanGestureHandler(collectionView: self)

    override var isDecelerating: Bool {
        super.isDecelerating || videoHandler.isDecelerating
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesBegan(touches, with: event)

        if let touch = touches.first {
            (delegate as? IFCollectionViewDelegate)?.collectionView(self, touchesBegan: touch.location(in: self))
        }
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesEnded(touches, with: event)
        
        if let touch = touches.first {
            (delegate as? IFCollectionViewDelegate)?.collectionView(self, touchesEnded: touch.location(in: self))
        }
    }
}
