//
//  LazyDataLoader.swift
//
//
//  Created by Alberto Saltarelli on 12/02/24.
//

import Foundation
import Nuke

class LazyDataLoader: DataLoading, @unchecked Sendable {
    private let nukeDataLoader = DataLoader()
    var request: ImageRequest?
    
    func loadData(with request: URLRequest, didReceiveData: @escaping (Data, URLResponse) -> Void, completion: @escaping (Error?) -> Void) -> any Cancellable {
        if self.request?.userInfo[.videoUrlKey] != nil {
            didReceiveData(Data(repeating: 1, count: 1), URLResponse())
            completion(nil)
            return _Cancellable()
        } else {
            return nukeDataLoader.loadData(with: request, didReceiveData: didReceiveData, completion: completion)
        }
    }
}

private final class _Cancellable: Cancellable {
    func cancel() {
        
    }
}
