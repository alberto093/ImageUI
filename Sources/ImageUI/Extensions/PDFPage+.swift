//
//  PDFPage+.swift
//
//
//  Created by Alberto Saltarelli on 27/02/24.
//

import Foundation
import PDFKit

extension PDFPage {
    var asImage: UIImage {
        let pdfPageSize = bounds(for: .mediaBox)
        let renderer = UIGraphicsImageRenderer(size: pdfPageSize.size)
        
        return renderer.image { context in
            UIColor.white.set()
            context.fill(pdfPageSize)
            context.cgContext.translateBy(x: 0.0, y: pdfPageSize.size.height)
            context.cgContext.scaleBy(x: 1.0, y: -1.0)
            
            draw(with: .mediaBox, to: context.cgContext)
        }
    }
}
