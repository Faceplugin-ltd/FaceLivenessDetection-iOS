import AVFoundation
import UIKit
import FaceLivenessKit

/// Android `CameraActivity` — VideoWorker tracking + PB liveness merge overlay.
final class LivenessCameraViewController: BaseCameraViewController {
    private let overlay = FaceLivenessOverlayView()
    private let hintLabel = UILabel()
    private var videoWorkerReady = false
    private var pbBusy = false
    private var lastFrame: UIImage?
    private var lastFrameSize: CGSize = .zero
    private var lastLivenessBoxes: [DetectedFace] = []
    private var hasFaces = false
    private let stateLock = NSLock()

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Liveness"
        overlay.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(overlay)

        hintLabel.text = "Center your face in the frame"
        hintLabel.textColor = .white
        hintLabel.font = .systemFont(ofSize: 15, weight: .medium)
        hintLabel.textAlignment = .center
        hintLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(hintLabel)

        NSLayoutConstraint.activate([
            overlay.topAnchor.constraint(equalTo: cameraView.topAnchor),
            overlay.leadingAnchor.constraint(equalTo: cameraView.leadingAnchor),
            overlay.trailingAnchor.constraint(equalTo: cameraView.trailingAnchor),
            overlay.bottomAnchor.constraint(equalTo: cameraView.bottomAnchor),
            hintLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            hintLabel.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -28),
        ])
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
    }

    override func viewWillDisappear(_ animated: Bool) {
        stopVideoWorker()
        overlay.update(faces: [], frameSize: .zero, mirror: useFrontCamera)
        super.viewWillDisappear(animated)
    }

    override func onSampleBuffer(_ sampleBuffer: CMSampleBuffer, connection: AVCaptureConnection) {
        guard FaceLivenessClient.shared.isEngineReady else { return }
        guard let prepared = CameraFrameUtils.liveEngineImage(
            from: sampleBuffer,
            frontCamera: useFrontCamera
        ) else { return }

        stateLock.lock()
        lastFrame = prepared
        lastFrameSize = prepared.size
        stateLock.unlock()

        if videoWorkerReady {
            FaceLivenessClient.shared.addFrame(prepared)
        }
        requestLiveness(prepared)
    }

    private func startVideoWorker() {
        let client = FaceLivenessClient.shared
        let threshold = AppSettings.livenessThreshold
        client.setVideoWorkerEventHandler { [weak self] json in
            self?.onVideoWorkerEvent(json)
        }
        client.async { [weak self] in
            let config = client.makeTrackingConfig(matchThreshold: threshold)
            let started = client.startVideoWorker(config: config)
            if started == 0 {
                _ = client.syncDatabase(matchThreshold: threshold)
            }
            DispatchQueue.main.async {
                guard let self, self.viewIfLoaded?.window != nil else {
                    client.stopVideoWorker()
                    return
                }
                // Android: camera still runs PB liveness even if VW fails.
                self.videoWorkerReady = started == 0
            }
        }
    }

    private func stopVideoWorker() {
        videoWorkerReady = false
        FaceLivenessClient.shared.stopVideoWorker()
        stateLock.lock()
        lastLivenessBoxes = []
        hasFaces = false
        stateLock.unlock()
    }

    private func onVideoWorkerEvent(_ json: String) {
        guard let event = FaceJSON.parseVideoWorkerEvent(json) else { return }
        switch event {
        case let .tracking(_, faces, _, frameSize):
            var boxes = FaceJSON.toDetectedFaces(faces, includeWeak: true)
            stateLock.lock()
            let live = lastLivenessBoxes
            let storedSize = lastFrameSize
            stateLock.unlock()
            boxes = LiveDetect.mergePbDetect(boxes, pb: live)
            assignDetectIds(&boxes)
            let size = storedSize.width > 0 ? storedSize : frameSize
            let found = !boxes.isEmpty
            DispatchQueue.main.async { [weak self] in
                guard let self else { return }
                self.hasFaces = found
                self.overlay.update(faces: boxes, frameSize: size, mirror: self.useFrontCamera)
                self.updateHint()
            }
        case .match:
            break
        }
    }

    private func requestLiveness(_ frame: UIImage) {
        stateLock.lock()
        if pbBusy {
            stateLock.unlock()
            return
        }
        pbBusy = true
        stateLock.unlock()

        let copy = frame
        let level = AppSettings.livenessLevel
        FaceLivenessClient.shared.async { [weak self] in
            guard let self else { return }
            var boxes = FaceLivenessClient.shared.faceDetection(from: copy, livenessLevel: level)
            self.assignDetectIds(&boxes)
            self.stateLock.lock()
            self.lastLivenessBoxes = boxes
            self.pbBusy = false
            let vwReady = self.videoWorkerReady
            self.stateLock.unlock()

            if !vwReady {
                let frameSize = copy.size
                let found = !boxes.isEmpty
                DispatchQueue.main.async {
                    self.hasFaces = found
                    self.overlay.update(faces: boxes, frameSize: frameSize, mirror: self.useFrontCamera)
                    self.updateHint()
                }
            }
        }
    }

    private func assignDetectIds(_ boxes: inout [DetectedFace]) {
        for i in boxes.indices where boxes[i].faceId < 0 {
            boxes[i] = DetectedFace(
                faceId: i + 1,
                region: boxes[i].region,
                attributes: boxes[i].attributes,
                yaw: boxes[i].yaw,
                pitch: boxes[i].pitch,
                roll: boxes[i].roll,
                landmarkCount: boxes[i].landmarkCount,
                landmarks: boxes[i].landmarks,
                luminance: boxes[i].luminance
            )
        }
    }

    private func updateHint() {
        hintLabel.text = hasFaces ? "Analyzing liveness…" : "Center your face in the frame"
    }
}
