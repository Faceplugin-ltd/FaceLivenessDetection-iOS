import Foundation

/// The engine's own operating points, exposed to the app and the active-liveness defaults.
///
/// (This file previously parsed the legacy engine's JSON; the current engine returns typed
/// `FaceRecognitionFace` values, so detect mapping lives in `DetectedFace+Metrics`.)
public enum FaceEngineConstants {
    /// `FaceRecognitionSDK.LIVENESS_THRESHOLD` — the passive anti-spoofing operating point.
    public static var livenessThreshold: Float { FaceRecognitionSDK.liveness_THRESHOLD() }

    /// `FaceRecognitionSDK.MATCH_THRESHOLD` — kept for completeness; liveness does not match.
    public static var matchThreshold: Float { FaceRecognitionSDK.match_THRESHOLD() }
}
