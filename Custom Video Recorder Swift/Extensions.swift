//
//  Extensions.swift
//  Custom Video Recorder Swift
//
//  Created by Cedan Misquith on 19/10/22.
//

import UIKit
import AVFoundation

// Extension to handle flash toggle and check if flash is enabled or not.
extension UIDevice {
    static func isFlashActive() -> Bool {
        guard let device = AVCaptureDevice.default(for: .video), device.hasTorch else { return false }
        return device.isTorchActive
    }
    static func toggleFlashLight() {
        guard let device = AVCaptureDevice.default(for: .video), device.hasTorch else { return }
        do {
            try device.lockForConfiguration()
            try device.setTorchModeOn(level: 1.0)
            device.torchMode = device.isTorchActive ? .off : .on
            device.unlockForConfiguration()
        } catch {
            assert(false, "Error: Problem with toggling flashlight\n\(error)")
        }
    }
}

// Extension to check the current orientation of the device.
extension UIInterfaceOrientation {
    var videoOrientation: AVCaptureVideoOrientation? {
        switch self {
        case .portraitUpsideDown: return .portraitUpsideDown
        case .landscapeRight: return .landscapeRight
        case .landscapeLeft: return .landscapeLeft
        case .portrait: return .portrait
        default: return nil
        }
    }
}

// Extension to track the progress of a playing video.
extension AVPlayer {
    func addProgressObserver(action:@escaping ((Double) -> Void)) {
        self.addPeriodicTimeObserver(forInterval: CMTime.init(value: 1, timescale: 1), queue: .main, using: { time in
            if let duration = self.currentItem?.duration {
                let duration = CMTimeGetSeconds(duration), time = CMTimeGetSeconds(time)
                let progress = (time/duration)
                action(progress)
            }
        })
    }
}

