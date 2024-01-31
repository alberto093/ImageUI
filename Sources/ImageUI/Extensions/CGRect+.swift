//
//  CGRect+.swift
//
//
//  Created by Alberto Saltarelli on 22/01/24.
//

import Foundation

extension CGRect {
    func containsIncludingBorders(_ point: CGPoint) -> Bool {
        return !(point.x < minX || point.x > maxX || point.y < minY || point.y > maxY)
    }
}
