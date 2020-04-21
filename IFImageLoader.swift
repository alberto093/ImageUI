//
//  IFImageLoader.swift
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
