//
//  IFImage.swift
//  ImageUI
//
//  Created by Alberto Saltarelli on 18/04/2020.
//

import Foundation

#warning("Add file and Data support --> Use DataLoader on ImageRequestOptions in Nuke")
public struct IFImage {
    public let title: String?
    public let url: URL
    
    public init(title: String? = nil, url: URL) {
        self.title = title
        self.url = url
    }
}
