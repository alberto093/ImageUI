//
//  ViewController.swift
//  ImageUI-Demo
//
//  Created by Alberto Saltarelli on 12/05/2020.
//  Copyright © 2020 Alberto Saltarelli. All rights reserved.
//

import UIKit
import ImageUI
import Photos

class ViewController: UIViewController {
    var browserViewController: IFBrowserViewController {
        let images = IFImage.mock
        let viewController = IFBrowserViewController(images: images, initialImageIndex: .random(in: images.indices))
        viewController.configuration.actions = [.share, .delete]
        viewController.delegate = self
        return viewController
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        PHPhotoLibrary.requestAuthorization { _ in }
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

extension ViewController: IFBrowserViewControllerDelegate {
    func browserViewController(_ browserViewController: IFBrowserViewController, didDeleteItemAt index: Int, isEmpty: Bool) {
        guard isEmpty else { return }
        if navigationController?.topViewController === browserViewController {
            navigationController?.popViewController(animated: true)
        } else {
            dismiss(animated: true)
        }
    }
}
