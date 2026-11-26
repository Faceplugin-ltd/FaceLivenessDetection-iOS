import AVFoundation
import UIKit
import FaceLivenessKit

/// Passive liveness: every camera frame is scored on its own, with no action asked of the user.
/// The engine reads the anti-spoofing score, quality and head pose from the single frame.
///
/// Mirrors Android `ui/CameraActivity`.
final class LivenessCameraViewController: BaseCameraViewController {
    private let overlay = FaceLivenessOverlayView()
    private let hint = PaddedLabel()
    private var hasFaces = false

    override func viewDidLoad() {
        super.viewDidLoad()
        overlay.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(overlay)

        let titlePill = PaddedLabel()
        titlePill.text = "Passive liveness"
        titlePill.textColor = .white
        titlePill.font = .systemFont(ofSize: 15, weight: .semibold)
        titlePill.backgroundColor = UIColor(white: 0, alpha: 0.4)
        titlePill.layer.cornerRadius = 18
        titlePill.clipsToBounds = true
        titlePill.translatesAutoresizingMaskIntoConstraints = false

        let close = roundButton(systemName: "xmark", action: #selector(didTapClose))
        let switchCam = roundButton(systemName: "arrow.triangle.2.circlepath.camera", action: #selector(didTapSwitch))

        hint.text = "Position your face in the frame"
        hint.textColor = .white
        hint.font = .systemFont(ofSize: 15, weight: .medium)
        hint.textAlignment = .center
        hint.backgroundColor = UIColor(white: 0, alpha: 0.4)
        hint.layer.cornerRadius = 18
        hint.clipsToBounds = true
        hint.translatesAutoresizingMaskIntoConstraints = false

        [titlePill, close, switchCam, hint].forEach { view.addSubview($0) }
        NSLayoutConstraint.activate([
            overlay.topAnchor.constraint(equalTo: cameraView.topAnchor),
            overlay.leadingAnchor.constraint(equalTo: cameraView.leadingAnchor),
            overlay.trailingAnchor.constraint(equalTo: cameraView.trailingAnchor),
            overlay.bottomAnchor.constraint(equalTo: cameraView.bottomAnchor),

            close.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 8),
            close.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            switchCam.centerYAnchor.constraint(equalTo: close.centerYAnchor),
            switchCam.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            titlePill.centerYAnchor.constraint(equalTo: close.centerYAnchor),
            titlePill.centerXAnchor.constraint(equalTo: view.centerXAnchor),

            hint.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            hint.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -28),
            hint.leadingAnchor.constraint(greaterThanOrEqualTo: view.leadingAnchor, constant: 24),
            hint.trailingAnchor.constraint(lessThanOrEqualTo: view.trailingAnchor, constant: -24),
        ])
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: animated)
    }

    override func viewWillDisappear(_ animated: Bool) {
        overlay.update(faces: [], frameSize: .zero, mirror: useFrontCamera)
        super.viewWillDisappear(animated)
    }

    override func onSampleBuffer(_ sampleBuffer: CMSampleBuffer, connection: AVCaptureConnection) {
        guard FaceEngine.shared.isReady,
              let image = CameraFrameUtils.liveEngineImage(from: sampleBuffer, frontCamera: useFrontCamera)
        else { return }
        let frameSize = image.size
        let mirror = useFrontCamera

        beginSDKWork()
        FaceEngine.shared.async { [weak self] in
            guard let self else { return }
            let faces = FaceEngine.shared.detect(image, options: .passive)
            DispatchQueue.main.async {
                self.endSDKWork()
                self.hasFaces = !faces.isEmpty
                self.overlay.update(faces: faces, frameSize: frameSize, mirror: mirror)
                self.hint.text = self.hasFaces ? "Analyzing liveness…" : "Position your face in the frame"
            }
        }
    }

    @objc private func didTapClose() {
        navigationController?.popViewController(animated: true)
    }

    @objc private func didTapSwitch() {
        switchCamera()
        hasFaces = false
        overlay.update(faces: [], frameSize: .zero, mirror: useFrontCamera)
        hint.text = "Position your face in the frame"
    }

    private func roundButton(systemName: String, action: Selector) -> UIButton {
        let button = UIButton(type: .system)
        button.setImage(UIImage(systemName: systemName), for: .normal)
        button.tintColor = .white
        button.backgroundColor = UIColor(white: 0, alpha: 0.4)
        button.layer.cornerRadius = 22
        button.translatesAutoresizingMaskIntoConstraints = false
        button.widthAnchor.constraint(equalToConstant: 44).isActive = true
        button.heightAnchor.constraint(equalToConstant: 44).isActive = true
        button.addTarget(self, action: action, for: .touchUpInside)
        return button
    }
}
