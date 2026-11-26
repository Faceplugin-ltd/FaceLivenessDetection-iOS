import Foundation

/// How one active-liveness attempt is run.
///
/// `pool` is what the sequence may be drawn from, `count` how many challenges one attempt asks for,
/// and `randomize` shuffles the order per attempt so a recorded session cannot be replayed. Every
/// attempt begins with the passive anti-spoofing gate, which the face has to clear at
/// `livenessThreshold` before any challenge is asked.
///
/// The thresholds are what `ActiveLivenessSession` judges each challenge against; the angles are
/// degrees, as the engine reports head pose.
///
/// Mirrors Android `face-liveness-active/ActiveLivenessOptions`.
struct ActiveLivenessOptions {
    var pool: [ActiveCheck] = ActiveLivenessOptions.defaultPool
    var count: Int = ActiveLivenessOptions.defaultCount
    var randomize: Bool = ActiveLivenessOptions.defaultRandomize
    var livenessThreshold: Float = ActiveLivenessOptions.defaultLivenessThreshold
    var passiveSamples: Int = ActiveLivenessOptions.defaultPassiveSamples
    var framesWait: Int = ActiveLivenessOptions.defaultFramesWait
    var yawThreshold: Float = ActiveLivenessOptions.defaultYaw
    var pitchThreshold: Float = ActiveLivenessOptions.defaultPitch
    var smileThreshold: Float = ActiveLivenessOptions.defaultSmile
    var blinkThreshold: Float = ActiveLivenessOptions.defaultBlink
    var blinksNumber: Int = ActiveLivenessOptions.defaultBlinksNumber
    var perspectiveThreshold: Float = ActiveLivenessOptions.defaultPerspective
    var alignAngle: Float = ActiveLivenessOptions.defaultAlignAngle
    /// Smallest the face may be, as a fraction of the frame's short side, to be scored.
    var minFaceFraction: Float = ActiveLivenessOptions.defaultMinFace
    /// Lowest image quality the engine's own score may report and still be judged.
    var qualityThreshold: Float = ActiveLivenessOptions.defaultQuality
    var invertTurn: Bool = false
    var invertTilt: Bool = false

    /// The challenge sequence for one attempt, in the order it will be asked.
    func buildPlan() -> [ActiveCheck] {
        let source = pool.isEmpty ? ActiveLivenessOptions.defaultPool : pool
        let ordered = randomize ? source.shuffled() : source
        return Array(ordered.prefix(max(1, min(count, ActiveLivenessOptions.maxChecks))))
    }

    /// +1 when the challenge wants a positive yaw, -1 when it wants a negative one.
    func yawSign(_ check: ActiveCheck) -> Float {
        let base: Float = check == .turnRight ? 1 : -1
        return invertTurn ? -base : base
    }

    /// +1 when the challenge wants a positive pitch, -1 when it wants a negative one.
    func pitchSign(_ check: ActiveCheck) -> Float {
        let base: Float = check == .turnUp ? 1 : -1
        return invertTilt ? -base : base
    }

    static let maxChecks = 6

    /// Every challenge but "move closer", which not every placement of the phone allows.
    static let defaultPool: [ActiveCheck] = [.blink, .smile, .turnLeft, .turnRight, .turnUp, .turnDown]

    static let defaultCount = 3
    static let defaultRandomize = true

    /// The engine's own passive-liveness operating point.
    static let defaultLivenessThreshold: Float = 0.5
    /// Frames the passive gate averages before it decides.
    static let defaultPassiveSamples = 3
    /// About 15 analyzed frames a second on a mid-range phone.
    static let defaultFramesWait = 150
    static let defaultYaw: Float = 25
    static let defaultPitch: Float = 15
    static let defaultSmile: Float = 0.5
    static let defaultBlink: Float = 0.3
    static let defaultBlinksNumber = 2
    static let defaultPerspective: Float = 0.15
    static let defaultAlignAngle: Float = 12
    /// A face smaller than this much of the frame is too far away to score reliably.
    static let defaultMinFace: Float = 0.3
    /// The engine's `ImageQuality` below which a frame is not worth judging.
    static let defaultQuality: Float = 0.3
}
