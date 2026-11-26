import Foundation

/// One active-liveness challenge.
///
/// The engine reports face attributes per frame — head pose, eye openness, smile, face size — and
/// `ActiveLivenessSession` decides from those when a challenge is satisfied. This enum is the
/// description of it: what to show, and the key the host app stores it under.
///
/// Mirrors Android `face-liveness-active/ActiveCheck`.
enum ActiveCheck: String, CaseIterable {
    case blink
    case smile
    case turnLeft
    case turnRight
    case turnUp
    case turnDown
    case perspective

    /// Stable key, matching the Android `ActiveCheck.key` values.
    var key: String {
        switch self {
        case .blink: return "blink"
        case .smile: return "smile"
        case .turnLeft: return "turn_left"
        case .turnRight: return "turn_right"
        case .turnUp: return "turn_up"
        case .turnDown: return "turn_down"
        case .perspective: return "perspective"
        }
    }

    var title: String {
        switch self {
        case .blink: return "Blink"
        case .smile: return "Smile"
        case .turnLeft: return "Turn left"
        case .turnRight: return "Turn right"
        case .turnUp: return "Look up"
        case .turnDown: return "Look down"
        case .perspective: return "Move closer"
        }
    }

    var hint: String {
        switch self {
        case .blink: return "Blink your eyes a couple of times"
        case .smile: return "Give the camera a clear smile"
        case .turnLeft: return "Turn your head to your left"
        case .turnRight: return "Turn your head to your right"
        case .turnUp: return "Tilt your head up, keep your eyes on the screen"
        case .turnDown: return "Tilt your head down slowly"
        case .perspective: return "Bring the phone a little closer to your face"
        }
    }

    /// SF Symbol shown on the challenge card and in the result list.
    var iconName: String {
        switch self {
        case .blink: return "eye.fill"
        case .smile: return "face.smiling.fill"
        case .turnLeft: return "arrow.left"
        case .turnRight: return "arrow.right"
        case .turnUp: return "arrow.up"
        case .turnDown: return "arrow.down"
        case .perspective: return "arrow.up.left.and.arrow.down.right"
        }
    }

    /// True for the challenges where turning the other way is a recoverable mistake.
    var isDirectional: Bool {
        self == .turnLeft || self == .turnRight || self == .turnUp || self == .turnDown
    }

    static func fromKey(_ key: String?) -> ActiveCheck? {
        guard let key, !key.isEmpty else { return nil }
        return allCases.first { $0.key.caseInsensitiveCompare(key) == .orderedSame }
    }
}
