//
//  IFCollectionView.swift
//  ImageUI
//
//  Created by Alberto Saltarelli on 01/05/2020.
//

import Foundation

protocol IFCollectionViewDelegate: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, touchBegan itemIndexPath: IndexPath?)
}

class IFCollectionView: UICollectionView {
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        if let touch = touches.first, let indexPath = indexPathForItem(at: touch.location(in: self)) {
            (delegate as? IFCollectionViewDelegate)?.collectionView(self, touchBegan: indexPath)
        } else {
            (delegate as? IFCollectionViewDelegate)?.collectionView(self, touchBegan: nil)
        }
        super.touchesBegan(touches, with: event)
    }
}
