//
//  IFVideoThumbnailGenerator.swift
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

import AVFoundation
import UIKit
import Combine

class IFVideoThumbnailGenerator {
    private enum Constants {
        static let minimumNumberOfThumbnails: Int = 2
    }
    
    let asset: AVAsset
    
    let numberOfThumbnails: Int
    let assetDuration: CMTime
    let thumbnailDuration: CMTime
    
    private var autoplayLastThumbnail: UIImage?
    private var thumbnails: [Int: UIImage] = [:]
    
    private let imageGenerator: AVAssetImageGenerator
    private var thumbnailTimes: [NSValue]?
    private var bag: Set<AnyCancellable> = []
    
    init(asset: AVAsset) {
        self.asset = asset
        self.imageGenerator = AVAssetImageGenerator(asset: asset)
        self.imageGenerator.appliesPreferredTrackTransform = true
        
        let assetDuration = asset.duration
        
        if assetDuration.value == 0 {
            self.numberOfThumbnails = Constants.minimumNumberOfThumbnails
        } else {
            let numberOfThumbnails = (3 * log(assetDuration.seconds)).rounded(.toNearestOrAwayFromZero)
            self.numberOfThumbnails = max(Constants.minimumNumberOfThumbnails, Int(numberOfThumbnails))
        }

        self.assetDuration = assetDuration
        self.thumbnailDuration = CMTimeMultiplyByRatio(assetDuration, multiplier: 1, divisor: Int32(numberOfThumbnails))
    }
    
    deinit {
        imageGenerator.cancelAllCGImageGeneration()
    }
    
    func generateAutoplayLastThumbnail(completion: @escaping (UIImage?) -> Void) {
        if let autoplayLastThumbnail {
            completion(autoplayLastThumbnail)
        } else {
            imageGenerator.cancelAllCGImageGeneration()
            
            var time = assetDuration
            time.value /= 2
            
            imageGenerator.generateCGImagesAsynchronously(forTimes: [NSValue(time: time)]) { [weak self] _, cgImage, _, result, _ in
                switch result {
                case .succeeded:
                    let image = cgImage.map(UIImage.init)
                    
                    DispatchQueue.main.async {
                        self?.autoplayLastThumbnail = image
                        completion(image)
                    }
                case .cancelled:
                    self?.generateAutoplayLastThumbnail(completion: completion)
                default:
                    break
                }
            }
        }
    }
    
    func generateImages(currentTime: CMTime, completion: @escaping ([Int: UIImage]) -> Void) {
        imageGenerator.cancelAllCGImageGeneration()
        
        if thumbnailTimes == nil {
            thumbnailTimes = (0..<numberOfThumbnails).reduce(into: [NSValue(time: .zero)]) { result, _ in
                result.append(NSValue(time: CMTimeAdd(result.last!.timeValue, thumbnailDuration)))
            }

        }
        
        thumbnailTimes = thumbnailTimes!.enumerated().compactMap {
            thumbnails[$0.offset] == nil ? $0.element : nil
        }
        
        let currentTime = currentTime.convertScale(thumbnailDuration.timescale, method: .quickTime)
        let thumbnailIndex = Int(currentTime.value / thumbnailDuration.value)

        var sortedTimes: [NSValue]
        
        if thumbnailTimes!.indices.contains(thumbnailIndex) {
            sortedTimes = [thumbnailTimes![thumbnailIndex]]
            
            var lowerIndex = thumbnailIndex - 1
            var upperIndex = thumbnailIndex + 1
            
            while lowerIndex >= 0 || upperIndex < thumbnailTimes!.count {
                if upperIndex < thumbnailTimes!.count {
                    sortedTimes.append(thumbnailTimes![upperIndex])
                    upperIndex += 1
                }
                
                if lowerIndex >= 0 {
                    sortedTimes.append(thumbnailTimes![lowerIndex])
                    lowerIndex -= 1
                }
            }
        } else {
            sortedTimes = thumbnailTimes!
        }
        
        imageGenerator.generateCGImagesAsynchronously(forTimes: sortedTimes) { [weak self] thumbnailTime, cgImage, _, result, _ in
            guard
                result == .succeeded,
                let thumbnailIndex = self?.thumbnailTimes?.firstIndex(of: NSValue(time: thumbnailTime)),
                let cgImage
            else { return }
            
            let image = UIImage(cgImage: cgImage)
            
            DispatchQueue.main.async {
                self?.thumbnails[thumbnailIndex] = image
                completion(self?.thumbnails ?? [:])
            }
        }
    }
    
    func cancelAllImageGeneration() {
        imageGenerator.cancelAllCGImageGeneration()
    }
}
