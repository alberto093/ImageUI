//
//  IFImageManager.swift
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

import Nuke

#if canImport(LinkPresentation)
import LinkPresentation
#endif

class IFImageManager {
    let images: [IFImage]
    private let pipeline = ImagePipeline()
    
    var prefersAspectFillZoom = false
    var placeholderImage: UIImage?
    private(set) var displayingImageIndex = 0
    
    @available(iOS 13.0, *)
    private lazy var displayingLinkMetadata: LPLinkMetadata? = nil
    private var linkMetadataTask: ImageTask? {
        didSet { oldValue?.cancel() }
    }
    
    init(images: [IFImage], initialImageIndex: Int = 0) {
        self.images = images
        self.displayingImageIndex = min(max(initialImageIndex, 0), images.count - 1)

        if #available(iOS 13.0, *) {
            prepareDisplayingMetadata()
        }
    }
    
    func updatedisplayingImage(index: Int) {
        guard images.indices.contains(index) else { return }
        displayingImageIndex = index
        
        if #available(iOS 13.0, *) {
            prepareDisplayingMetadata()
        }
    }
    
    func loadImage(
        at index: Int,
        preferredSize: CGSize? = nil,
        kind: IFImage.Kind,
        sender: ImageDisplayingView,
        completion: ((Result<UIImage, Error>) -> Void)? = nil) {
        
        guard let image = images[safe: index] else { return }
        let priority: ImageRequest.Priority
        
        if index == displayingImageIndex {
            priority = preferredSize == nil ? .veryHigh : .high
        } else {
            priority = .normal
        }
        
        let request = ImageRequest(
            url: image[kind].url,
            processors: preferredSize.map { [ImageProcessor.Resize(size: $0)] } ?? [],
            priority: priority)

        var options = ImageLoadingOptions(
            placeholder: image.placeholder ?? placeholderImage,
            transition: .fadeIn(duration: 0.1, options: .curveEaseOut))
        options.pipeline = pipeline
        Nuke.loadImage(with: request, options: options, into: sender) { result in
            completion?(result.map { $0.image }.mapError { $0 })
        }
    }
    
    func sharingImage(forImageAt index: Int, completion: @escaping (Result<IFSharingImage, Error>) -> Void) {
        guard let image = images[safe: index] else { return }
        pipeline.loadImage(with: image.original.url) { [weak self] result in
            guard let self = self else { return }
            let sharingResult: Result<IFSharingImage, Error> = result
                .map {
                    if #available(iOS 13.0, *) {
                        return IFSharingImage(container: image, image: $0.image, metadata: self.displayingLinkMetadata)
                    } else {
                        return IFSharingImage(container: image, image: $0.image)
                    }
                }.mapError { $0 }
            
            completion(sharingResult)
        }
    }
}

@available(iOS 13.0, *)
extension IFImageManager {
    private func prepareDisplayingMetadata() {
        guard let image = images[safe: displayingImageIndex] else { return }
        let metadata = LPLinkMetadata()
        metadata.title = image.title
        metadata.originalURL = image.original.url
        
        let request = ImageRequest(url: image.original.url, priority: .low)
        linkMetadataTask = pipeline.loadImage(with: request) { result in
            if case .success(let response) = result {
                let provider = NSItemProvider(object: response.image)
                metadata.imageProvider = provider
                metadata.iconProvider = provider
            }
        }

        self.displayingLinkMetadata = metadata
    }
}
