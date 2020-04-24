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
    let images: [IFImage] = [
        "https://i.imgur.com/GJoXDDu.jpg",
        "https://i.imgur.com/NCaJTv1.jpeg",
        Bundle.main.path(forResource: "Image1", ofType: "jpeg")!,
        "https://i.imgur.com/2zyjIRm.jpg",
        "https://i.imgur.com/HhkyHKQ.jpeg",
        "https://i.imgur.com/hHHXUoG.jpeg",
        Bundle.main.path(forResource: "Image2", ofType: "jpeg")!,
        "https://i.imgur.com/dgsC5L9.jpg",
        "https://i.imgur.com/CIEPYb6.jpg",
        "https://i.imgur.com/oBoLh3W.jpeg",
        Bundle.main.path(forResource: "Image3", ofType: "jpeg")!,
        "https://i.imgur.com/yRkK3il.jpeg",
        "https://i.imgur.com/EW1UMtj.jpeg",
        "https://i.imgur.com/RG7gRc7.jpg",
        Bundle.main.path(forResource: "Image4", ofType: "jpeg")!,
        "https://i.imgur.com/yYpFuFt.jpeg",
        "https://i.imgur.com/P2m2ZYf.jpeg",
        "https://i.imgur.com/dapWvP3.jpeg",
        Bundle.main.path(forResource: "Image5", ofType: "jpeg")!,
        "https://i.imgur.com/myQHEsY.jpeg",
        "https://i.imgur.com/FE4nY3N.jpg",
        "https://i.imgur.com/04JTu29.jpeg",
        "https://i.imgur.com/1dDczmF.jpg",
        "https://i.imgur.com/iB9kaqB.jpg",
        "https://i.imgur.com/klfsNhq.jpg",
        "https://i.imgur.com/LHDhBwR.jpg",
        "https://i.imgur.com/XawVasr.jpeg",
        "https://i.imgur.com/3xDRjrW.jpeg",
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
        "https://i.imgur.com/3xDRjrW.jpeg",
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
        "https://i.imgur.com/3xDRjrW.jpeg",
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
        ].enumerated().map {
            switch $0.offset {
            case 2, 6, 10, 14, 18:
                return IFImage(title: "Image \($0.offset + 1)", path: $0.element)
            default:
                return IFImage(title: "Image \($0.offset + 1)", url: URL(string: $0.element)!)
            }
        }
    
    var browserViewController: IFBrowserViewController {
        let viewController = IFBrowserViewController(images: images, initialImageIndex: 9)
        viewController.actions = [.share, .delete]
        return viewController
    }
    
    @IBAction private func showImagesButtonDidTap() {
        navigationController?.pushViewController(browserViewController, animated: true)
    }
    
    @IBAction private func presentImagesButtonDidTap() {
        let navigationController = UINavigationController(rootViewController: browserViewController)
        navigationController.modalPresentationStyle = .fullScreen
        present(navigationController, animated: true)
    }
}
