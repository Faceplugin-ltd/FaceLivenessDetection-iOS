import FaceLivenessKit
import Foundation
import UIKit

/// The Objective-C face of this project, for hosts that cannot speak Swift.
///
/// Swift-only API — structs, enums with associated values, generics — is invisible to Objective-C,
/// and therefore to .NET for iOS, Xamarin, Unity and anything else that binds a framework through
/// its generated header. This file is the one place that translates: every type here is an
/// `NSObject` or an `Int`-backed `@objc` enum, named with an `FPL` prefix so it cannot collide
/// with a host's own symbols.
///
/// It adds **no behaviour**. The engine is `FaceEngine` from `FaceLivenessKit`, the screens are
/// `ActiveLivenessViewController` and `LivenessCameraViewController` — the same code the
/// FaceLivenessSDK app runs — so a host that drives this facade sees exactly what the native demo
/// shows, down to the challenge order and the result card.
///
/// Wire values (`FPLActiveOptions.pool`, `FPLActiveResult.challenges` and `.outcomes`) are the
/// strings Android uses, so a cross-platform host can treat both platforms the same.

// MARK: - Engine

/// What `FPLEngine.state` reports. Matches Android `FaceEngine.State` and the engine's own codes.
@objc(FPLEngineState)
public enum FPLEngineState: Int {
    case loading = 0
    case ready = 1
    case notActivated = 2
    case licenseInvalid = 3
    case licenseExpired = 4
    case failed = 5
}

/// What the activated key unlocks. A mirror of the kit's `LicenseStatus` struct.
@objc(FPLLicenseStatus)
public final class FPLLicenseStatus: NSObject {
    @objc public let licensed: Bool
    @objc public let level: Int
    @objc public let levelName: String
    @objc public let recognition: Bool
    @objc public let liveness: Bool
    @objc public let label: String

    init(_ status: LicenseStatus) {
        licensed = status.licensed
        level = status.level
        levelName = status.levelName
        recognition = status.recognition
        liveness = status.liveness
        label = status.label
    }
}

/// Activation and licence state.
///
/// Call `start` once per process. Everything here is a class method, because the engine itself is
/// process-wide.
@objc(FPLEngine)
public final class FPLEngine: NSObject {

    private override init() { super.init() }

    /// Activate with `license` and load the models. `completion` runs on the main queue with the
    /// engine's own return code — 0 is success; see `FPLEngineState` for what the others mean.
    @objc(startWithLicense:completion:)
    public static func start(license: String, completion: ((Int) -> Void)?) {
        FaceEngine.shared.start(license: license) { code in completion?(code) }
    }

    @objc public static var state: FPLEngineState {
        switch FaceEngine.shared.state {
        case .loading: return .loading
        case .ready: return .ready
        case .notActivated: return .notActivated
        case .licenseInvalid: return .licenseInvalid
        case .licenseExpired: return .licenseExpired
        case .failed: return .failed
        }
    }

    @objc public static var isReady: Bool { FaceEngine.shared.isReady }

    /// Reads the licence on the engine's own worker; `completion` runs on the main queue.
    @objc(licenseStatusWithCompletion:)
    public static func licenseStatus(completion: @escaping (FPLLicenseStatus) -> Void) {
        FaceEngine.shared.async {
            let status = FPLLicenseStatus(FaceEngine.shared.licenseStatus())
            DispatchQueue.main.async { completion(status) }
        }
    }

    /// The engine's own message for the last activation failure, or an empty string.
    @objc public static var lastLicenseError: String { FaceEngine.shared.lastLicenseError() }

    /// This device's machine code, for issuing a node-locked key. `completion` runs on the main
    /// queue, because reading it takes the engine lock.
    @objc(machineCodeWithCompletion:)
    public static func machineCode(completion: @escaping (String) -> Void) {
        FaceEngine.shared.async {
            let code = FaceEngine.shared.machineCode()
            DispatchQueue.main.async { completion(code) }
        }
    }

    /// The short message the native home screen shows in its status pill.
    @objc public static var stateMessage: String { FaceEngine.shared.stateMessage() }
}

// MARK: - Options

/// How one active-liveness attempt is run.
///
/// Every property starts at the native default, so a host only sets what it means to change. The
/// defaults are the engine's own operating points and are identical to Android's.
@objc(FPLActiveOptions)
public final class FPLActiveOptions: NSObject {

    /// Challenge keys the sequence may be drawn from: `blink`, `smile`, `turn_left`,
    /// `turn_right`, `turn_up`, `turn_down`, `perspective`. An empty or unrecognised pool falls
    /// back to the native default.
    @objc public var pool: [String] = ActiveLivenessOptions.defaultPool.map { $0.key }

    @objc public var count: Int = ActiveLivenessOptions.defaultCount
    @objc public var randomize: Bool = ActiveLivenessOptions.defaultRandomize
    @objc public var livenessThreshold: Float = ActiveLivenessOptions.defaultLivenessThreshold
    @objc public var passiveSamples: Int = ActiveLivenessOptions.defaultPassiveSamples
    @objc public var framesWait: Int = ActiveLivenessOptions.defaultFramesWait
    @objc public var yawThreshold: Float = ActiveLivenessOptions.defaultYaw
    @objc public var pitchThreshold: Float = ActiveLivenessOptions.defaultPitch
    @objc public var smileThreshold: Float = ActiveLivenessOptions.defaultSmile
    @objc public var blinkThreshold: Float = ActiveLivenessOptions.defaultBlink
    @objc public var blinksNumber: Int = ActiveLivenessOptions.defaultBlinksNumber
    @objc public var perspectiveThreshold: Float = ActiveLivenessOptions.defaultPerspective
    @objc public var alignAngle: Float = ActiveLivenessOptions.defaultAlignAngle

    /// Smallest the face may be, as a fraction of the frame's short side, to be scored.
    @objc public var minFaceFraction: Float = ActiveLivenessOptions.defaultMinFace

    /// Lowest image quality the engine's own score may report and still be judged.
    @objc public var qualityThreshold: Float = ActiveLivenessOptions.defaultQuality

    @objc public var invertTurn: Bool = false
    @objc public var invertTilt: Bool = false

    /// Which lens the screen opens on. The passive screen reads this too.
    @objc public var useFrontCamera: Bool = true

    @objc public override init() { super.init() }

    /// The native options this describes.
    func toNative() -> ActiveLivenessOptions {
        var options = ActiveLivenessOptions()
        // Keep the canonical enum order so the pool is stable when randomize is off.
        let wanted = Set(pool)
        let checks = ActiveCheck.allCases.filter { wanted.contains($0.key) }
        options.pool = checks.isEmpty ? ActiveLivenessOptions.defaultPool : checks
        options.count = count
        options.randomize = randomize
        options.livenessThreshold = livenessThreshold
        options.passiveSamples = passiveSamples
        options.framesWait = framesWait
        options.yawThreshold = yawThreshold
        options.pitchThreshold = pitchThreshold
        options.smileThreshold = smileThreshold
        options.blinkThreshold = blinkThreshold
        options.blinksNumber = blinksNumber
        options.perspectiveThreshold = perspectiveThreshold
        options.alignAngle = alignAngle
        options.minFaceFraction = minFaceFraction
        options.qualityThreshold = qualityThreshold
        options.invertTurn = invertTurn
        options.invertTilt = invertTilt
        return options
    }
}

// MARK: - Result

/// What one attempt came to.
///
/// `passed` is the only thing most callers need: it is true when the passive anti-spoofing gate
/// cleared *and* every challenge was completed.
@objc(FPLActiveResult)
public final class FPLActiveResult: NSObject {

    @objc public let passed: Bool

    /// Why the attempt did not pass: `NONE`, `SPOOF`, `CHECK`, `TIMEOUT` or `CANCELLED`.
    @objc public let failure: String

    /// Averaged passive anti-spoofing score, or -1 when the engine never returned one.
    @objc public let passiveScore: Float

    @objc public let passivePassed: Bool

    /// The challenge keys asked, in the order they were asked.
    @objc public let challenges: [String]

    /// One outcome per entry of `challenges`: `PENDING`, `ACTIVE`, `PASSED` or `FAILED`.
    @objc public let outcomes: [String]

    @objc public let durationMs: Int64

    /// The challenge key that ended the attempt, or nil when none did.
    @objc public var failedCheck: String? {
        guard let index = outcomes.firstIndex(of: "FAILED"), index < challenges.count else {
            return nil
        }
        return challenges[index]
    }

    init(_ result: ActiveLivenessResult) {
        passed = result.passed
        failure = FPLActiveResult.wire(result.failure)
        passiveScore = result.passiveScore
        passivePassed = result.passivePassed
        challenges = result.challenges.map { $0.key }
        outcomes = result.outcomes.map(FPLActiveResult.wire)
        durationMs = result.durationMs
    }

    /// The names Android's enums use, so both platforms report an attempt identically.
    private static func wire(_ failure: ActiveLivenessSession.Failure) -> String {
        switch failure {
        case .none: return "NONE"
        case .spoof: return "SPOOF"
        case .check: return "CHECK"
        case .timeout: return "TIMEOUT"
        case .cancelled: return "CANCELLED"
        }
    }

    private static func wire(_ step: ActiveLivenessSession.StepState) -> String {
        switch step {
        case .pending: return "PENDING"
        case .active: return "ACTIVE"
        case .passed: return "PASSED"
        case .failed: return "FAILED"
        }
    }
}

// MARK: - Screens

/// Opens the native liveness screens.
///
/// Both present modally over whatever is on screen, so a host does not have to hand over a view
/// controller — useful for frameworks like .NET MAUI, where the host's own controller is not
/// readily at hand. Pass one explicitly with the `from:` variants when you need to.
@objc(FPLLiveness)
public final class FPLLiveness: NSObject {

    private override init() { super.init() }

    /// Opens the guided active-liveness screen and waits for the attempt to finish.
    ///
    /// One attempt runs in three stages: the face is found and aligned, the passive anti-spoofing
    /// gate scores it, and only then are the challenges asked — so a printed photo or a replayed
    /// video is turned away before it is ever invited to blink.
    ///
    /// `completion` runs on the main queue with nil when the user closed the screen before an
    /// attempt produced a result.
    @objc(presentActiveLivenessWithOptions:completion:)
    public static func presentActiveLiveness(
        options: FPLActiveOptions,
        completion: @escaping (FPLActiveResult?) -> Void
    ) {
        DispatchQueue.main.async {
            guard let host = topViewController() else {
                completion(nil)
                return
            }
            present(from: host, options: options, completion: completion)
        }
    }

    @objc(presentActiveLivenessFrom:options:completion:)
    public static func present(
        from host: UIViewController,
        options: FPLActiveOptions,
        completion: @escaping (FPLActiveResult?) -> Void
    ) {
        // The screens read the lens and the threshold from AppSettings, which in this framework is
        // a plain holder the host writes before presenting. See BridgeSupport.swift.
        AppSettings.useFrontCamera = options.useFrontCamera
        AppSettings.livenessThreshold = options.livenessThreshold

        ActiveLivenessViewController.present(from: host, options: options.toNative()) { outcome in
            let mapped = outcome.map(FPLActiveResult.init)
            DispatchQueue.main.async { completion(mapped) }
        }
    }

    /// Opens the passive-liveness screen: every camera frame is scored on its own, with no action
    /// asked of the user, and the HUD shows liveness, quality and head pose. It has no result; the
    /// user closes it.
    @objc(presentPassiveLivenessWithFrontCamera:livenessThreshold:)
    public static func presentPassiveLiveness(useFrontCamera: Bool, livenessThreshold: Float) {
        DispatchQueue.main.async {
            guard let host = topViewController() else { return }
            presentPassiveLiveness(
                from: host,
                useFrontCamera: useFrontCamera,
                livenessThreshold: livenessThreshold
            )
        }
    }

    @objc(presentPassiveLivenessFrom:frontCamera:livenessThreshold:)
    public static func presentPassiveLiveness(
        from host: UIViewController,
        useFrontCamera: Bool,
        livenessThreshold: Float
    ) {
        AppSettings.useFrontCamera = useFrontCamera
        AppSettings.livenessThreshold = livenessThreshold

        let controller = LivenessCameraViewController()
        let nav = UINavigationController(rootViewController: controller)
        nav.modalPresentationStyle = .fullScreen
        nav.setNavigationBarHidden(true, animated: false)
        host.present(nav, animated: true)
    }

    /// Whatever is actually on screen: the deepest presented controller under the key window.
    private static func topViewController() -> UIViewController? {
        let scenes = UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }
        let window = scenes
            .first { $0.activationState == .foregroundActive }?
            .windows.first { $0.isKeyWindow }
            ?? scenes.flatMap(\.windows).first { $0.isKeyWindow }
        var controller = window?.rootViewController
        while let presented = controller?.presentedViewController {
            controller = presented
        }
        if let navigation = controller as? UINavigationController {
            controller = navigation.visibleViewController ?? navigation
        }
        if let tabs = controller as? UITabBarController {
            controller = tabs.selectedViewController ?? tabs
        }
        return controller
    }
}
