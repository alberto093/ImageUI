//
//  UIImage+.swift
//
//  Copyright © 2020 ImageUI - Alberto Saltarelli
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.
//

import UIKit

public extension UIImage {
    convenience init?(color: UIColor, size: CGSize = CGSize(width: 1, height: 1)) {
        let image = UIGraphicsImageRenderer(size: size).image { context in
            color.setFill()
            context.fill(CGRect(origin: .zero, size: size))
        }
        
        guard let cgImage = image.cgImage else { return nil }
        self.init(cgImage: cgImage)
    }
}

extension UIImage {
    func resizedToFill(size newSize: CGSize) -> UIImage {
        guard size.width > newSize.width || size.height > newSize.height else { return self }
        
        let ratio = size.width / size.height
        if newSize.width / ratio > newSize.height {
            return resized(to: CGSize(width: newSize.width, height: newSize.width / ratio))
        } else {
            return resized(to: CGSize(width: newSize.height * ratio, height: newSize.height))
        }
    }
    
    func resizedToFit(size newSize: CGSize) -> UIImage {
        guard size.width > newSize.width || size.height > newSize.height else { return self }
        
        let ratio = size.width / size.height
        if newSize.width / ratio < newSize.height {
            return resized(to: CGSize(width: newSize.width, height: newSize.width / ratio))
        } else {
            return resized(to: CGSize(width: newSize.height * ratio, height: newSize.height))
        }
    }
    
    func resized(to size: CGSize) -> UIImage {
        UIGraphicsImageRenderer(size: size).image { _ in
            draw(in: CGRect(origin: .zero, size: size))
        }
    }
}
