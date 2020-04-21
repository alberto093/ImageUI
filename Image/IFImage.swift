//
//  IFImage.swift
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

import Foundation

public struct IFImage {
    public enum Source {
        case local(path: String)
        case remote(url: URL)
    }

    public let title: String?
    public let source: Source
    
    internal var url: URL {
        switch source {
        case .local(let path):
            return URL(fileURLWithPath: path)
        case .remote(let url):
            return url
        }
    }
    
    public init(title: String? = nil, source: Source) {
        self.title = title
        self.source = source
    }
    
    public init(title: String? = nil, url: URL) {
        self.title = title
        self.source = .remote(url: url)
    }
    
    public init(title: String? = nil, path: String) {
        self.title = title
        self.source = .local(path: path)
    }
}
