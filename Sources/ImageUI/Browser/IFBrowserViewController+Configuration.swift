//
//  IFBrowserViewController+Configuration.swift
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

import UIKit

extension IFBrowserViewController {
    public class Configuration {
        /// A Boolean value indicating whether the navigation bar is always visible.
        ///
        /// When this property is set to `true` (the default), the browser shows the navigation bar even if the navigation controller property `isNavigationBarHidden` is set to `true`.
        ///
        /// When the property is set to `false`, the browser shows the navigation bar when it is available.
        public var alwaysShowNavigationBar: Bool
        
        /// A Boolean value indicating whether the navigation controller’s built-in toolbar is always visible.
        ///
        /// When this property is set to `true`, the browser shows the toolbar even if there is no actions
        ///
        /// When the property is set to `false` (the default), the browser shows the toolbar when it is available.
        public var alwaysShowToolbar: Bool
        
        private var actions: [MediaType: [Action]] = [:]
        private var placeholders: [MediaType: UIImage] = [:]
        
        public var pdfProgressViewClass: IFPDFProgressView.Type
        
        var isNavigationBarHidden: Bool
        var isToolbarHidden: Bool
        
        public init(
            alwaysShowNavigationBar: Bool = true,
            alwaysShowToolbar: Bool = false,
            pdfProgressViewClass: IFPDFProgressView.Type = UIProgressView.self,
            isNavigationBarHidden: Bool = false,
            isToolbarHidden: Bool = true) {
                self.alwaysShowNavigationBar = alwaysShowNavigationBar
                self.alwaysShowToolbar = alwaysShowToolbar
                self.pdfProgressViewClass = pdfProgressViewClass
                self.isNavigationBarHidden = isNavigationBarHidden
                self.isToolbarHidden = isToolbarHidden
            }
        
        public func setActions(_ actions: [Action], for mediaType: MediaType) {
            self.actions[mediaType] = actions
        }

        public func actions(for mediaType: MediaType) -> [Action] {
            actions[mediaType] ?? actions[.all] ?? []
        }
        
        public func setPlaceholder(_ placeholder: UIImage, for mediaType: MediaType) {
            self.placeholders[mediaType] = placeholder
        }

        public func placeholder(for mediaType: MediaType) -> UIImage? {
            placeholders[mediaType] ?? placeholder(for: .all)
        }
    }
    
    public enum Action: Hashable {
        case share
        case delete
        case custom(identifier: String, title: String? = nil, image: UIImage? = nil)
        
        public func hash(into hasher: inout Hasher) {
            switch self {
            case .share, .delete:
                hasher.combine(String(describing: self))
            case .custom(let identifier, _, _):
                hasher.combine(identifier)
            }
        }
    }

    public struct MediaType: OptionSet, Hashable {
        public let rawValue: Int
        
        public static let images = MediaType(rawValue: 1 << 0)
        public static let videos = MediaType(rawValue: 1 << 1)
        public static let pdf = MediaType(rawValue: 1 << 2)
        public static let all: MediaType = [.images, .videos, .pdf]
        
        public init(rawValue: Int) {
            self.rawValue = rawValue
        }
    }
}

extension IFBrowserViewController.Configuration {
    func actions(for media: IFMedia) -> [IFBrowserViewController.Action] {
        switch media.mediaType {
        case .image:
            return actions(for: .images)
        case .video:
            return actions(for: .videos)
        case .pdf:
            return actions(for: .pdf)
        }
    }
    
    func placeholder(for media: IFMedia) -> UIImage? {
        switch media.mediaType {
        case .image:
            return placeholder(for: .images)
        case .video:
            return placeholder(for: .videos)
        case .pdf:
            return placeholder(for: .pdf)
        }
    }
}
