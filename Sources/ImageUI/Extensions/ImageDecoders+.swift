//
//  ImageDecoders+.swift
//
//
//  Created by Alberto Saltarelli on 12/02/24.
//

import AVFoundation
import Nuke
import UIKit
import PDFKit

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
    
    final class PDFDocument: ImageDecoding {
        
        init?(context: ImageDecodingContext) {
            if context.request.userInfo[.pdfAssetKey] == nil {
                return nil
            }
        }
        
        func decode(_ data: Data) throws -> ImageContainer {
            ImageContainer(image: UIImage(), userInfo: [.pdfAssetKey: PDFKit.PDFDocument(data: data) as Any])
        }
    }
}

extension ImageRequest.UserInfoKey {
    static let videoUrlKey: ImageRequest.UserInfoKey = "ImageUI/videoUrlKey"
    static let pdfAssetKey: ImageRequest.UserInfoKey = "ImageUI/pdfAssetKey"
}

extension ImageContainer.UserInfoKey {
    /// A key for a pdf (`PDFDocument`)
    public static let pdfAssetKey: ImageContainer.UserInfoKey = "ImageUI/pdfAssetKey"
}
