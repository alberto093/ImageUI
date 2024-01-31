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
import SwiftUI

class ViewController: UIViewController {
    
    private var enableSwiftUI = false
    
    var browserViewController: IFBrowserViewController {
        let media = IFMedia.mock
        let viewController = IFBrowserViewController(media: media, initialIndex: .random(in: media.indices))
        viewController.configuration.actions = [.share, .delete]
        viewController.delegate = self
        return viewController
    }
    
    var browserHostingViewController: UIHostingController<IFBrowserView> {
        let media = IFMedia.mock
        let configuration = IFBrowserViewController.Configuration(actions: [.share, .delete])
        let contentView = IFBrowserView(
            media: media,
            selectedIndex: .constant(.random(in: media.indices)),
            configuration: configuration,
            action: { identifier in
                print(identifier)
            })
        
        return UIHostingController(rootView: contentView)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        navigationController?.navigationBar.scrollEdgeAppearance = navigationController?.navigationBar.standardAppearance
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        PHPhotoLibrary.requestAuthorization { _ in }
    }

    @IBAction private func pushButtonDidTap() {

        navigationController?.pushViewController(enableSwiftUI ? browserHostingViewController : browserViewController, animated: true)
    }

    @IBAction private func presentButtonDidTap() {
        let navigationController = UINavigationController(rootViewController: enableSwiftUI ? browserHostingViewController : browserViewController)
        navigationController.navigationBar.scrollEdgeAppearance = navigationController.navigationBar.standardAppearance
        navigationController.modalPresentationStyle = .fullScreen
        present(navigationController, animated: true)
    }
    
    @IBAction private func swiftUISwitchDidChange(_ sender: UISwitch) {
        enableSwiftUI = sender.isOn
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
