//
//  IFSharingImage.swift
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

import MobileCoreServices

#if canImport(LinkPresentation)
import LinkPresentation
import Photos
#endif

class IFSharingImage: NSObject, UIActivityItemSource {
    let container: IFImage
    let image: UIImage
    
    private lazy var metadata: LPLinkMetadata? = nil
    
    init(container: IFImage, image: UIImage) {
        self.container = container
        self.image = image
    }
    
    func activityViewControllerPlaceholderItem(_ activityViewController: UIActivityViewController) -> Any {
        UIImage()
    }
    
    func activityViewController(_ activityViewController: UIActivityViewController, itemForActivityType activityType: UIActivity.ActivityType?) -> Any? {
        image
    }
    
    func activityViewController(_ activityViewController: UIActivityViewController, dataTypeIdentifierForActivityType activityType: UIActivity.ActivityType?) -> String {
        let uti = image.cgImage?.utType ?? kUTTypeImage
        return uti as String
    }

    func activityViewController(_ activityViewController: UIActivityViewController, thumbnailImageForActivityType activityType: UIActivity.ActivityType?, suggestedSize size: CGSize) -> UIImage? {
        image.resizedToFill(size: size)
    }
}

@available(iOS 13.0, *)
extension IFSharingImage {
    convenience init(container: IFImage, image: UIImage, metadata: LPLinkMetadata? = nil) {
        self.init(container: container, image: image)
        self.metadata = metadata
    }
    
    func activityViewControllerLinkMetadata(_ activityViewController: UIActivityViewController) -> LPLinkMetadata? {
        if let metadata = metadata {
            return metadata
        } else {
            let metadata = LPLinkMetadata()
            metadata.title = container.title
            if case .url(let url) = container.original {
                metadata.originalURL = url
            }

            let provider = NSItemProvider(object: image)
            metadata.imageProvider = provider
            metadata.iconProvider = provider
            return metadata
        }
    }
}
