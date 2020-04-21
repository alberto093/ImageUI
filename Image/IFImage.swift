//
//  IFImage.swift
//  ImageUI
//
//  Created by Alberto Saltarelli on 18/04/2020.
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
