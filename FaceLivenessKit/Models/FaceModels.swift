import CoreGraphics
import UIKit

/// One detected face, in the shape the liveness screens use.
///
/// Mirrors Android `face-liveness-kit/DetectedFace`. The engine reports an attribute it was not
/// asked for, or could not measure, as `NaN`; this keeps that, so callers can tell "not measured"
/// from zero (`hasLiveness`, `hasPose`).
public struct DetectedFace {
    public let bounds: CGRect
    public let score: Float
    public let liveness: Float
    public let quality: Float
    public let yaw: Float
    public let pitch: Float
    public let roll: Float
    public let eyesOpen: Float
    public let smile: Float
    public let mouthOpen: Float

    public init(
        bounds: CGRect,
        score: Float,
        liveness: Float,
        quality: Float,
        yaw: Float,
        pitch: Float,
        roll: Float,
        eyesOpen: Float,
        smile: Float,
        mouthOpen: Float
    ) {
        self.bounds = bounds
        self.score = score
        self.liveness = liveness
        self.quality = quality
        self.yaw = yaw
        self.pitch = pitch
        self.roll = roll
        self.eyesOpen = eyesOpen
        self.smile = smile
        self.mouthOpen = mouthOpen
    }
}

/// One camera frame prepared for the engine. `CameraFrameUtils` produces it.
public struct CameraFrame {
    public let image: UIImage
    public let uprightSize: CGSize
    public let bufferSize: CGSize

    public init(image: UIImage, uprightSize: CGSize, bufferSize: CGSize) {
        self.image = image
        self.uprightSize = uprightSize
        self.bufferSize = bufferSize
    }
}
