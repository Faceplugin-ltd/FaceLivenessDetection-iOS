import AVFoundation
import Foundation

/// Every preference this demo stores, in one place.
///
/// The libraries take their configuration as arguments, so this is the only part of the app that
/// knows about `UserDefaults`: it reads what the user chose and builds `ActiveLivenessOptions` for
/// the active-liveness screen.
///
/// Mirrors Android `data/AppSettings`. Defaults are the engine's own operating points — passive
/// liveness 0.5, head turn 25°, tilt 15°.
enum AppSettings {
    static let defaults = UserDefaults.standard

    static let keyCameraLens = "camera_lens"
    static let keyLivenessThreshold = "liveness_threshold"
    static let keyChecks = "active_checks"
    static let keyCount = "active_check_count"
    static let keyRandomize = "active_randomize"
    static let keyFramesWait = "active_frames_wait"
    static let keyYaw = "active_yaw"
    static let keyPitch = "active_pitch"
    static let keySmile = "active_smile"
    static let keyBlink = "active_blink"
    static let keyBlinksNumber = "active_blinks_number"
    static let keyPerspective = "active_perspective"
    static let keyAlignAngle = "active_align_angle"
    static let keyMinFace = "active_min_face"
    static let keyQuality = "active_quality"
    static let keyInvertTurn = "active_invert_turn"
    static let keyInvertTilt = "active_invert_tilt"

    static let defaultCameraLens = "front"
    static let defaultLivenessThreshold = trimFloat(ActiveLivenessOptions.defaultLivenessThreshold)
    static let defaultCount = String(ActiveLivenessOptions.defaultCount)
    static let defaultRandomize = ActiveLivenessOptions.defaultRandomize
    static let defaultFramesWait = String(ActiveLivenessOptions.defaultFramesWait)
    static let defaultYaw = trimFloat(ActiveLivenessOptions.defaultYaw)
    static let defaultPitch = trimFloat(ActiveLivenessOptions.defaultPitch)
    static let defaultSmile = trimFloat(ActiveLivenessOptions.defaultSmile)
    static let defaultBlink = trimFloat(ActiveLivenessOptions.defaultBlink)
    static let defaultBlinksNumber = String(ActiveLivenessOptions.defaultBlinksNumber)
    static let defaultPerspective = trimFloat(ActiveLivenessOptions.defaultPerspective)
    static let defaultAlignAngle = trimFloat(ActiveLivenessOptions.defaultAlignAngle)
    static let defaultMinFace = trimFloat(ActiveLivenessOptions.defaultMinFace)
    static let defaultQuality = trimFloat(ActiveLivenessOptions.defaultQuality)
    static let defaultInvert = false
    static let defaultCheckKeys = ActiveLivenessOptions.defaultPool.map { $0.key }

    private static let prefsSchemaKey = "prefs_schema"
    /// Bumped with the move to the facerecognitionsdk runtime.
    private static let prefsSchemaLX = 5

    /// Seeds the defaults this build expects. The thresholds belong to the engine, so a build that
    /// changes engines re-seeds them even where an older set is already stored.
    static func applyDefaults() {
        if defaults.integer(forKey: prefsSchemaKey) >= prefsSchemaLX { return }
        defaults.set(defaultCameraLens, forKey: keyCameraLens)
        defaults.set(defaultLivenessThreshold, forKey: keyLivenessThreshold)
        defaults.set(defaultCheckKeys, forKey: keyChecks)
        defaults.set(defaultCount, forKey: keyCount)
        defaults.set(defaultRandomize, forKey: keyRandomize)
        defaults.set(defaultFramesWait, forKey: keyFramesWait)
        defaults.set(defaultYaw, forKey: keyYaw)
        defaults.set(defaultPitch, forKey: keyPitch)
        defaults.set(defaultSmile, forKey: keySmile)
        defaults.set(defaultBlink, forKey: keyBlink)
        defaults.set(defaultBlinksNumber, forKey: keyBlinksNumber)
        defaults.set(defaultPerspective, forKey: keyPerspective)
        defaults.set(defaultAlignAngle, forKey: keyAlignAngle)
        defaults.set(defaultMinFace, forKey: keyMinFace)
        defaults.set(defaultQuality, forKey: keyQuality)
        defaults.set(defaultInvert, forKey: keyInvertTurn)
        defaults.set(defaultInvert, forKey: keyInvertTilt)
        defaults.set(prefsSchemaLX, forKey: prefsSchemaKey)
    }

    static func restoreDefaults() {
        defaults.set(prefsSchemaLX - 1, forKey: prefsSchemaKey)
        applyDefaults()
    }

    // MARK: - Camera

    static var useFrontCamera: Bool {
        get { (defaults.string(forKey: keyCameraLens) ?? defaultCameraLens) != "back" }
        set { defaults.set(newValue ? "front" : "back", forKey: keyCameraLens) }
    }

    static var cameraPosition: AVCaptureDevice.Position { useFrontCamera ? .front : .back }

    // MARK: - Passive liveness

    static var livenessThreshold: Float {
        floatPref(keyLivenessThreshold, defaultLivenessThreshold)
    }

    /// Whether a passive score counts as a live face at the user's threshold.
    static func livenessPassed(score: Float, label: String?) -> Bool {
        let lower = (label ?? "").lowercased()
        if lower.contains("spoof") || lower.contains("fake") { return false }
        return score >= livenessThreshold
    }

    // MARK: - Active liveness

    /// What the active-liveness screen should run, as the user has it configured.
    static func activeLiveness() -> ActiveLivenessOptions {
        let keys = Set(defaults.stringArray(forKey: keyChecks) ?? defaultCheckKeys)
        // Keep the canonical enum order so the pool is stable when randomize is off.
        let pool = ActiveCheck.allCases.filter { keys.contains($0.key) }
        var options = ActiveLivenessOptions()
        options.pool = pool.isEmpty ? ActiveLivenessOptions.defaultPool : pool
        options.count = intPref(keyCount, defaultCount)
        options.randomize = boolPref(keyRandomize, defaultRandomize)
        options.livenessThreshold = livenessThreshold
        options.framesWait = min(max(intPref(keyFramesWait, defaultFramesWait), 30), 600)
        options.yawThreshold = floatPref(keyYaw, defaultYaw)
        options.pitchThreshold = floatPref(keyPitch, defaultPitch)
        options.smileThreshold = floatPref(keySmile, defaultSmile)
        options.blinkThreshold = floatPref(keyBlink, defaultBlink)
        options.blinksNumber = min(max(intPref(keyBlinksNumber, defaultBlinksNumber), 1), 6)
        options.perspectiveThreshold = floatPref(keyPerspective, defaultPerspective)
        options.alignAngle = floatPref(keyAlignAngle, defaultAlignAngle)
        options.minFaceFraction = floatPref(keyMinFace, defaultMinFace)
        options.qualityThreshold = floatPref(keyQuality, defaultQuality)
        options.invertTurn = boolPref(keyInvertTurn, defaultInvert)
        options.invertTilt = boolPref(keyInvertTilt, defaultInvert)
        return options
    }

    // MARK: - Helpers

    static func floatPref(_ key: String, _ fallback: String) -> Float {
        Float((defaults.string(forKey: key) ?? fallback).trimmingCharacters(in: .whitespaces)) ?? Float(fallback)!
    }

    static func intPref(_ key: String, _ fallback: String) -> Int {
        Int((defaults.string(forKey: key) ?? fallback).trimmingCharacters(in: .whitespaces)) ?? Int(fallback)!
    }

    static func boolPref(_ key: String, _ fallback: Bool) -> Bool {
        defaults.object(forKey: key) == nil ? fallback : defaults.bool(forKey: key)
    }

    /// `25.0` reads badly in a settings field; `25` does.
    static func trimFloat(_ value: Float) -> String {
        value == Float(Int(value)) ? String(Int(value)) : String(value)
    }
}
