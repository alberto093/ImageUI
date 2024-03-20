//
//  IFPDFLoadingView.swift
//
//
//  Created by Alberto Saltarelli on 20/03/24.
//

import Foundation
import UIKit

public protocol IFPDFProgressView: UIView {
    var progress: Float { get set }
}

extension UIProgressView: IFPDFProgressView { }
