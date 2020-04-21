//
//  IFImageLoader.swift
//  ImageUI
//
//  Created by Alberto Saltarelli on 21/04/2020.
//

import Nuke

class IFImageLoader: DataLoading {
    let networkLoader = DataLoader()
    private let fileFetchingQueue = DispatchQueue(label: "org.cocoapods.ImageUI", attributes: .concurrent, target: .global(qos: .userInitiated))
    
    func loadData(with request: URLRequest, didReceiveData: @escaping (Data, URLResponse) -> Void, completion: @escaping (Error?) -> Void) -> Cancellable {
        if let url = request.url, url.isFileURL == true {
            let fetchingTask = DispatchWorkItem {
                let localPath = url.relativePath
                if !FileManager.default.fileExists(atPath: localPath) {
                    completion(URLError(.fileDoesNotExist))
                } else if let data = FileManager.default.contents(atPath: localPath) {
                    didReceiveData(data, URLResponse())
                    completion(nil)
                } else {
                    completion(URLError(.resourceUnavailable))
                }
            }
            fileFetchingQueue.async(execute: fetchingTask)
            return fetchingTask
        } else {
            return networkLoader.loadData(with: request, didReceiveData: didReceiveData, completion: completion)
        }
    }
}
