//
//  IFCollectionView.swift
//
//
//  Created by Alberto Saltarelli on 26/01/24.
//

import Foundation
import UIKit

protocol IFCollectionViewDelegate: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didTap location: CGPoint)
}

class IFCollectionView: UICollectionView {
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesBegan(touches, with: event)

        if let touch = touches.first {
            (delegate as? IFCollectionViewDelegate)?.collectionView(self, didTap: touch.location(in: self))
        }
    }
}
