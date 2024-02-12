//
//  ImageDecoders+.swift
//
//
//  Created by Alberto Saltarelli on 12/02/24.
//

import AVFoundation
import Nuke
import UIKit

extension ImageDecoders {
    final class AVAsset: ImageDecoding {
        private let url: URL
        init?(context: ImageDecodingContext) {
            guard let videoURL = context.request.userInfo[.videoUrlKey] as? URL else { return nil }
            self.url = videoURL
        }
        
        func decode(_ data: Data) throws -> ImageContainer {
            ImageContainer(image: UIImage(), userInfo: [.videoAssetKey: AVFoundation.AVAsset(url: url)])
        }
    }
}

extension ImageRequest.UserInfoKey {
    static let videoUrlKey: ImageRequest.UserInfoKey = "ImageUI/videoUrlKey"
}
