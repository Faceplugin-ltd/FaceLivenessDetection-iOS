import AVFoundation
import Foundation
import UIKit

/// Thin app-facing wrapper around `FaceLivenessSDK` (Android `FaceLivenessClient`).
/// Activate once, then use face detection + optional VideoWorker tracking.
public final class FaceLivenessClient {
    public static let shared = FaceLivenessClient()

    private let readyLock = NSLock()
    private var engineReadyFlag = false

    public var isEngineReady: Bool {
        readyLock.lock()
        defer { readyLock.unlock() }
        return engineReadyFlag
    }

    private init() {}

    public func getLicenseStatus() -> LicenseStatus {
        LicenseStatus.current()
    }

    public func allowsLiveness() -> Bool {
        FaceLivenessSDK.allowsLiveness()
    }

    public func activate(license: String, completion: @escaping (Int) -> Void) {
        FaceLivenessQueue.async { [weak self] in
            guard let self else { return }
            if self.isEngineReady {
                DispatchQueue.main.async { completion(0) }
                return
            }
            _ = FaceLivenessSDK.getMachineCode()
            var ret = FaceLivenessSDK.setActivation(license)
            if ret == 0 {
                ret = FaceLivenessSDK.initSDK()
            }
            if ret == 0 {
                self.readyLock.lock()
                self.engineReadyFlag = true
                self.readyLock.unlock()
            }
            DispatchQueue.main.async { completion(Int(ret)) }
        }
    }

    public func faceDetection(from image: UIImage, livenessLevel: Int = 0) -> [DetectedFace] {
        let flags = LiveDetect.livenessOnlyFlags(level: livenessLevel)
        guard let json = FaceLivenessQueue.detect(image, crop: false, flags: flags) else { return [] }
        return FaceJSON.parseDetect(json, source: image)
    }

    public func makeTrackingConfig(matchThreshold: Float) -> FaceRecognitionVideoWorkerConfig {
        let config = FaceRecognitionVideoWorkerConfig(matchThreshold: matchThreshold)
        let al = FaceRecognitionActiveLivenessConfig.default()
        al.enabled = false
        config.activeLiveness = al
        return config
    }

    @discardableResult
    public func startVideoWorker(config: FaceRecognitionVideoWorkerConfig) -> Int {
        FaceLivenessQueue.startVideoWorker(config: config)
    }

    public func stopVideoWorker() {
        FaceLivenessQueue.stopVideoWorker()
    }

    public func setVideoWorkerEventHandler(_ handler: ((String) -> Void)?) {
        FaceLivenessQueue.setVideoWorkerEventHandler(handler)
    }

    /// Sync an empty enroll DB (tracking-only VideoWorker, Android `syncDatabase`).
    @discardableResult
    public func syncDatabase(matchThreshold: Float) -> Int {
        FaceLivenessQueue.syncVideoWorkerDatabase(matchThreshold: matchThreshold)
    }

    @discardableResult
    public func addFrame(_ image: UIImage) -> Int {
        FaceLivenessQueue.addVideoWorkerFrameNonBlocking(image)
    }

    public func async(_ work: @escaping () -> Void) {
        FaceLivenessQueue.async(work)
    }
}
