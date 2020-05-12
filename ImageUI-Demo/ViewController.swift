//
//  ViewController.swift
//  ImageUI-Demo
//
//  Created by Alberto Saltarelli on 12/05/2020.
//  Copyright © 2020 Alberto Saltarelli. All rights reserved.
//

import UIKit
import ImageUI

class ViewController: UIViewController {
    var browserViewController: IFBrowserViewController {
        let images = IFImage.mock
        let viewController = IFBrowserViewController(images: images, initialImageIndex: .random(in: images.indices))
        viewController.actions = [.share]
        return viewController
    }

    @IBAction private func pushButtonDidTap() {
        navigationController?.pushViewController(browserViewController, animated: true)
    }
    
    @IBAction private func presentButtonDidTap() {
        let navigationController = UINavigationController(rootViewController: browserViewController)
        navigationController.modalPresentationStyle = .fullScreen
        present(navigationController, animated: true)
    }
}

