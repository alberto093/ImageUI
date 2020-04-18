//
//  IFSharingImage.swift
//  ImageUI
//
//  Created by Alberto Saltarelli on 18/04/2020.
//

import MobileCoreServices
import Nuke

class IFSharingImage: NSObject, UIActivityItemSource {
    let source: IFImage
    let image: UIImage
    
    init(source: IFImage, image: UIImage) {
        self.source = source
        self.image = image
    }
    
    func activityViewControllerPlaceholderItem(_ activityViewController: UIActivityViewController) -> Any {
        image
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

#if canImport(LinkPresentation)

import LinkPresentation

extension IFSharingImage {
    @available(iOS 13.0, *)
    func activityViewControllerLinkMetadata(_ activityViewController: UIActivityViewController) -> LPLinkMetadata? {
        let metadata = LPLinkMetadata()
        metadata.title = source.title
        metadata.imageProvider = NSItemProvider(object: image)
        metadata.iconProvider = NSItemProvider(object: image)
        return metadata
    }
}

#endif
