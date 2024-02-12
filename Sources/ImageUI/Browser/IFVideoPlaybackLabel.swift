//
//  IFVideoPlaybackLabel.swift
//
//
//  Created by Alberto Saltarelli on 12/02/24.
//

import Foundation
import UIKit

class IFVideoPlaybackLabel: UILabel {
    
    var defaultOrigin: CGPoint = .zero
    
    func resetToDefaultPosition() {
        frame.origin = defaultOrigin
    }
}
