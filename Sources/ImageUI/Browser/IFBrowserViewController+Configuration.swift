//
//  IFBrowserViewController+Configuration.swift
//  
//
//  Created by Alberto Saltarelli on 12/05/2020.
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
        public var prefersAspectFillZoom: Bool

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
        
        public init(actions: [Action] = [], prefersAspectFillZoom: Bool = false) {
            self.actions = actions
            self.prefersAspectFillZoom = prefersAspectFillZoom
        }
    }
}
