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
    let pipeline: ImagePipeline
    
    var prefersAspectFillZoom = false
    var placeholderImage: UIImage?
    var dysplaingImageIndex = 0
    @available(iOS 13.0, *)
    private(set) lazy var dysplaingLinkMetadata = LPLinkMetadata()
    
    private let dataCache: DataCache? = {
        let dataCache = try? DataCache(name: "org.cocoapods.ImageUI.dataCache")
        dataCache?.countLimit = 3
        dataCache?.sweepInterval = 5
        return dataCache
    }()
    
    init(images: [IFImage], initialImageIndex: Int = 0) {
        self.images = images
        self.dysplaingImageIndex = min(max(initialImageIndex, 0), images.count - 1)
        var configuration = ImagePipeline.Configuration(dataLoader: IFImageLoader())
        configuration.dataCache = dataCache
        self.pipeline = ImagePipeline(configuration: configuration)
    }
    
    func updateDysplaingImage(index: Int) {
        guard images.indices.contains(index) else { return }
        dysplaingImageIndex = index

        if #available(iOS 13.0, *) {
            let metadata = LPLinkMetadata()
            let image = images[index]
            metadata.title = image.title
            metadata.originalURL = image.url
            let provider = NSItemProvider(contentsOf: image.url)
            metadata.imageProvider = provider
            metadata.iconProvider = provider
        }
    }
    
    func loadImage(
        at index: Int,
        preferredSize: CGSize? = nil,
        sender: ImageDisplayingView,
        completion: ((Result<UIImage, Error>) -> Void)? = nil) {
        
        guard let image = images[safe: index] else { return }
        let priority: ImageRequest.Priority
        
        if index == dysplaingImageIndex {
            priority = preferredSize == nil ? .veryHigh : .high
        } else {
            priority = .normal
        }
        
        let request = ImageRequest(
            url: image.url,
            processors: preferredSize.map { [ImageProcessor.Resize(size: $0)] } ?? [],
            priority: priority)

        var options = ImageLoadingOptions(
            placeholder: placeholderImage,
            transition: .fadeIn(duration: 0.1, options: .curveEaseOut))
        options.pipeline = pipeline
        Nuke.loadImage(with: request, options: options, into: sender) { result in
            completion?(result.map { $0.image }.mapError { $0 })
        }
    }
}
