//
//  CMTime+.swift
//  
//
//  Created by Alberto Saltarelli on 12/02/24.
//

import AVFoundation

extension CMTime {
    var formattedProgress: String {
        let duration = seconds
        
        let hours = Int(duration / 3600)
        let minutes = Int(duration.truncatingRemainder(dividingBy: 3600) / 60)
        let seconds = Int(duration.truncatingRemainder(dividingBy: 60))
        
        if hours < 1 {
            return String(format: "%02d:%02d", minutes, seconds)
        } else {
            return String(format: "%02d:%02d:%02d", hours, minutes, seconds)
        }
    }
}
