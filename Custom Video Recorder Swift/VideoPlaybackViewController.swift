//
//  VideoPlaybackViewController.swift
//  Custom Video Recorder Swift
//
//  Created by Cedan Misquith on 19/10/22.
//

import UIKit
import AVFoundation

class VideoPlaybackViewController: UIViewController {
    
    // MARK: UI Elements
    @IBOutlet weak var videoPlayerView: UIView!
    @IBOutlet weak var retakeButton: UIButton!
    @IBOutlet weak var seekSlider: UISlider!
    @IBOutlet weak var videoDurationLabel: UILabel!
    @IBOutlet weak var playBackDurationLabel: UILabel!
    @IBOutlet weak var playPauseButton: UIButton!
    
    // MARK: Variables
    var player = AVPlayer()
    var playBackTimer: Timer!
    var currentPlaybackValue: Int!
    var recordedVideo: URL!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        applyStyling()
        applyFonts()
        NotificationCenter.default.addObserver(self, selector: #selector(playerDidFinishPlaying),
                                               name: .AVPlayerItemDidPlayToEndTime, object: nil)
    }
    deinit {
        print("Reclaiming memory for 'VideoPlaybackViewController' - No Retain Cycles/Memory Leaks")
        NotificationCenter.default.removeObserver(self,
                                                  name: .AVPlayerItemDidPlayToEndTime,
                                                  object: nil)
    }
    override func viewWillAppear(_ animated: Bool) {
        initializeVideoPlayerWithVideo()
    }
    override func viewWillDisappear(_ animated: Bool) {
        player.replaceCurrentItem(with: nil)
    }
    fileprivate func configurePlaybackTimer(value: Int = 1) {
        currentPlaybackValue = value
        playBackTimer?.invalidate()
        playBackTimer = Timer.scheduledTimer(withTimeInterval: 1,
                                             repeats: true) { [weak self] _ in
            let secondsText = String(format: "%02d", Int(self?.currentPlaybackValue ?? 0) % 60)
            let minuteText = String(format: "%02d", Int(self?.currentPlaybackValue ?? 0) / 60)
            self?.playBackDurationLabel.text = "\(minuteText):\(secondsText)"
            self?.currentPlaybackValue += 1
        }
    }
    fileprivate func applyStyling() {
        seekSlider.isContinuous = false
        seekSlider.setThumbImage(UIImage(named: "seekSliderThumbIcon"), for: .normal)
        retakeButton.layer.cornerRadius = 8
        retakeButton.layer.borderWidth = 1
        retakeButton.layer.borderColor = UIColor.white.cgColor
        retakeButton.setTitleColor(.white, for: .normal)
        retakeButton.setTitle("Retake", for: .normal)
    }
    fileprivate func applyFonts() {
        retakeButton.titleLabel?.font = UIFont.systemFont(ofSize: 20)
    }
    // Detect when video has completed play and start again (Loop)
    @objc func playerDidFinishPlaying() {
        playBackDurationLabel.text = "00:00"
        player.seek(to: .zero)
        player.play()
        configurePlaybackTimer()
    }
    fileprivate func initializeVideoPlayerWithVideo() {
        // Initialize the video player with the url
        if let filePath = recordedVideo { // AppIDKEYS.videoCompressFilePath
            // Get video duration and set it to the duration label
            let seconds = AVURLAsset(url: filePath).duration.seconds
            let secondsText = String(format: "%02d", Int(seconds) % 60)
            let minuteText = String(format: "%02d", Int(seconds) / 60)
            videoDurationLabel.text = "\(minuteText):\(secondsText)"
            self.player = AVPlayer(url: filePath)
            // Create a video layer for the player
            let layer: AVPlayerLayer = AVPlayerLayer(player: player)
            // Make the layer the same size as the container view
            layer.frame = self.view.bounds
            // Make the video fill the layer as much as possible while keeping its aspect size
            layer.videoGravity = AVLayerVideoGravity.resizeAspectFill
            // Add the layer to the container view
            videoPlayerView.layer.addSublayer(layer)
            player.addProgressObserver { [weak self] progress in
                self?.seekSlider.setValue(Float(progress), animated: true)
            }
            player.play()
            configurePlaybackTimer()
        }
    }
    @objc fileprivate func deleteRecordedView() {
        let fileUrl = FileManager.default.urls(
            for: .documentDirectory,
            in: .userDomainMask).first?.deletingPathExtension().appendingPathComponent(
                "recording.mp4",
                isDirectory: false
            )
        if FileManager.default.fileExists(atPath: fileUrl?.path ?? "") {
            // Delete file
            do {
                try FileManager.default.removeItem(atPath: fileUrl?.path ?? "")
                print("Delete successful")
            } catch {
                print("Could not delete file, probably read-only filesystem")
            }
        } else {
            print("File not found")
        }
        self.navigationController?.popViewController(animated: true)
    }
    @IBAction func playPauseButtonAction(_ sender: UIButton) {
        if player.rate == 1 {
            player.pause()
            playBackTimer.invalidate()
            playPauseButton.setImage(UIImage(named: "playVideoIcon"), for: .normal)
        } else {
            player.play()
            configurePlaybackTimer(value: currentPlaybackValue)
            playPauseButton.setImage(nil, for: .normal)
        }
    }
    @IBAction func seekSliderAction(_ sender: UISlider) {
        if let duration = player.currentItem?.duration {
            let totalSeconds = CMTimeGetSeconds(duration)
            let value = Float64(sender.value) * totalSeconds
            let seekTime = CMTime(value: Int64(value), timescale: 1)
            player.seek(to: seekTime) { completedSeek in
                if completedSeek {
                    self.player.play()
                    self.playPauseButton.setImage(nil, for: .normal)
                    self.configurePlaybackTimer(value: Int(round(value)))
                }
            }
        }
    }
    @IBAction func retakeVideoButtonAction(_ sender: UIButton) {
        deleteRecordedView()
    }
}
