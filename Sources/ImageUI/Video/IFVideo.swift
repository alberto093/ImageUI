//
//  IFVideo.swift
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
//  THE SOFTWARE.
//

import Foundation
import Photos
import AVFoundation
import UIKit

public final class IFVideo {
    public enum Source {
        case url(_ url: URL)
        case video(AVAsset)
        case asset(PHAsset)
    }
    
    public enum Cover {
        case image(IFImage.Source)
        case seek(CMTime = .zero)
    }
    
    public let media: Source
    
    /// Cover should have the same size as media in width/height pixels
    public internal(set) var cover: Cover
    
    public let placeholder: UIImage?
    
    public init(media: Source, cover: Cover = .seek(), placeholder: UIImage? = nil) {
        self.media = media
        self.cover = cover
        self.placeholder = placeholder
    }
}

extension IFVideo {
    enum Status {
        case autoplay
        case autoplayPause
        case autoplayEnded
        case play
        case pause
        
        var isAutoplay: Bool {
            switch self {
            case .autoplay, .autoplayPause, .autoplayEnded:
                return true
            case .play, .pause:
                return false
            }
        }
        
        mutating func toggle() {
            switch self {
            case .autoplay:
                self = .autoplayPause
            case .autoplayPause, .autoplayEnded:
                self = .play
            case .play:
                self = .pause
            case .pause:
                self = .play
            }
        }
    }
    
    struct Playback {
        var currentTime: CMTime
        let totalDuration: CMTime
        
        var progress: Double {
            (currentTime.seconds / totalDuration.seconds).clamped(to: 0...1)
        }
    }
    
    enum AudioStatus {
        case disabled
        case enabled
        case muted // user tap on enabled sound button
        
        var isEnabled: Bool {
            switch self {
            case .disabled, .muted:
                return false
            case .enabled:
                return true
            }
        }
        
        mutating func toggle() {
            switch self {
            case .disabled:
                self = .enabled
            case .enabled:
                self = .muted
            case .muted:
                self = .enabled
            }
        }
    }
}
