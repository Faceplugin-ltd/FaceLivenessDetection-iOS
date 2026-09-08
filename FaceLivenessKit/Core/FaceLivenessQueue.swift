import UIKit
import AVFoundation

/// Serial access to native `FaceLivenessSDK` (Android `FaceLivenessQueue`).
public enum FaceLivenessQueue {
    private static let key = DispatchSpecificKey<Void>()
    private static let queue: DispatchQueue = {
        let q = DispatchQueue(label: "com.faceplugin.faceliveness.sdk", qos: .userInitiated)
        q.setSpecific(key: key, value: ())
        return q
    }()
    private static let frameLock = NSLock()
    private static var frameBusy = false

    public static func async(_ work: @escaping () -> Void) {
        queue.async(execute: work)
    }

    public static func sync<T>(_ work: () -> T) -> T {
        if DispatchQueue.getSpecific(key: key) != nil {
            return work()
        }
        return queue.sync(execute: work)
    }

    public static func detect(_ image: UIImage, crop: Bool, flags: FaceRecognitionDetectFlags) -> String? {
        sync { FaceLivenessSDK.detect(image, crop: crop, flags: flags) }
    }

    public static func startVideoWorker(config: FaceRecognitionVideoWorkerConfig) -> Int {
        sync {
            FaceLivenessSDK.stopVideoWorker()
            return Int(FaceLivenessSDK.startVideoWorker(with: config))
        }
    }

    public static func stopVideoWorker() {
        FaceLivenessSDK.setVideoWorkerEventHandler(nil)
        sync {
            FaceLivenessSDK.stopVideoWorker()
            frameLock.lock()
            frameBusy = false
            frameLock.unlock()
        }
    }

    public static func setVideoWorkerEventHandler(_ handler: ((String) -> Void)?) {
        if let handler {
            FaceLivenessSDK.setVideoWorkerEventHandler { json in
                handler(json)
            }
        } else {
            FaceLivenessSDK.setVideoWorkerEventHandler(nil)
        }
    }

    @discardableResult
    public static func syncVideoWorkerDatabase(matchThreshold: Float) -> Int {
        sync {
            Int(FaceLivenessSDK.syncVideoWorkerDatabase(withFeatures: [], matchThreshold: matchThreshold))
        }
    }

    @discardableResult
    public static func addVideoWorkerFrameNonBlocking(_ image: UIImage) -> Int {
        frameLock.lock()
        if frameBusy {
            frameLock.unlock()
            return 0
        }
        frameBusy = true
        frameLock.unlock()
        async {
            defer {
                frameLock.lock()
                frameBusy = false
                frameLock.unlock()
            }
            _ = FaceLivenessSDK.addVideoWorkerFrame(image)
        }
        return 0
    }
}
