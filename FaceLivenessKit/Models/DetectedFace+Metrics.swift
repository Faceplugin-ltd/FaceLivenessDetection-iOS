import CoreGraphics
import Foundation

public extension DetectedFace {
    var width: CGFloat { bounds.width }
    var height: CGFloat { bounds.height }
    var area: CGFloat { bounds.width * bounds.height }

    /// The engine reports `NaN` for an attribute it did not measure.
    var hasLiveness: Bool { !liveness.isNaN }
    var hasPose: Bool { !yaw.isNaN && !pitch.isNaN }

    /// Label the engine's own operating point gives this score.
    var livenessLabel: String {
        if liveness.isNaN { return "" }
        return liveness > FaceRecognitionSDK.liveness_THRESHOLD() ? "Live" : "Fake"
    }

    /// Build a `DetectedFace` from the engine's `FaceRecognitionFace`.
    static func from(_ face: FaceRecognitionFace) -> DetectedFace {
        DetectedFace(
            bounds: face.bounds,
            score: face.score,
            liveness: face.liveness,
            quality: face.quality,
            yaw: face.yaw,
            pitch: face.pitch,
            roll: face.roll,
            eyesOpen: face.eyesOpen,
            smile: face.smile,
            mouthOpen: face.mouthOpen
        )
    }
}
