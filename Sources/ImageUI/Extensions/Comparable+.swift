//
//  Comparable+.swift
//  
//
//  Created by Alberto Saltarelli on 22/01/24.
//

import Foundation

extension Comparable {
    func clamped(to limits: ClosedRange<Self>) -> Self {
        min(max(self, limits.lowerBound), limits.upperBound)
    }
}
