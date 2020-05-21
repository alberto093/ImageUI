//
//  IFImage+Fetching.swift
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
import Photos

extension IFImage.Source {
    var url: URL? {
        switch self {
        case .url(let url):
            return url
        case .image:
            return nil
        }
    }
}

extension IFImage {
    enum Kind {
        case original
        case thumbnail
    }
    
    subscript(kind: Kind) -> Source {
        switch kind {
        case .original:
            return original
        case .thumbnail:
            return thumbnail ?? original
        }
    }
}

extension IFImage {
    struct LoadOptions {
        enum DeliveryMode {
            case highQuality
            case opportunistic
        }
        
        let preferredSize: CGSize?
        let kind: Kind
        let deliveryMode: DeliveryMode
        
        var allowsThumbnail: Bool {
            kind == .original && deliveryMode == .opportunistic
        }
        
        init(preferredSize: CGSize? = nil, kind: Kind, deliveryMode: DeliveryMode = .opportunistic) {
            self.preferredSize = preferredSize
            self.kind = kind
            self.deliveryMode = deliveryMode
        }
    }
    
    typealias Result = Swift.Result<(kind: Kind, resource: UIImage), Error>
}
