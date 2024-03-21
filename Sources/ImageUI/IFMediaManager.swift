//
//  IFMediaManager.swift
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

import Combine
import Nuke
import NukeUI
import NukeExtensions
import Photos
import PDFKit
import CoreServices

#if canImport(LinkPresentation)
import LinkPresentation
#endif

class IFMediaManager {
    private(set) var media: [IFMedia]
    var configuration: IFBrowserViewController.Configuration
    
    private let imagesPipeline: ImagePipeline
    
    let videoPlaybackLabel: IFVideoPlaybackLabel = {
        let label = IFVideoPlaybackLabel()
        label.alpha = 0
        label.clipsToBounds = true
        label.textAlignment = .center
        label.font = .systemFont(ofSize: 11)
        label.textColor = .label
        label.layer.cornerRadius = 3
        label.backgroundColor = .systemBackground.withAlphaComponent(0.8)
        return label
    }()
    
    let photosManager = PHCachingImageManager()
    
    var allowsMediaPlay = true
    var videoStatus = CurrentValueSubject<IFVideo.Status, Never>(.autoplay)
    var videoPlayback = CurrentValueSubject<IFVideo.Playback?, Never>(nil)
    var soundStatus = CurrentValueSubject<IFVideo.AudioStatus, Never>(.disabled)
    
    private(set) var previousDisplayingMediaIndex: Int?
    private(set) var displayingMediaIndex: Int {
        didSet {
            previousDisplayingMediaIndex = oldValue
            displayingLinkMetadata = nil
        }
    }
    
    private lazy var displayingLinkMetadata: LPLinkMetadata? = nil
    
    private let imagePipelineDelegate = ImagePipelineDefaultDelegate()
    private let videoGeneratorCache = IFVideoThumbnailGeneratorCache()
    private var bag: Set<AnyCancellable> = []
    
    init(media: [IFMedia], configuration: IFBrowserViewController.Configuration = IFBrowserViewController.Configuration(), initialIndex: Int = 0) {
        self.media = media
        self.configuration = configuration
        self.displayingMediaIndex = min(max(initialIndex, 0), media.count - 1)
        
        self.imagesPipeline = ImagePipeline(delegate: ImagePipelineDefaultDelegate()) { configuration in
            let registry = ImageDecoderRegistry()
            registry.register(ImageDecoders.AVAsset.init)
            registry.register(ImageDecoders.PDFDocument.init)

            configuration.makeImageDecoder = {
                registry.decoder(for: $0)
            }
        }
        
        if #available(iOS 13.0, *) {
            prepareDisplayingMetadata()
        }
        
        soundStatus
            .filter { [weak self] sound in
                sound == .enabled && self?.videoStatus.value.isAutoplay == true
            }
            .sink { [weak self] _ in
                self?.videoStatus.value = self?.videoStatus.value == .autoplay ? .play : .pause
            }
            .store(in: &bag)
    }
    
    func updatedisplayingMedia(index: Int) {
        guard media.indices.contains(index) else { return }
        displayingMediaIndex = index
        videoStatus.value = .autoplay
        videoPlayback.value?.currentTime.value = 0
        
        if #available(iOS 13.0, *) {
            prepareDisplayingMetadata()
        }
    }
    
    func removeDisplayingMedia() {
        let removingIndex = displayingMediaIndex
        let displayingIndex = (previousDisplayingMediaIndex ?? removingIndex) > removingIndex ? removingIndex - 1 : removingIndex
        media.remove(at: removingIndex)
        updatedisplayingMedia(index: min(max(displayingIndex, 0), media.count - 1))
    }
    
    func sharingMedia(at index: Int, completion: @escaping (Result<IFMediaActivityItem, Error>) -> Void) {
//        guard let media = media[safe: index] else { return }
//
//        let prepareSharingImage = { [weak self] (result: Result<UIImage, Error>) in
//            let sharingResult: Result<IFMediaActivityItem, Error> = result
//                .map {
//                    if #available(iOS 13.0, *) {
//                        if self?.displayingLinkMetadata == nil {
//                            self?.prepareDisplayingMetadata()
//                        }
//                        
//                        return IFMediaActivityItem(media: media, metadata: <#T##LPLinkMetadata?#>) IFMediaActivityItem(container: image, image: $0, metadata: self?.displayingLinkMetadata)
//                    } else {
//                        return IFMediaActivityItem(container: image, image: $0)
//                    }
//                }.mapError { $0 }
//
//            completion(sharingResult)
//        }
//        
//        switch media.mediaType {
//        case .image(let image):
//            switch image[.original] {
//            case .url(let url):
//                imagesPipeline.loadImage(with: url, completion: { result in
//                    prepareSharingImage(result.map { $0.image }.mapError { $0 })
//                })
//            case .image(let image):
//                prepareSharingImage(.success(image))
//            case .asset(let asset):
//                let request = PHImageRequestOptions()
//                request.deliveryMode = .highQualityFormat
//                let size = CGSize(width: asset.pixelWidth, height: asset.pixelHeight)
//                
//                photosManager.requestImage(for: asset, targetSize: size, contentMode: .aspectFit, options: request) { image, userInfo in
//                    if let image = image {
//                        prepareSharingImage(.success(image))
//                    } else {
//                        if (userInfo?[PHImageCancelledKey] as? NSNumber)?.boolValue == true {
//                            completion(.failure(IFError.cancelled))
//                        } else if let error = userInfo?[PHImageErrorKey] as? Error {
//                            completion(.failure(error))
//                        } else {
//                            completion(.failure(IFError.failed))
//                        }
//                    }
//                }
//            }
//        case .video(let video):
//        case .pdf:
//        }
    }
}

// MARK: - Image
extension IFMediaManager {
    
    @discardableResult
    func loadImage(
        at index: Int,
        options: IFImage.LoadOptions,
        completion: ((ImageContainer) -> Void)? = nil
    ) -> Nuke.Cancellable? {
        
        guard
            let media = media[safe: index],
            case .image(let image) = media.mediaType
        else { return nil }
        
        let preferredSize = options.preferredSize.map { CGSize(width: $0.width * UIScreen.main.scale, height: $0.height * UIScreen.main.scale) }
        let configurationPlaceholder = configuration.placeholder(for: .images) ?? UIImage()
        
        switch image[options.kind] {
        case .image(let image):
            let state = CancellableState()
            
            if let preferredSize = preferredSize {
                DispatchQueue.global(qos: .userInteractive).async {
                    let image = image.resizedToFill(size: preferredSize)
                    DispatchQueue.main.async {
                        if !state.isCancelled {
                            completion?(ImageContainer(image: image))
                        }
                    }
                }
            } else {
                completion?(ImageContainer(image: image))
            }

            return state
        case .asset(let asset):
            let size = preferredSize ?? CGSize(width: asset.pixelWidth, height: asset.pixelHeight)
            let request = PHImageRequestOptions()

            if preferredSize == nil {
                request.resizeMode = .none
            }
            
            request.isNetworkAccessAllowed = true
            
            if #available(iOS 17, *) {
                request.allowSecondaryDegradedImage = true
            }

            
            let placeholder = image.placeholder ?? configurationPlaceholder
            let requestID: PHImageRequestID
            
            if PHAssetResource.assetResources(for: asset).contains(where: { $0.uniformTypeIdentifier == kUTTypeGIF as String }) {
                requestID = photosManager.requestImageDataAndOrientation(for: asset, options: request) { data, _, _, userInfo in
                    let isCancelled = (userInfo?[PHImageCancelledKey] as? NSNumber)?.boolValue == true
                    
                    guard !isCancelled else { return }
                    let image = data.flatMap(UIImage.init)
                    
                    DispatchQueue.main.async {
                        completion?(ImageContainer(image: image ?? placeholder, type: .gif, data: data))
                    }
                }
            } else {
                requestID = photosManager.requestImage(for: asset, targetSize: size, contentMode: .aspectFit, options: request) { image, userInfo in
                    let isCancelled = (userInfo?[PHImageCancelledKey] as? NSNumber)?.boolValue == true
                    
                    guard !isCancelled else { return }

                    DispatchQueue.main.async {
                        completion?(ImageContainer(image: image ?? placeholder))
                    }
                }
            }
            
            return PHImageTask(manager: photosManager, requestID: requestID)
        case .url(let url):
            let priority: ImageRequest.Priority
            
            if index == displayingMediaIndex {
                priority = options.kind == .original ? .veryHigh : .high
            } else {
                priority = .normal
            }

            let request = ImageRequest(
                url: url,
                processors: preferredSize.map { [ImageProcessors.Resize(size: $0)] } ?? [],
                priority: priority)
            
            return imagesPipeline.loadImage(with: request) { result in
                let placeholder = image.placeholder ?? configurationPlaceholder
          
                let container = (try? result.get())?.container ?? ImageContainer(image: placeholder)
                DispatchQueue.main.async {
                    completion?(container)
                }
            }
        }
    }
}

// MARK: - Video
extension IFMediaManager {
    
    @discardableResult
    func videoThumbnailGenerator(at index: Int, completion: @escaping (IFVideoThumbnailGenerator?) -> Void) -> Nuke.Cancellable {
        let nestedTask = NestedTask()
        
        let videoTask = loadVideo(at: index) { [weak self] asset in
            if let asset {
                self?.videoGeneratorCache.createGenerator(at: index, asset: asset) { generator in
                    if !nestedTask.isCancelled {
                        DispatchQueue.main.async {
                            completion(generator)
                        }
                    }
                }
            } else {
                completion(nil)
            }
        }
        
        if let videoTask {
            nestedTask.addSubtask(videoTask)
        }
        
        return nestedTask
    }
    
    @discardableResult
    func loadVideo(at index: Int, completion: @escaping (AVAsset?) -> Void) -> Nuke.Cancellable? {
        guard
            let media = media[safe: index],
            case .video(let video) = media.mediaType
        else { return nil }
        
        switch video.media {
        case .url(let url):
            if let cachedVideo = imagesPipeline.cache[url], let asset = cachedVideo.userInfo[.videoAssetKey] as? AVAsset {
                completion(asset)
                return nil
            } else {
                let priority: ImageRequest.Priority
                
                if index == displayingMediaIndex {
                    priority = .veryHigh
                } else {
                    priority = .normal
                }
                
                let request = ImageRequest(url: url, priority: priority, userInfo: [.videoUrlKey: url])
                
                return imagesPipeline.loadImage(with: request) { result in
                    completion((try? result.get())?.container.userInfo[.videoAssetKey] as? AVAsset)
                }
            }
        case .video(let avAsset):
            completion(avAsset)
            return nil
        case .asset(let phAsset):
            let options = PHVideoRequestOptions()
            options.isNetworkAccessAllowed = true
            
            let requestID = photosManager.requestAVAsset(forVideo: phAsset, options: options) { avAsset, _, userInfo in
                let isCancelled = (userInfo?[PHImageCancelledKey] as? NSNumber)?.boolValue == true
                
                guard !isCancelled else { return }

                DispatchQueue.main.async {
                    completion(avAsset)
                }
            }
            
            return PHImageTask(manager: photosManager, requestID: requestID)
        }
    }
    
    @discardableResult
    func loadVideoCover(at index: Int, preferredSize: CGSize? = nil, completion: ((UIImage) -> Void)? = nil) -> Nuke.Cancellable? {
        guard
            let media = media[safe: index],
            case .video(let video) = media.mediaType
        else { return nil }
        
        let preferredSize = preferredSize.map { CGSize(width: $0.width * UIScreen.main.scale, height: $0.height * UIScreen.main.scale) }
        let configurationPlaceholder = configuration.placeholder(for: .videos) ?? UIImage()
        
        switch video.cover {
        case .image(let source):
            switch source {
            case .image(let image):
                let state = CancellableState()
                
                if let preferredSize {
                    DispatchQueue.global(qos: .userInteractive).async {
                        let image = image.resizedToFill(size: preferredSize)
                        DispatchQueue.main.async {
                            if !state.isCancelled {
                                completion?(image)
                            }
                        }
                    }
                } else {
                    completion?(image)
                }

                return state
            case .asset(let asset):
                let size = preferredSize ?? CGSize(width: asset.pixelWidth, height: asset.pixelHeight)
                let request = PHImageRequestOptions()

                if preferredSize == nil {
                    request.resizeMode = .none
                }
                
                request.isNetworkAccessAllowed = true
                
                if #available(iOS 17, *) {
                    request.allowSecondaryDegradedImage = true
                }

                let requestID = photosManager.requestImage(for: asset, targetSize: size, contentMode: .aspectFit, options: request) { requestedImage, _ in
                    let image = requestedImage ?? video.placeholder ?? configurationPlaceholder
                    completion?(image)
                }
                
                return PHImageTask(manager: photosManager, requestID: requestID)
            case .url(let url):
                let request = ImageRequest(
                    url: url,
                    processors: preferredSize.map { [ImageProcessors.Resize(size: $0)] } ?? [],
                    priority: index == displayingMediaIndex ? .high : .normal)
                
                return imagesPipeline.loadImage(with: request) { result in
                    let image = (try? result.get())?.image ?? video.placeholder ?? configurationPlaceholder
                    DispatchQueue.main.async {
                        completion?(image)
                    }
                }
            }
        case .seek(let time):
            let nestedTask = NestedTask()
            let videoTask = loadVideo(at: index) { asset in
                let placeholder = video.placeholder ?? configurationPlaceholder
                
                guard let asset else {
                    completion?(placeholder)
                    return
                }
                
                DispatchQueue.global(qos: .userInteractive).async {
                    let generator = AVAssetImageGenerator(asset: asset)
                    generator.appliesPreferredTrackTransform = true
                    generator.generateCGImagesAsynchronously(forTimes: [NSValue(time: time)]) { _, cgImage, _, _, _ in
                        let originalImage = cgImage.map(UIImage.init) ?? placeholder
                        let scaledImage = preferredSize.map { originalImage.resizedToFill(size: $0) } ?? originalImage
                        
                        DispatchQueue.main.async {
                            video.cover = .image(.image(originalImage))
                            
                            if !nestedTask.isCancelled {
                                completion?(scaledImage)
                            }
                        }
                    }
                }
            }
            
            if let videoTask {
                nestedTask.addSubtask(videoTask)
            }
            
            return nestedTask
        }
    }
}

// MARK: - PDF
extension IFMediaManager {
    
    @discardableResult
    func loadPDF(at index: Int, completion: @escaping (PDFDocument?) -> Void) -> Nuke.Cancellable? {
        guard
            let media = media[safe: index],
            case .pdf(let pdf) = media.mediaType
        else { return nil }
        
        switch pdf.media {
        case .url(let url):
            if let cachedDocument = imagesPipeline.cache[url], let document = cachedDocument.userInfo[.pdfAssetKey] as? PDFDocument {
                completion(document)
                return nil
            } else {
                let priority: ImageRequest.Priority
                
                if index == displayingMediaIndex {
                    priority = .veryHigh
                } else {
                    priority = .normal
                }
                
                let request = ImageRequest(url: url, priority: priority, userInfo: [.pdfAssetKey: url])
                return imagesPipeline.loadImage(with: request) { result in
                    completion((try? result.get())?.container.userInfo[.pdfAssetKey] as? PDFDocument)
                }
            }
        case .data(let data):
            let state = CancellableState()
            
            DispatchQueue.global(qos: .userInteractive).async {
                let document = PDFDocument(data: data) ?? PDFDocument()
                
                DispatchQueue.main.async {
                    pdf.media = .document(document)
                    if !state.isCancelled {
                        completion(document)
                    }
                }
            }
            
            return state
        case .document(let document):
            completion(document)
            return nil
        }
    }
    
    @discardableResult
    func loadPDFThumbnail(at index: Int, preferredSize: CGSize? = nil, completion: ((UIImage) -> Void)? = nil) -> Nuke.Cancellable? {
        guard
            let media = media[safe: index],
            case .pdf(let pdf) = media.mediaType
        else { return nil }
        
        let configurationPlaceholder = configuration.placeholder(for: .pdf) ?? UIImage()
        
        switch pdf.cover {
        case .image(let image):
            switch image {
            case .url(let url):
                let request = ImageRequest(
                    url: url,
                    processors: preferredSize.map { [ImageProcessors.Resize(size: $0)] } ?? [],
                    priority: index == displayingMediaIndex ? .high : .normal)
                
                return imagesPipeline.loadImage(with: request) { result in
                    let image = (try? result.get())?.image ?? pdf.placeholder ?? configurationPlaceholder
                    DispatchQueue.main.async {
                        completion?(image)
                    }
                }
            case .image(let image):
                let state = CancellableState()
                
                if let preferredSize {
                    DispatchQueue.global(qos: .userInteractive).async {
                        let image = image.resizedToFill(size: preferredSize)
                        DispatchQueue.main.async {
                            if !state.isCancelled {
                                completion?(image)
                            }
                        }
                    }
                } else {
                    completion?(image)
                }
                
                return state
            case .asset(let asset):
                let size = preferredSize ?? CGSize(width: asset.pixelWidth, height: asset.pixelHeight)
                let request = PHImageRequestOptions()

                if preferredSize == nil {
                    request.resizeMode = .none
                }
                
                request.isNetworkAccessAllowed = true
                
                if #available(iOS 17, *) {
                    request.allowSecondaryDegradedImage = true
                }

                let requestID = photosManager.requestImage(for: asset, targetSize: size, contentMode: .aspectFit, options: request) { requestedImage, _ in
                    let image = requestedImage ?? pdf.placeholder ?? configurationPlaceholder
                    completion?(image)
                }
                
                return PHImageTask(manager: photosManager, requestID: requestID)
                
            }
        case .page(let pageIndex):
            let nestedTask = NestedTask()
            
            let pdfTask = loadPDF(at: index) { document in
                let placeholder = pdf.placeholder ?? configurationPlaceholder
                
                guard let document else {
                    completion?(placeholder)
                    return
                }

                DispatchQueue.global(qos: .userInteractive).async {
                    let image = document.page(at: pageIndex)?.asImage ?? placeholder
                    DispatchQueue.main.async {
                        pdf.cover = .image(.image(image))
                        
                        if !nestedTask.isCancelled {
                            completion?(image)
                        }
                    }
                }
            }
            
            if let pdfTask {
                nestedTask.addSubtask(pdfTask)
            }
            
            return nestedTask
        }
    }
}

@available(iOS 13.0, *)
extension IFMediaManager {
    private func prepareDisplayingMetadata() {
        guard let media = media[safe: displayingMediaIndex] else { return }
        let metadata = LPLinkMetadata()
        metadata.title = media.title
        
        switch media.mediaType {
        case .image(let image):
            switch image[.original] {
            case .url(let url):
                metadata.originalURL = url

                imagesPipeline.loadImage(with: ImageRequest(url: url, priority: .veryHigh), completion: { [weak metadata] result in
                    if case .success(let response) = result {
                        let provider = NSItemProvider(object: response.image)
                        metadata?.imageProvider = provider
                        metadata?.iconProvider = provider
                    }
                })
            case .image(let image):
                let provider = NSItemProvider(object: image)
                metadata.imageProvider = provider
                metadata.iconProvider = provider
            case .asset(let asset):
                let request = PHImageRequestOptions()
                request.deliveryMode = .highQualityFormat
                let size = CGSize(width: asset.pixelWidth, height: asset.pixelHeight)
                
                photosManager.requestImage(for: asset, targetSize: size, contentMode: .aspectFit, options: request) { [weak metadata] image, _ in
                    if let image = image {
                        let provider = NSItemProvider(object: image)
                        metadata?.imageProvider = provider
                        metadata?.iconProvider = provider
                    }
                }
            }
        case .video(let video):
            #warning("Improve video sharing")
            switch video.media {
            case .url(let url):
                metadata.originalURL = url
                metadata.remoteVideoURL = url
            case .video(let aVAsset):
                return
            case .asset(let pHAsset):
                return
            }
        case .pdf:
            break
        }

        
        self.displayingLinkMetadata = metadata
    }
}

private final class ImagePipelineDefaultDelegate: ImagePipelineDelegate {
    private let dataLoader = LazyDataLoader()
    
    func dataLoader(for request: ImageRequest, pipeline: ImagePipeline) -> DataLoading {
        dataLoader.request = request
        return dataLoader
    }
}
