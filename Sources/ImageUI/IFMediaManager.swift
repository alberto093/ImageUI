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

#if canImport(LinkPresentation)
import LinkPresentation
#endif

class IFMediaManager {
    private(set) var media: [IFMedia]
    private let placeholder: IFBrowserViewController.Placeholder
    
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
    
    var prefersAspectFillZoom = false
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
    
    private var assetHighQualityRequestID: PHImageRequestID? {
        didSet { oldValue.map(photosManager.cancelImageRequest) }
    }
    
    private let videoGeneratorCache = IFVideoThumbnailGeneratorCache()
    private var bag: Set<AnyCancellable> = []
    
    init(media: [IFMedia], placeholder: IFBrowserViewController.Placeholder = IFBrowserViewController.Placeholder(), initialIndex: Int = 0) {
        self.media = media
        self.placeholder = placeholder
        self.displayingMediaIndex = min(max(initialIndex, 0), media.count - 1)
        
        self.imagesPipeline = ImagePipeline { configuration in
            let registry = ImageDecoderRegistry()
            registry.register(ImageDecoders.Video.init)
            
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
    @MainActor
    func loadImage(
        at index: Int,
        options: IFImage.LoadOptions,
        sender: ImageDisplayingView,
        completion: ((IFImage.Result) -> Void)? = nil) {
        
        guard
            let media = media[safe: index],
            case .image(let image) = media.mediaType
        else { return }
        
        switch image[options.kind] {
        case .image(let image):
            sender.nuke_display(image: image, data: nil)

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

            let requestID = self.photosManager.requestImage(for: asset, targetSize: size, contentMode: .aspectFit, options: request) { [weak sender] image, userInfo in
                if let image = image {
                    sender?.nuke_display(image: image, data: nil)

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
            
            if index == displayingMediaIndex {
                priority = options.kind == .original ? .veryHigh : .high
            } else {
                priority = .normal
            }

            let request = ImageRequest(
                url: url,
                processors: options.preferredSize.map { [ImageProcessors.Resize(size: $0)] } ?? [],
                priority: priority)

            var loadingOptions = ImageLoadingOptions(
                placeholder: image.placeholder,
                transition: .fadeIn(duration: 0.1, options: .curveEaseOut))
            loadingOptions.pipeline = imagesPipeline
                
            NukeExtensions.loadImage(with: request, options: loadingOptions, into: sender, completion: { result in
                completion?(result.map { (options.kind, $0.image) }.mapError { $0 })
            })
        }
    }
}

// MARK: - Video
extension IFMediaManager {
    func videoThumbnailGenerator(at index: Int, completion: @escaping (IFVideoThumbnailGenerator?) -> Void) {
        loadVideo(at: index) { [weak self] asset in
            if let asset {
                self?.videoGeneratorCache.createGenerator(at: index, asset: asset) { generator in
                    DispatchQueue.main.async {
                        completion(generator)
                    }
                }
            } else {
                completion(nil)
            }
        }
    }
    
    func loadVideo(at index: Int, completion: @escaping ((AVAsset?) -> Void)) {
        guard
            let media = media[safe: index],
            case .video(let video) = media.mediaType
        else { return }
        
        let completion: (AVAsset?) -> Void = { [weak self] asset in
            if self?.displayingMediaIndex == index, let asset {
                self?.videoGeneratorCache.createGenerator(at: index, asset: asset)
            }
            
            completion(asset)
        }
        
        switch video.media {
        case .url(let url):
            if let cachedVideo = imagesPipeline.cache[url], let asset = cachedVideo.userInfo[.videoAssetKey] as? AVAsset {
                completion(asset)
            } else {
                DispatchQueue.global(qos: index == displayingMediaIndex ? .userInitiated : .userInteractive).async {
                    let asset = AVAsset(url: url)
                    DispatchQueue.main.async { [weak self] in
                        self?.imagesPipeline.cache[url] = ImageContainer(image: UIImage(), userInfo: [.videoAssetKey: asset])
                        completion(asset)
                    }
                }
            }
        case .video(let avAsset):
            completion(avAsset)
        case .asset(let phAsset):
            photosManager.requestAVAsset(forVideo: phAsset, options: nil) { avAsset, _, _ in
                DispatchQueue.main.async {
                    completion(avAsset)
                }
            }
        }
    }
    
    #warning("Add preferredSize and scaling image not in main thread")
    func loadVideoCover(at index: Int, completion: ((UIImage) -> Void)? = nil) {
        guard
            let media = media[safe: index],
            case .video(let video) = media.mediaType
        else { return }
        
        switch video.cover {
        case .image(let source):
            switch source {
            case .image(let image):
                completion?(image)
            case .asset(let asset):
                let size = CGSize(width: asset.pixelWidth, height: asset.pixelHeight)
                let request = PHImageRequestOptions()
                request.resizeMode = .none
                request.isNetworkAccessAllowed = true
                
                photosManager.requestImage(for: asset, targetSize: size, contentMode: .aspectFit, options: request) { [weak self] image, userInfo in
                    guard let self else { return }
                    completion?(image ?? video.placeholder ?? self.placeholder.video)
                }
            case .url(let url):
                imagesPipeline.loadImage(with: url) { [weak self] result in
                    guard let self else { return }
                    let image = try? result.get().image
                    completion?(image ?? video.placeholder ?? self.placeholder.video)
                }
            }
        case .seek(let time):
            loadVideo(at: index) { asset in
                guard let asset else { return }
                
                DispatchQueue.global(qos: .userInteractive).async {
                    let generator = AVAssetImageGenerator(asset: asset)
                    generator.appliesPreferredTrackTransform = true
                    generator.generateCGImagesAsynchronously(forTimes: [NSValue(time: time)]) { [weak self] _, cgImage, _, _, _ in
                        guard let self else { return }
                        
                        let image = cgImage.map(UIImage.init) ?? video.placeholder ?? self.placeholder.video
                        DispatchQueue.main.async {
                            video.cover = .image(.image(image))
                            completion?(image)
                        }
                    }
                }
            }
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
