//
//  IFImage+Mock.swift
//  ImageUI-Demo
//
//  Created by Alberto Saltarelli on 12/05/2020.
//  Copyright © 2020 Alberto Saltarelli. All rights reserved.
//

import UIKit
import ImageUI

extension IFImage {
    static let mock: [IFImage] = {
        [localImages, remoteImages, memoryImages].flatMap { $0 }.shuffled()
    }()

    private static let localImages = [
        Bundle.main.path(forResource: "Image1", ofType: "jpeg")!,
        Bundle.main.path(forResource: "Image2", ofType: "jpeg")!,
        Bundle.main.path(forResource: "Image3", ofType: "jpeg")!,
        Bundle.main.path(forResource: "Image4", ofType: "jpeg")!,
        Bundle.main.path(forResource: "Image5", ofType: "jpeg")!
        ].enumerated().map { IFImage(title: "Local file \($0.offset + 1)", path: $0.element) }

    private static let remoteImages: [IFImage] = [
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
            var image = IFImage(title: "Remote image \($0.offset + 1)", url: URL(string: $0.element)!)
            image.placeholder = UIImage(color: UIColor(white: 0.9, alpha: 0.5))
            return image
    }

    private static let memoryImages = [UIImage(named: "photo1")!, UIImage(named: "photo2")!]
        .enumerated()
        .map { IFImage(title: "In-memory image \($0.offset + 1)", original: .image($0.element)) }
}
