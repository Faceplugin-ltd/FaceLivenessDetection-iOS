import UIKit

/// Serial access to the native `FaceRecognitionSDK` ObjC API (`facerecognitionsdk.framework`,
/// the same engine `Face-Recognition-LivenessDetection-iOS` ships). The engine is not safe for
/// concurrent use — overlapping detect work from the camera and still-image work can freeze or
/// crash on device — so every call goes through this one serial queue.
///
/// Mirrors Android `FaceEngine.lock` (`face-liveness-kit`) and the recognition iOS
/// `FaceRecognitionSDKQueue`.
public enum FaceLivenessSDKQueue {
    private static let key = DispatchSpecificKey<Void>()
    private static let queue: DispatchQueue = {
        let q = DispatchQueue(label: "com.faceplugin.faceliveness.sdk", qos: .userInitiated)
        q.setSpecific(key: key, value: ())
        return q
    }()

    public static func async(_ work: @escaping () -> Void) {
        queue.async(execute: work)
    }

    public static func sync<T>(_ work: () -> T) -> T {
        if DispatchQueue.getSpecific(key: key) != nil {
            return work()
        }
        return queue.sync(execute: work)
    }
}
