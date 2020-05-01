//
//  IFCollectionView.swift
//  ImageUI
//
//  Created by Alberto Saltarelli on 01/05/2020.
//

import Foundation

protocol IFCollectionViewDelegate: UICollectionViewDelegate {
    func collectionViewDidTouch(_ collectionView: UICollectionView)
}

class IFCollectionView: UICollectionView {
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        (delegate as? IFCollectionViewDelegate)?.collectionViewDidTouch(self)
        super.touchesBegan(touches, with: event)
    }
}
