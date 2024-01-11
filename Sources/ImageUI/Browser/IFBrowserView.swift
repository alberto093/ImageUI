//
//  IFBrowserView.swift
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
//

#if canImport(SwiftUI)

import SwiftUI

@available(iOS 13.0, *)
public struct IFBrowserView: UIViewControllerRepresentable {
    public typealias ImageAction = (_ identifier: String) -> Void
    private let images: [IFImage]
    @Binding private var selectedIndex: Int
    private let imageAction: ImageAction?
    
    public init(
        images: [IFImage],
        selectedIndex: Binding<Int>,
        configuration: IFBrowserViewController.Configuration = IFBrowserViewController.Configuration(),
        action: ImageAction? = nil) {
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
