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
    public enum Action: Hashable {
        case share
        case delete
        case custom(identifier: String, image: UIImage)
        
        public func hash(into hasher: inout Hasher) {
            switch self {
            case .share, .delete:
                hasher.combine(String(describing: self))
            case .custom(let identifier, _):
                hasher.combine(identifier)
            }
        }
    }
    
    public struct Configuration {
        public var actions: [Action]
        
        /// A Boolean value specifying whether the image should be zoomed to fill the entire container
        ///
        /// When this property is set to `true`, the browser allows the image to be displayed using the aspect fill zoom if the aspect ratio is similar to its container view one.
        ///
        /// When the property is set to `false` (the default), the browser use the aspect fit zoom as its minimum zoom value.
        public var prefersAspectFillZoom: Bool = false

        /// A Boolean value indicating whether the navigation bar is always visible.
        ///
        /// When this property is set to `true` (the default), the browser shows the navigation bar even if the navigation controller property `isNavigationBarHidden` is set to `true`.
        ///
        /// When the property is set to `false`, the browser shows the navigation bar when it is available.
        public var alwaysShowNavigationBar: Bool = true
        
        /// A Boolean value indicating whether the navigation controller’s built-in toolbar is always visible.
        ///
        /// When this property is set to `true`, the browser shows the toolbar even if there is no actions
        ///
        /// When the property is set to `false` (the default), the browser shows the toolbar when it is available.
        public var alwaysShowToolbar: Bool = false
        
        var isNavigationBarHidden = false
        var isToolbarHidden = true
        
        public init(
            actions: [Action] = [],
            prefersAspectFillZoom: Bool = false,
            alwaysShowNavigationBar: Bool = true,
            alwaysShowToolbar: Bool = false,
            isNavigationBarHidden: Bool = false,
            isToolbarHidden: Bool = true) {
                self.actions = actions
                self.prefersAspectFillZoom = prefersAspectFillZoom
                self.alwaysShowNavigationBar = alwaysShowNavigationBar
                self.alwaysShowToolbar = alwaysShowToolbar
                self.isNavigationBarHidden = isNavigationBarHidden
                self.isToolbarHidden = isToolbarHidden
            }
    }
}
