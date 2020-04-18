//
//  ViewController.swift
//  ImageUI
//
//  Created by alberto093 on 04/12/2020.
//  Copyright (c) 2020 alberto093. All rights reserved.
//

import UIKit
import ImageUI

class ViewController: UIViewController {
    let images = [
        "https://i.imgur.com/GJoXDDu.jpg",
        "https://i.imgur.com/NCaJTv1.jpeg",
        "https://i.imgur.com/2zyjIRm.jpg",
        "https://i.imgur.com/HhkyHKQ.jpeg",
        "https://i.imgur.com/hHHXUoG.jpeg",
        "https://i.imgur.com/dgsC5L9.jpg",
        "https://i.imgur.com/CIEPYb6.jpg",
        "https://i.imgur.com/oBoLh3W.jpeg",
        "https://i.imgur.com/yRkK3il.jpeg",
        "https://i.imgur.com/EW1UMtj.jpeg",
        "https://i.imgur.com/RG7gRc7.jpg",
        "https://i.imgur.com/yYpFuFt.jpeg",
        "https://i.imgur.com/P2m2ZYf.jpeg",
        "https://i.imgur.com/dapWvP3.jpeg",
        "https://i.imgur.com/myQHEsY.jpeg",
        "https://i.imgur.com/FE4nY3N.jpg",
        "https://i.imgur.com/04JTu29.jpeg",
        "https://i.imgur.com/1dDczmF.jpg",
        "https://i.imgur.com/iB9kaqB.jpg",
        "https://i.imgur.com/klfsNhq.jpg",
        "https://i.imgur.com/LHDhBwR.jpg",
        "https://i.imgur.com/XawVasr.jpeg",
        "https://i.imgur.com/3xDRjrW.jpeg"
        ].enumerated().map { IFImage(title: "Image \($0.offset + 1)", url: URL(string: $0.element)!)  }
    
    @IBAction private func showImagesButtonDidTap() {
        let viewController = IFBrowserViewController(images: images, initialImageIndex: 10)
        viewController.title = "Images"
        viewController.actions = [.share, .delete]
        navigationController?.pushViewController(viewController, animated: true)
    }
    
    @IBAction private func presentImagesButtonDidTap() {
        let viewController = IFBrowserViewController(images: images, initialImageIndex: 10)
        viewController.title = "Images"
        viewController.actions = [.share, .delete]
        let navigationController = UINavigationController(rootViewController: viewController)
        navigationController.modalPresentationStyle = .fullScreen
        present(navigationController, animated: true)
    }
}
