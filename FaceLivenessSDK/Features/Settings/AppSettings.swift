import AVFoundation
import Foundation

/// Mirrors Android `SettingsActivity` preference keys (liveness-only).
enum AppSettings {
    static let defaults = UserDefaults.standard

    static let defaultCameraLens = "front"
    static let defaultLivenessThreshold = "0.5"
    static let defaultLivenessLevel = "0"

    private static let prefsSchemaKey = "prefs_schema"
    private static let prefsSchemaLiveness = 2

    static func applyEngineDefaults() {
        if defaults.integer(forKey: prefsSchemaKey) >= prefsSchemaLiveness { return }
        defaults.set(defaultCameraLens, forKey: "camera_lens")
        defaults.set(defaultLivenessThreshold, forKey: "liveness_threshold")
        defaults.set(defaultLivenessLevel, forKey: "liveness_level")
        defaults.set(prefsSchemaLiveness, forKey: prefsSchemaKey)
    }

    static var useFrontCamera: Bool {
        get { (defaults.string(forKey: "camera_lens") ?? defaultCameraLens) != "back" }
        set { defaults.set(newValue ? "front" : "back", forKey: "camera_lens") }
    }

    static var cameraPosition: AVCaptureDevice.Position {
        useFrontCamera ? .front : .back
    }

    static var livenessThreshold: Float {
        Float(defaults.string(forKey: "liveness_threshold") ?? defaultLivenessThreshold) ?? 0.5
    }

    static var livenessLevel: Int {
        (defaults.string(forKey: "liveness_level") ?? defaultLivenessLevel) == "0" ? 0 : 1
    }

    static func livenessPassed(score: Float, label: String?) -> Bool {
        let lower = (label ?? "").lowercased()
        if lower.contains("spoof") || lower.contains("fake") { return false }
        return score >= livenessThreshold
    }

    static func restoreDefaults() {
        defaults.set(defaultCameraLens, forKey: "camera_lens")
        defaults.set(defaultLivenessThreshold, forKey: "liveness_threshold")
        defaults.set(defaultLivenessLevel, forKey: "liveness_level")
        defaults.set(prefsSchemaLiveness, forKey: prefsSchemaKey)
    }
}
