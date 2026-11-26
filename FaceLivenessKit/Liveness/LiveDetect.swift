import Foundation

/// What the app asks the engine for on a frame.
///
/// Mirrors Android `face-liveness-kit/DetectOptions`. Pose, eyes and expression are what the
/// active-liveness challenges are judged on; `liveness` is the passive anti-spoofing score.
public struct DetectOptions {
    public var liveness: Bool
    public var quality: Bool
    public var pose: Bool
    public var eyes: Bool
    public var expression: Bool
    public var points: Bool
    public var ageGender: Bool

    public init(
        liveness: Bool = false,
        quality: Bool = false,
        pose: Bool = false,
        eyes: Bool = false,
        expression: Bool = false,
        points: Bool = false,
        ageGender: Bool = false
    ) {
        self.liveness = liveness
        self.quality = quality
        self.pose = pose
        self.eyes = eyes
        self.expression = expression
        self.points = points
        self.ageGender = ageGender
    }

    func toSdk() -> FaceRecognitionDetectOptions {
        let options = FaceRecognitionDetectOptions()
        options.liveness = liveness
        options.quality = quality
        options.pose = pose
        options.eyes = eyes
        options.expression = expression
        options.points = points
        options.ageGender = ageGender
        return options
    }

    /// Passive liveness screen: score, quality and pose for the HUD.
    public static let passive = DetectOptions(liveness: true, quality: true, pose: true)

    /// Active liveness: everything the challenges read, plus the passive score.
    public static let active = DetectOptions(
        liveness: true,
        quality: true,
        pose: true,
        eyes: true,
        expression: true
    )

    /// Active liveness while a challenge is running — no passive score, so it stays fast.
    public static let activeFast = DetectOptions(pose: true, eyes: true, expression: true)
}
