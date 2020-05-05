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
    var browserViewController: IFBrowserViewController {
        let images = IFImage.mock
        let viewController = IFBrowserViewController(images: images, initialImageIndex: .random(in: images.indices))
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
