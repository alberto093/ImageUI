//
//  IFImage+Fetching.swift
//  
//
//  Created by Alberto Saltarelli on 10/05/2020.
//

import UIKit
import Photos

extension IFImage.Source {
    var url: URL? {
        switch self {
        case .local(let path):
            return URL(fileURLWithPath: path)
        case .remote(let url):
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
