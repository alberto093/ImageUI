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
import Photos

#if canImport(LinkPresentation)
import LinkPresentation
#endif

class IFImageManager {
    private(set) var images: [IFImage]
    private let pipeline = ImagePipeline()
    let photosManager = PHCachingImageManager()
    
    var prefersAspectFillZoom = false
    var placeholderImage: UIImage?
    private var previousDisplayingImageIndex: Int?
    private(set) var displayingImageIndex: Int {
        didSet { previousDisplayingImageIndex = oldValue }
    }
    
    @available(iOS 13.0, *)
    private lazy var displayingLinkMetadata: LPLinkMetadata? = nil
    private var linkMetadataTask: ImageTask? {
        didSet { oldValue?.cancel() }
    }
    
    private var assetMetadataTaskID: PHImageRequestID? {
        didSet { oldValue.map(photosManager.cancelImageRequest) }
    }
    
    private var assetHighQualityRequestID: PHImageRequestID? {
        didSet { oldValue.map(photosManager.cancelImageRequest) }
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
    
    func removeDisplayingImage() {
        let removingIndex = displayingImageIndex
        let displayingIndex = (previousDisplayingImageIndex ?? removingIndex) > removingIndex ? removingIndex - 1 : removingIndex
        images.remove(at: removingIndex)
        updatedisplayingImage(index: min(max(displayingIndex, 0), images.count - 1))
    }
    
    func loadImage(
        at index: Int,
        options: IFImage.LoadOptions,
        sender: ImageDisplayingView,
        completion: ((IFImage.Result) -> Void)? = nil) {
        
        guard let image = images[safe: index] else { return }
        
        switch image[options.kind] {
        case .image(let image):
            sender.nuke_display(image: image)
            completion?(.success((options.kind, image)))

        case .asset(let asset):
            // Required
            let preferredSize = options.preferredSize.map { CGSize(width: $0.width * UIScreen.main.scale, height: $0.height * UIScreen.main.scale) }
            let size = preferredSize ?? CGSize(width: asset.pixelWidth, height: asset.pixelHeight)
            let request = PHImageRequestOptions()

            if options.preferredSize == nil {
                request.resizeMode = .none
            }
            
            request.deliveryMode = options.deliveryMode
            request.isNetworkAccessAllowed = true
            
            let requestID = self.photosManager.requestImage(for: asset, targetSize: size, contentMode: .aspectFit, options: request) { image, userInfo in
                if let image = image {
                    sender.nuke_display(image: image)

                    if (userInfo?[PHImageResultIsDegradedKey] as? NSNumber)?.boolValue == true {
                        completion?(.success((kind: .thumbnail, resource: image)))
                    } else {
                        completion?(.success((kind: .original, resource: image)))
                    }
                } else {
                    if (userInfo?[PHImageCancelledKey] as? NSNumber)?.boolValue == true {
                        completion?(.failure(IFError.cancelled))
                    } else if let error = userInfo?[PHImageErrorKey] as? Error {
                        completion?(.failure(error))
                    } else {
                        completion?(.failure(IFError.failed))
                    }
                }
            }
            
            if options.kind == .original {
                assetHighQualityRequestID = requestID
            }
        case .url(let url):
            let priority: ImageRequest.Priority
            
            if index == displayingImageIndex {
                priority = options.kind == .original ? .veryHigh : .high
            } else {
                priority = .normal
            }

            let request = ImageRequest(
                url: url,
                processors: options.preferredSize.map { [ImageProcessors.Resize(size: $0)] } ?? [],
                priority: priority)

            var loadingOptions = ImageLoadingOptions(
                placeholder: image.placeholder ?? placeholderImage,
                transition: .fadeIn(duration: 0.1, options: .curveEaseOut))
            loadingOptions.pipeline = pipeline

            Nuke.loadImage(with: request, options: loadingOptions, into: sender, completion: { result in
                completion?(result.map { (options.kind, $0.image) }.mapError { $0 })
            })
        }
    }
    
    private func thumbnailImage(at index: Int) -> UIImage? {
        guard let thumbnail = images[safe: index]?.thumbnail else { return nil }
        switch thumbnail {
        case .url(let url):
            return pipeline.cachedImage(for: url)?.image
        case .image(let image):
            return image
        case .asset:
            return nil
        }
    }
    
    func sharingImage(forImageAt index: Int, completion: @escaping (Result<IFSharingImage, Error>) -> Void) {
        guard let image = images[safe: index] else { return }

        let prepareSharingImage = { [weak self] (result: Result<UIImage, Error>) in
            let sharingResult: Result<IFSharingImage, Error> = result
                .map {
                    if #available(iOS 13.0, *) {
                        self?.prepareDisplayingMetadataIfNeeded()
                        return IFSharingImage(container: image, image: $0, metadata: self?.displayingLinkMetadata)
                    } else {
                        return IFSharingImage(container: image, image: $0)
                    }
                }.mapError { $0 }

            completion(sharingResult)
        }
        
        switch image[.original] {
        case .url(let url):
            pipeline.loadImage(with: url, completion: { result in
                prepareSharingImage(result.map { $0.image }.mapError { $0 })
            })
        case .image(let image):
            prepareSharingImage(.success(image))
        case .asset(let asset):
            let request = PHImageRequestOptions()
            request.deliveryMode = .highQualityFormat
            let size = CGSize(width: asset.pixelWidth, height: asset.pixelHeight)
            
            photosManager.requestImage(for: asset, targetSize: size, contentMode: .aspectFit, options: request) { image, userInfo in
                if let image = image {
                    prepareSharingImage(.success(image))
                } else {
                    if (userInfo?[PHImageCancelledKey] as? NSNumber)?.boolValue == true {
                        completion(.failure(IFError.cancelled))
                    } else if let error = userInfo?[PHImageErrorKey] as? Error {
                        completion(.failure(error))
                    } else {
                        completion(.failure(IFError.failed))
                    }
                }
            }
        }
    }
}

@available(iOS 13.0, *)
extension IFImageManager {
    private func prepareDisplayingMetadataIfNeeded() {
        guard displayingLinkMetadata?.imageProvider == nil else { return }
        prepareDisplayingMetadata()
    }
    
    private func prepareDisplayingMetadata() {
        guard let image = images[safe: displayingImageIndex] else { return }
        let metadata = LPLinkMetadata()
        metadata.title = image.title
        
        switch image[.original] {
        case .url(let url):
            metadata.originalURL = url
            let request = ImageRequest(url: url, priority: .low)
            assetMetadataTaskID = nil
            linkMetadataTask = pipeline.loadImage(with: request, completion: { result in
                if case .success(let response) = result {
                    let provider = NSItemProvider(object: response.image)
                    metadata.imageProvider = provider
                    metadata.iconProvider = provider
                }
            })
        case .image(let image):
            linkMetadataTask = nil
            assetMetadataTaskID = nil
            let provider = NSItemProvider(object: image)
            metadata.imageProvider = provider
            metadata.iconProvider = provider
        case .asset(let asset):
            linkMetadataTask = nil
            
            let request = PHImageRequestOptions()
            request.deliveryMode = .highQualityFormat
            let size = CGSize(width: asset.pixelWidth, height: asset.pixelHeight)
            
            assetMetadataTaskID = photosManager.requestImage(for: asset, targetSize: size, contentMode: .aspectFit, options: request) { image, userInfo in
                if let image = image {
                    let provider = NSItemProvider(object: image)
                    metadata.imageProvider = provider
                    metadata.iconProvider = provider
                }
            }
        }
        
        self.displayingLinkMetadata = metadata
    }
}
