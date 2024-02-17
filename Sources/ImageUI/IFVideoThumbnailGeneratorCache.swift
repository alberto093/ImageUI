//
//  IFVideoThumbnailGeneratorQueue.swift
//
//
//  Created by Alberto Saltarelli on 23/01/24.
//

import Foundation
import AVFoundation

class IFVideoThumbnailGeneratorCache {
    typealias Completion = (IFVideoThumbnailGenerator) -> Void
    private let queue = DispatchQueue(label: "IFVideoThumbnailGeneratorQueue", qos: .userInteractive)
    
    private var creatingIndices: Set<Int> = []
    private var generatorCompletion: [Int: [Completion]] = [:]
    private var generators: [Int: IFVideoThumbnailGenerator] = [:]
    
    func createGenerator(at index: Int, asset: AVAsset, completion: Completion? = nil) {
        queue.sync {
            if let generator = self.generators[index] {
                completion?(generator)
            }
        }

        queue.async { [weak self] in
            guard let self else { return }
            
            if let completion {
                self.generatorCompletion[index, default: []].append(completion)
            }
            
            if !self.creatingIndices.contains(index) {
                self.creatingIndices.insert(index)
                let generator = IFVideoThumbnailGenerator(asset: asset)
                
                queue.async(flags: .barrier) { [weak self] in
                    self?.generators[index] = generator
                }

                self.generatorCompletion[index]?.forEach {
                    $0(generator)
                }
                self.creatingIndices.remove(index)
                self.generatorCompletion[index] = nil
            }
        }
    }
}
