//
//  RecordVideoViewController.swift
//  Custom Video Recorder Swift
//
//  Created by Cedan Misquith on 19/10/22.
//

import UIKit
import AVFoundation

class RecordVideoViewController: UIViewController {
    
    // MARK: UI Elements
    @IBOutlet weak var previewView: UIView!
    @IBOutlet weak var recordedTimerLabel: UILabel!
    @IBOutlet weak var recordButton: UIButton!
    @IBOutlet weak var flashButton: UIButton!
    @IBOutlet weak var timerButton: UIButton!
    @IBOutlet weak var timerLabel: UILabel!
    @IBOutlet weak var cancelButton: UIButton!
    @IBOutlet weak var flipCameraButton: UIButton!

    // MARK: Variables
    var cameraPosition: CameraPosition = .FRONT
    var captureSession: AVCaptureSession?
    var videoPreviewLayer: AVCaptureVideoPreviewLayer?
    var audioDevice: AVCaptureDevice?
    var movieFileOutput: AVCaptureMovieFileOutput!
    var audioInput: AVCaptureDeviceInput?
    var isStarted: Bool = false
    var presenter: RecordVideoPresenter!
    var recordingTimer: Timer!
    var timerCount: Int = 0
    
    // MARK: Camera States
    enum CameraPosition {
        case FRONT
        case BACK
    }
    override func viewDidLoad() {
        super.viewDidLoad()
        presenter = RecordVideoPresenter(delegate: self)
        applyStyling()
        applyFonts()
        configureCaptureSession()
    }
    deinit {
        print("Reclaiming memory for 'RecordVideoViewController' - No Retain Cycles/Memory Leaks")
    }
    
    // MARK: Get camera permission to record video and audio
    func checkCameraAccess() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .denied:
            print("Permissions Denied, Please request permission from settings.")
            presentCameraSettings(message: "Permissions Denied, Please request permission from settings.")
        case .restricted:
            print("Restricted, device owner must approve")
            presentCameraSettings(message: "Restricted, device owner must approve")
        case .authorized:
            print("Authorized, proceed")
            configureCaptureSession()
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { success in
                if success {
                    print("Permission granted, proceed")
                    self.configureCaptureSession()
                } else {
                    print("Permission denied")
                    self.presentCameraSettings(message: "Permission denied")
                }
            }
        @unknown default:
            print("Unknown type.")
        }
    }
    func presentCameraSettings(message: String) {
        let alertController = UIAlertController(title: "Error",
                                                message: message,
                                                preferredStyle: .alert)
        alertController.addAction(UIAlertAction(title: "Cancel", style: .default))
        alertController.addAction(UIAlertAction(title: "Settings", style: .cancel) { _ in
            if let url = URL(string: UIApplication.openSettingsURLString) {
                UIApplication.shared.open(url, options: [:], completionHandler: { _ in
                    self.configureCaptureSession()
                })
            }
        })
        present(alertController, animated: true)
    }
    override func viewDidAppear(_ animated: Bool) {
        // Starting camera capture session from background thread.
        DispatchQueue.global(qos: .background).async {
            self.captureSession?.startRunning()
        }
        setFlashButtonState()
    }
    fileprivate func applyStyling() {
        timerLabel.textColor = .white
        cancelButton.setTitleColor(.white, for: .normal)
    }
    fileprivate func applyFonts() {
        timerLabel.font = UIFont.systemFont(ofSize: 260)
        cancelButton.titleLabel?.font = UIFont.systemFont(ofSize: 17)
    }
    fileprivate func configureCaptureSession() {
        /*
         Get an instance of the AVCaptureDevice class to initialize a device object and provide the video
         as the media type parameter
         */
        guard let captureDevice = AVCaptureDevice.default(
            AVCaptureDevice.DeviceType.builtInWideAngleCamera,
            for: .video, position: cameraPosition == .BACK ? .back : .front) else {
            return
        }
        do {
            // Get an instance of the AVCaptureDeviceInput class using the previous deivce object
            let input = try AVCaptureDeviceInput(device: captureDevice)
            // Initialize the captureSession object
            captureSession = AVCaptureSession()
            // Set the input devcie on the capture session
            captureSession?.addInput(input)
            // Initalize video outPut
            movieFileOutput = nil
            movieFileOutput = AVCaptureMovieFileOutput()
            movieFileOutput.movieFragmentInterval = .invalid
            captureSession?.addOutput(movieFileOutput)
            // Initialize a AVCaptureMetadataOutput object and set it as the input device
            let captureMetadataOutput = AVCaptureMetadataOutput()
            captureSession?.addOutput(captureMetadataOutput)
            // Initialise the video preview layer and add it as a sublayer to the viewPreview view's layer
            videoPreviewLayer = AVCaptureVideoPreviewLayer(session: captureSession!)
            videoPreviewLayer?.videoGravity = AVLayerVideoGravity.resizeAspectFill
            videoPreviewLayer?.frame = view.layer.bounds
            previewView.layer.addSublayer(videoPreviewLayer!)
            // Capture audio for the video being recorded
            self.audioDevice = AVCaptureDevice.default(for: AVMediaType.audio)
            if let audioDevice = self.audioDevice {
                self.audioInput = try AVCaptureDeviceInput(device: audioDevice)
                if (captureSession?.canAddInput(self.audioInput!)) != nil {
                    captureSession?.addInput(self.audioInput!)
                } else {
                    print("Error loading microphone")
                }
            }
            // Start video capture
            DispatchQueue.global(qos: .background).async {
                self.captureSession?.startRunning()
            }
        } catch {
            // If any error occurs, simply print it out
            print(error)
            return
        }
    }
    fileprivate func setFlashButtonState() {
        if cameraPosition == .FRONT {
            flashButton.isHidden = true
        } else {
            flashButton.isHidden = false
        }
    }
    // Starting the timer for recorder
    fileprivate func startRecordingTimer() {
        recordedTimerLabel.backgroundColor = .red
        recordingTimer = Timer.scheduledTimer(timeInterval: 1,
                                              target: self,
                                              selector: #selector(recordingTimerElapsed),
                                              userInfo: nil, repeats: true)
    }
    // Stopping the timer while recording completes
    fileprivate func stopRecordingTimer() {
        timerCount = 0
        recordedTimerLabel.text = "00:00:00"
        recordedTimerLabel.backgroundColor = .clear
        recordingTimer.invalidate()
        recordingTimer = nil
    }
    // Updating the time elapsed of recording
    @objc func recordingTimerElapsed() {
        recordedTimerLabel.text = "\(secondsToHoursMinutesSeconds(timerCount))"
        timerCount += 1
    }
    // Formatting timer values
    fileprivate func secondsToHoursMinutesSeconds(_ seconds: Int) -> String {
        let hours = seconds / 3600
        let minutes = (seconds % 3600) / 60
        let seconds = (seconds % 3600) % 60
        let hoursString = String(format: "%02d", hours)
        let minutesString = String(format: "%02d", minutes)
        let secondsString = String(format: "%02d", seconds)
        let returnString = "\(hoursString):\(minutesString):\(secondsString)"
        return returnString
    }
    // Start recording and create the storage path for recorded file
    fileprivate func startRecording() {
        startRecordingTimer()
        let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0] as URL
        let filePath = documentsURL.appendingPathComponent("recording.mp4")
        if FileManager.default.fileExists(atPath: filePath.absoluteString) {
            do {
                try FileManager.default.removeItem(at: filePath)
                print("\(filePath.absoluteString)")
            } catch {
                // Error if any
                print("Could not save the video at path: \(filePath.absoluteString)")
            }
        }
        movieFileOutput.startRecording(to: filePath, recordingDelegate: self)
    }
    fileprivate func showOptions() {
        flashButton.isHidden = false
        timerButton.isHidden = false
        flipCameraButton.isHidden = false
        cancelButton.isHidden = false
    }
    fileprivate func hideOptions() {
        flashButton.isHidden = true
        timerButton.isHidden = true
        flipCameraButton.isHidden = true
        cancelButton.isHidden = true
    }
    override func viewDidLayoutSubviews() {
        videoPreviewLayer?.frame = view.bounds
        if let previewLayer = videoPreviewLayer,
           ((previewLayer.connection?.isVideoOrientationSupported) != nil) {
            let appOrientation = UIApplication.shared.statusBarOrientation.videoOrientation ?? .portrait
            previewLayer.connection?.videoOrientation = appOrientation
        }
    }
    // Toggle flash on and off while on back camera only
    @IBAction func toggleFlashButtonAction(_ sender: UIButton) {
        UIDevice.toggleFlashLight()
        if UIDevice.isFlashActive() {
            flashButton.setImage(UIImage(named: "flashOnIcon"), for: .normal)
        } else {
            flashButton.setImage(UIImage(named: "flashOffIcon"), for: .normal)
        }
    }
    // Toggle between none, 3, 5, 10 second count down timer when recording starts
    @IBAction func timerButtonAction(_ sender: UIButton) {
        switch presenter.countDownPreset {
        case CameraCountDown.NONE():
            presenter.countDownPreset = CameraCountDown.SHORT()
            timerButton.setImage(UIImage(named: "3secTimerIcon"), for: .normal)
        case CameraCountDown.SHORT():
            presenter.countDownPreset = CameraCountDown.MEDIUM()
            timerButton.setImage(UIImage(named: "5secTimerIcon"), for: .normal)
        case CameraCountDown.MEDIUM():
            presenter.countDownPreset = CameraCountDown.LONG()
            timerButton.setImage(UIImage(named: "10secTimerIcon"), for: .normal)
        default:
            presenter.countDownPreset = CameraCountDown.NONE()
            timerButton.setImage(UIImage(named: "noTimerIcon"), for: .normal)
        }
        timerLabel.text = ""
        timerLabel.font = UIFont.systemFont(ofSize: 260)
        presenter.resetCountDownValue()
    }
    @IBAction func cancelButtonAction(_ sender: UIButton) {
        self.navigationController?.popViewController(animated: true)
    }
    // Switch between front and back camera
    @IBAction func flipCameraButtonAction(_ sender: UIButton) {
        captureSession?.stopRunning()
        cameraPosition = cameraPosition == .BACK ? .FRONT : .BACK
        configureCaptureSession()
        if cameraPosition == .FRONT {
            UIView.animate(withDuration: 0.25, animations: {
                sender.transform = CGAffineTransform(rotationAngle: CGFloat.pi)
            })
        } else {
            flashButton.setImage(UIImage(named: "flashOnIcon"), for: .normal)
            UIView.animate(withDuration: 0.25, animations: {
                sender.transform = CGAffineTransform(rotationAngle: CGFloat.pi * 2)
            })
        }
        setFlashButtonState()
    }
    @IBAction func recordButtonAction(_ sender: UIButton) {
        if self.isStarted {
            UIApplication.shared.isIdleTimerDisabled = false
            self.recordButton.setImage(UIImage(named: "startRecordIcon"), for: .normal)
            self.movieFileOutput.stopRecording()
            self.showOptions()
            self.presenter.resetCountDownValue()
            if UIDevice.isFlashActive() {
                UIDevice.toggleFlashLight()
                self.flashButton.setImage(UIImage(named: "flashOnIcon"), for: .normal)
            }
            self.stopRecordingTimer()
        } else {
            UIApplication.shared.isIdleTimerDisabled = true
            self.hideOptions()
            self.recordButton.isUserInteractionEnabled = false
            self.presenter.initializeCountDownTimer()
        }
        self.isStarted = !self.isStarted
    }
    fileprivate func goToVideoPlayback(url: URL) {
        guard let playbackVC = storyboard?.instantiateViewController(
            withIdentifier: "VideoPlaybackViewController") as? VideoPlaybackViewController else {
            return
        }
        playbackVC.recordedVideo = url
        self.navigationController?.pushViewController(playbackVC, animated: true)
        captureSession?.stopRunning()
    }
}
extension RecordVideoViewController: AVCaptureFileOutputRecordingDelegate {
    // Output of recorded file is received here
    func fileOutput(_ output: AVCaptureFileOutput,
                    didFinishRecordingTo outputFileURL: URL,
                    from connections: [AVCaptureConnection], error: Error?) {
        print("Video saved at: \(outputFileURL)")
        self.goToVideoPlayback(url: outputFileURL)
    }
}
extension RecordVideoViewController: RecordVideoPresenterProtocol {
    func showTimerLabel() {
        timerLabel.isHidden = false
    }
    func hideTimerLabel() {
        timerLabel.isHidden = true
        timerLabel.text = ""
    }
    func updateTimerLabel(value: String) {
        if value == "START" {
            recordButton.isUserInteractionEnabled = true
            recordButton.setImage(UIImage(named: "stopRecordIcon"), for: .normal)
            timerLabel.font = UIFont.systemFont(ofSize: 115)
            startRecording()
        } else {
            timerLabel.font = UIFont.systemFont(ofSize: 260)
        }
        timerLabel.text = value
    }
}

