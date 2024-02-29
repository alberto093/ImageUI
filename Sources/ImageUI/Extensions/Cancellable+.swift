//
//  Cancellable+.swift
//
//
//  Created by Alberto Saltarelli on 28/02/24.
//

import Foundation
import Photos
import Nuke

final class PHImageTask: Cancellable, @unchecked Sendable {
    
    private let requestID: PHImageRequestID
    private weak var manager: PHCachingImageManager?
    
    init(manager: PHCachingImageManager, requestID: PHImageRequestID) {
        self.manager = manager
        self.requestID = requestID
    }
    
    func cancel() {
        manager?.cancelImageRequest(requestID)
    }
}

final class NestedTask: Cancellable, @unchecked Sendable {
    
    private(set) var isCancelled = false
    private var subTasks: [Cancellable] = []
    
    func addSubtask(_ task: Cancellable) {
        subTasks.append(task)
        
        if isCancelled {
            task.cancel()
        }
    }
    
    func cancel() {
        isCancelled = true
        subTasks.forEach { $0.cancel() }
    }
}

final class CancellableState: Cancellable, @unchecked Sendable {
    private(set) var isCancelled = false
    
    func cancel() {
        isCancelled = true
    }
}

extension Nuke.ImageTask: Cancellable { }
