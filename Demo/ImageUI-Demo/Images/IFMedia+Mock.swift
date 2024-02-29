//
//  IFMedia+Mock.swift
//  ImageUI-Demo
//
//  Created by Alberto Saltarelli on 12/05/2020.
//  Copyright © 2020 Alberto Saltarelli. All rights reserved.
//

import UIKit
import ImageUI
import Photos

extension IFMedia {
    static let mock: [IFMedia] = {
        let localImages = IFMedia.localImages.enumerated().map { IFMedia(title: "Local file \($0.offset + 1)", mediaType: .image($0.element)) }
        let remoteImages = IFMedia.remoteImages.enumerated().map { IFMedia(title: "Remote image \($0.offset + 1)", mediaType: .image($0.element)) }
        let memoryImages = IFMedia.memoryImages.enumerated().map { IFMedia(title: "In-memory image \($0.offset + 1)", mediaType: .image($0.element)) }
        let imageAssets = IFMedia.imageAssets.enumerated().map { IFMedia(title: "Photo asset \($0.offset + 1)", mediaType: .image($0.element)) }
        
        let remoteVideos = IFMedia.remoteVideos.enumerated().map { IFMedia(title: "Remote video \($0.offset + 1)", mediaType: .video($0.element)) }
        let videoAssets = IFMedia.videoAssets.enumerated().map { IFMedia(title: "Video asset \($0.offset + 1)", mediaType: .video($0.element)) }
        
        let remotePDF = IFMedia.remotePDF.enumerated().map { IFMedia(title: "Remote PDF \($0.offset + 1)", mediaType: .pdf($0.element)) }
        
        let remoteGIF = IFMedia.remoteGIF.enumerated().map { IFMedia(title: "Remote GIF \($0.offset + 1)", mediaType: .image($0.element)) }
        
        return (localImages + remoteImages + memoryImages + imageAssets + remoteVideos + videoAssets + remotePDF + remoteGIF).shuffled()
    }()
    
    // MARK: - Images

    private static let localImages = [
        Bundle.main.path(forResource: "Image1", ofType: "jpeg")!,
        Bundle.main.path(forResource: "Image2", ofType: "jpeg")!,
        Bundle.main.path(forResource: "Image3", ofType: "jpeg")!,
        Bundle.main.path(forResource: "Image4", ofType: "jpeg")!,
        Bundle.main.path(forResource: "Image5", ofType: "jpeg")!
    ].map { IFImage(original: .url(URL(fileURLWithPath: $0))) }

    private static let remoteImages: [IFImage] = [
        "https://i.imgur.com/GJoXDDu.jpg",
        "https://i.imgur.com/NCaJTv1.jpeg",
        "https://i.imgur.com/2zyjIRm.jpg",
        "https://i.imgur.com/HhkyHKQ.jpeg",
        "https://i.imgur.com/hHHXUoG.jpeg",
        "https://i.imgur.com/dgsC5L9.jpg",
        "https://i.imgur.com/CIEPYb6.jpg",
        "https://i.imgur.com/oBoLh3W.jpeg",
        "https://i.imgur.com/yRkK3il.jpeg",
//        "https://i.imgur.com/EW1UMtj.jpeg",
//        "https://i.imgur.com/RG7gRc7.jpg",
//        "https://i.imgur.com/yYpFuFt.jpeg",
//        "https://i.imgur.com/P2m2ZYf.jpeg",
//        "https://i.imgur.com/dapWvP3.jpeg",
//        "https://i.imgur.com/myQHEsY.jpeg",
//        "https://i.imgur.com/FE4nY3N.jpg",
//        "https://i.imgur.com/04JTu29.jpeg",
//        "https://i.imgur.com/1dDczmF.jpg",
//        "https://i.imgur.com/iB9kaqB.jpg",
//        "https://i.imgur.com/klfsNhq.jpg",
//        "https://i.imgur.com/LHDhBwR.jpg",
//        "https://i.imgur.com/XawVasr.jpeg",
//        "https://i.imgur.com/3xDRjrW.jpeg",
//        "https://i.imgur.com/GJoXDDu.jpg",
//        "https://i.imgur.com/NCaJTv1.jpeg",
//        "https://i.imgur.com/2zyjIRm.jpg",
//        "https://i.imgur.com/HhkyHKQ.jpeg",
//        "https://i.imgur.com/hHHXUoG.jpeg",
//        "https://i.imgur.com/dgsC5L9.jpg",
//        "https://i.imgur.com/CIEPYb6.jpg",
//        "https://i.imgur.com/oBoLh3W.jpeg",
//        "https://i.imgur.com/yRkK3il.jpeg",
//        "https://i.imgur.com/EW1UMtj.jpeg",
//        "https://i.imgur.com/RG7gRc7.jpg",
//        "https://i.imgur.com/yYpFuFt.jpeg",
//        "https://i.imgur.com/P2m2ZYf.jpeg",
//        "https://i.imgur.com/dapWvP3.jpeg",
//        "https://i.imgur.com/myQHEsY.jpeg",
//        "https://i.imgur.com/FE4nY3N.jpg",
//        "https://i.imgur.com/04JTu29.jpeg",
//        "https://i.imgur.com/1dDczmF.jpg",
//        "https://i.imgur.com/iB9kaqB.jpg",
//        "https://i.imgur.com/klfsNhq.jpg",
//        "https://i.imgur.com/LHDhBwR.jpg",
//        "https://i.imgur.com/XawVasr.jpeg",
//        "https://i.imgur.com/3xDRjrW.jpeg",
//        "https://i.imgur.com/GJoXDDu.jpg",
//        "https://i.imgur.com/NCaJTv1.jpeg",
//        "https://i.imgur.com/2zyjIRm.jpg",
//        "https://i.imgur.com/HhkyHKQ.jpeg",
//        "https://i.imgur.com/hHHXUoG.jpeg",
//        "https://i.imgur.com/dgsC5L9.jpg",
//        "https://i.imgur.com/CIEPYb6.jpg",
//        "https://i.imgur.com/oBoLh3W.jpeg",
//        "https://i.imgur.com/yRkK3il.jpeg",
//        "https://i.imgur.com/EW1UMtj.jpeg",
//        "https://i.imgur.com/RG7gRc7.jpg",
//        "https://i.imgur.com/yYpFuFt.jpeg",
//        "https://i.imgur.com/P2m2ZYf.jpeg",
//        "https://i.imgur.com/dapWvP3.jpeg",
//        "https://i.imgur.com/myQHEsY.jpeg",
//        "https://i.imgur.com/FE4nY3N.jpg",
//        "https://i.imgur.com/04JTu29.jpeg",
//        "https://i.imgur.com/1dDczmF.jpg",
//        "https://i.imgur.com/iB9kaqB.jpg",
//        "https://i.imgur.com/klfsNhq.jpg",
//        "https://i.imgur.com/LHDhBwR.jpg",
//        "https://i.imgur.com/XawVasr.jpeg",
//        "https://i.imgur.com/3xDRjrW.jpeg",
//        "https://i.imgur.com/GJoXDDu.jpg",
//        "https://i.imgur.com/NCaJTv1.jpeg",
//        "https://i.imgur.com/2zyjIRm.jpg",
//        "https://i.imgur.com/HhkyHKQ.jpeg",
//        "https://i.imgur.com/hHHXUoG.jpeg",
//        "https://i.imgur.com/dgsC5L9.jpg",
//        "https://i.imgur.com/CIEPYb6.jpg",
//        "https://i.imgur.com/oBoLh3W.jpeg",
//        "https://i.imgur.com/yRkK3il.jpeg",
//        "https://i.imgur.com/EW1UMtj.jpeg",
//        "https://i.imgur.com/RG7gRc7.jpg",
//        "https://i.imgur.com/yYpFuFt.jpeg",
//        "https://i.imgur.com/P2m2ZYf.jpeg",
//        "https://i.imgur.com/dapWvP3.jpeg",
//        "https://i.imgur.com/myQHEsY.jpeg",
//        "https://i.imgur.com/FE4nY3N.jpg",
//        "https://i.imgur.com/04JTu29.jpeg",
//        "https://i.imgur.com/1dDczmF.jpg",
//        "https://i.imgur.com/iB9kaqB.jpg",
//        "https://i.imgur.com/klfsNhq.jpg",
//        "https://i.imgur.com/LHDhBwR.jpg",
//        "https://i.imgur.com/XawVasr.jpeg",
//        "https://i.imgur.com/3xDRjrW.jpeg"
        ].map {
            IFImage(
                original: .url(URL(string: $0)!),
                placeholder: UIImage(color: UIColor(white: 0.9, alpha: 0.5))
            )
    }

    private static let memoryImages = [UIImage(named: "photo1")!, UIImage(named: "photo2")!]
        .map { IFImage(original: .image($0)) }
    
    private static let imageAssets: [IFImage] = {
        let result = PHAsset.fetchAssets(with: .image, options: nil)
        return (0..<result.count).map { IFImage(original: .asset(result.object(at: $0))) }
    }()
    
    // MARK: - Videos
    
    private static let remoteVideos: [IFVideo] = [
        "https://kean.github.io/videos/cat_video.mp4",
        "https://storage.googleapis.com/gtv-videos-bucket/sample/ForBiggerEscapes.mp4",
        "https://storage.googleapis.com/gtv-videos-bucket/sample/ForBiggerBlazes.mp4",
        "https://storage.googleapis.com/gtv-videos-bucket/sample/ElephantsDream.mp4",
        "https://storage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4",
        "https://storage.googleapis.com/gtv-videos-bucket/sample/ForBiggerFun.mp4",
        "https://storage.googleapis.com/gtv-videos-bucket/sample/ForBiggerJoyrides.mp4",
        "https://storage.googleapis.com/gtv-videos-bucket/sample/ForBiggerMeltdowns.mp4",
        "https://storage.googleapis.com/gtv-videos-bucket/sample/Sintel.mp4",
        "https://storage.googleapis.com/gtv-videos-bucket/sample/SubaruOutbackOnStreetAndDirt.mp4",
        "https://storage.googleapis.com/gtv-videos-bucket/sample/TearsOfSteel.mp4"
    ].map {
        IFVideo(media: .url(URL(string: $0)!))
    }
    
    private static let videoAssets: [IFVideo] = {
        let result = PHAsset.fetchAssets(with: .video, options: nil)
        return (0..<result.count).map { IFVideo(media: .asset(result.object(at: $0))) }
    }()
    
    // MARK: - PDF
    
    private static let remotePDF: [IFPDF] = [
        "https://css4.pub/2015/icelandic/dictionary.pdf",
        "https://www.princexml.com/howcome/2016/samples/invoice/index.pdf",
        "https://css4.pub/2015/textbook/somatosensory.pdf",
        "https://css4.pub/2015/usenix/example.pdf",
        "https://www.princexml.com/howcome/2016/samples/magic8/index.pdf"
    ].map {
        IFPDF(media: .url(URL(string: $0)!))
    }
    
    // MARK: - GIF
    
    private static let remoteGIF: [IFImage] = [
        "https://www.easygifanimator.net/images/samples/eglite.gif",
        "https://www.easygifanimator.net/images/samples/sparkles.gif",
        "https://www.easygifanimator.net/images/samples/imageeffects.gif"
    ].map {
        IFImage(original: .url(URL(string: $0)!))
    }
}
