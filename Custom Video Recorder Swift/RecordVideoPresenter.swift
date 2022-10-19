//
//  RecordVideoPresenter.swift
//  Custom Video Recorder Swift
//
//  Created by Cedan Misquith on 19/10/22.
//

import Foundation

// MARK: Camera count down timer options
enum CameraCountDown {
    static let NONE = { return 0 }
    static let SHORT = { return 3 }
    static let MEDIUM = { return 5 }
    static let LONG = { return 10 }
}

protocol RecordVideoPresenterProtocol: AnyObject {
    func updateTimerLabel(value: String)
    func showTimerLabel()
    func hideTimerLabel()
}

class RecordVideoPresenter: NSObject {
    weak var delegate: RecordVideoPresenterProtocol?
    var countDownPreset: Int = CameraCountDown.NONE()
    var countDownValue: Int!
    var timer: Timer!
    init(delegate: RecordVideoPresenterProtocol) {
        super.init()
        self.delegate = delegate
        countDownValue = countDownPreset
    }
    func resetCountDownValue() {
        countDownValue = countDownPreset
        timer?.invalidate()
    }
    func initializeCountDownTimer() {
        delegate?.showTimerLabel()
        timer?.invalidate()
        timer = Timer.scheduledTimer(timeInterval: 1,
                                     target: self, selector: #selector(timerExecuted),
                                     userInfo: nil, repeats: true)
    }
    @objc fileprivate func timerExecuted() {
        if countDownValue == 0 {
            delegate?.updateTimerLabel(value: "START")
        } else if countDownValue > 0 {
            delegate?.updateTimerLabel(value: String(countDownValue ?? 0))
        } else {
            delegate?.hideTimerLabel()
            countDownValue = countDownPreset
            timer.invalidate()
        }
        countDownValue -= 1
    }
}

