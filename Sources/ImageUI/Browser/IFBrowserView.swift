//
//  IFBrowserView.swift
//  ImageUIDemo
//
//  Created by Alberto Saltarelli on 09/05/2020.
//  Copyright © 2020 Alberto Saltarelli. All rights reserved.
//

#if canImport(SwiftUI)

import SwiftUI

@available(iOS 13.0, *)
public struct IFBrowserView: UIViewControllerRepresentable {
    public typealias ImageAction = (_ identifier: String) -> Void
    private let images: [IFImage]
    @Binding private var selectedIndex: Int
    private let imageAction: ImageAction?
    
    public init(images: [IFImage], selectedIndex: Binding<Int>, action: ImageAction? = nil) {
        self.images = images
        self._selectedIndex = selectedIndex
        self.imageAction = action
    }
    
    public func makeUIViewController(context: Context) -> IFBrowserViewController {
        let viewController = IFBrowserViewController(images: images, initialImageIndex: selectedIndex)
        viewController.delegate = context.coordinator
        return viewController
    }
    
    public func updateUIViewController(_ uiViewController: IFBrowserViewController, context: Context) {
        
    }
    
    public func makeCoordinator() -> Coordinator {
        Coordinator(sourceView: self)
    }
}

@available(iOS 13.0, *)
public extension IFBrowserView {
    class Coordinator: NSObject, IFBrowserViewControllerDelegate {
        let sourceView: IFBrowserView

        init(sourceView: IFBrowserView) {
            self.sourceView = sourceView
        }
        
        public func browserViewController(_ browserViewController: IFBrowserViewController, didSelectActionWith identifier: String, forImageAt index: Int) {
            sourceView.imageAction?(identifier)
        }
    }
}

#endif
