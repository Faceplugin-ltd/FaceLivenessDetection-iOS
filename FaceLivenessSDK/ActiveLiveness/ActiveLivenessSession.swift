import CoreGraphics
import QuartzCore
import FaceLivenessKit

/// Runs one active-liveness attempt.
///
/// The engine scores a frame; it does not sequence anything. So this class owns the order of the
/// attempt:
///
/// 1. **Align** — wait for exactly one face inside the oval guide (enter the circle, sit in its
///    middle, fit the circle) and looking straight ahead. The passive gate does not start until
///    that hold is satisfied.
/// 2. **Passive** — score that face for spoofing and average `options.passiveSamples` frames. Below
///    `options.livenessThreshold` the attempt ends here and no challenge is asked: a printed photo
///    or a replayed video should never get to perform actions.
/// 3. **Challenges** — ask for each challenge in `plan` in turn, deciding from the per-frame
///    attributes (`DetectedFace`) when one is satisfied, timed out or failed.
///
/// **Losing the face starts the attempt over.** Gone for longer than about a second and everything
/// resets to stage one — the gate included — so no attempt can be half-completed by one face and
/// finished by another.
///
/// Mirrors Android `face-liveness-active/ActiveLivenessSession`. Not thread-safe — call from one
/// thread.
final class ActiveLivenessSession {

    enum Phase { case idle, align, passive, running, passed, failed }
    enum StepState { case pending, active, passed, failed }
    enum Failure { case none, spoof, check, timeout, cancelled }

    /// What is wrong with the frame, if anything. Everything but `wrongWay` is about the face being
    /// unusable rather than the challenge being unmet.
    enum Notice {
        case none
        case noFace
        case manyFaces
        case tooFar
        case tooClose
        case offCenter
        case lookStraight
        case lowQuality
        case notScorable
        case wrongWay
    }

    struct State {
        let phase: Phase
        let passive: StepState
        let passiveScore: Float
        let steps: [StepState]
        let activeIndex: Int
        let current: ActiveCheck?
        let progress: Float
        let passedCount: Int
        let total: Int
        let failedCheck: ActiveCheck?
        let failure: Failure
        let notice: Notice
        let restarts: Int
        let elapsedMs: Int64
    }

    let plan: [ActiveCheck]
    private let options: ActiveLivenessOptions

    private var steps: [StepState]
    private var phase: Phase = .idle
    private var passive: StepState = .pending
    private var activeIndex = -1
    private var failedCheck: ActiveCheck?
    private var failure: Failure = .none
    private var notice: Notice = .none
    private var startedAt: Int64 = 0
    private var finishedAt: Int64 = 0

    // Face loss
    private var lastFaceAt: Int64 = 0
    private var restarts = 0

    // Passive gate
    private var passiveSum: Float = 0
    private var passiveCount = 0
    private var passiveScore: Float = -1
    private var framesOnPassive = 0

    // Align stage, measured from the last (re)start rather than from the attempt
    private var alignStartedAt: Int64 = 0
    /// Good oval-framing frames held before the passive gate is allowed to start.
    private var alignHoldFrames = 0

    // Per-challenge progress
    private var checkProgress: Float = 0
    private var framesOnCheck = 0
    private var holdFrames = 0

    // BLINK: count closed -> open transitions
    private var blinks = 0
    private var eyesWereClosed = false

    // PERSPECTIVE: face width when the challenge started
    private var baselineWidth: Float = 0

    init(plan: [ActiveCheck], options: ActiveLivenessOptions) {
        self.plan = plan
        self.options = options
        self.steps = Array(repeating: .pending, count: plan.count)
    }

    var isFinished: Bool { phase == .passed || phase == .failed }

    /// Whether the next frame still needs the passive anti-spoofing score. Scoring liveness costs
    /// more than reading pose and expression, so the challenge stage leaves it off.
    var needsLiveness: Bool { phase == .align || phase == .passive }

    func start() {
        phase = plan.isEmpty ? .failed : .align
        failedCheck = nil
        failure = plan.isEmpty ? .check : .none
        startedAt = Self.nowMs()
        finishedAt = 0
        restarts = 0
        lastFaceAt = startedAt
        resetProgress()
    }

    func cancel() {
        if isFinished { return }
        failure = .cancelled
        finish(.failed)
    }

    /// Overall guard, on top of the per-stage budgets.
    func timeOut() {
        if isFinished { return }
        failure = .timeout
        finish(.failed)
    }

    /// Feeds one analyzed frame.
    ///
    /// - Parameter guideRect: The on-screen oval cut-out mapped into image coordinates. When
    ///   non-empty, align / passive framing is judged against that oval (enter, centre, fit)
    ///   rather than against the full camera frame.
    func onFrame(
        faces: [DetectedFace],
        frameWidth: Int,
        frameHeight: Int,
        guideRect: CGRect = .zero
    ) {
        if isFinished || phase == .idle { return }
        let now = Self.nowMs()

        // Aligning is not counted per frame, so it gets a wall-clock budget of its own.
        if phase == .align && now - alignStartedAt > Self.alignBudgetMs {
            failure = .timeout
            finish(.failed)
            return
        }

        if faces.isEmpty {
            notice = .noFace
            holdFrames = 0
            alignHoldFrames = 0
            if phase != .align && now - lastFaceAt > Self.faceLostGraceMs {
                restart()
            }
            return
        }
        lastFaceAt = now

        if faces.count > 1 {
            notice = .manyFaces
            holdFrames = 0
            alignHoldFrames = 0
            return
        }
        let face = faces[0]

        switch phase {
        case .align: onAlignFrame(face, frameWidth, frameHeight, guideRect)
        case .passive: onPassiveFrame(face, frameWidth, frameHeight, guideRect)
        case .running: onChallengeFrame(face)
        default: break
        }
    }

    /// Everything the attempt has achieved so far, back to stage one, with the same plan.
    private func restart() {
        restarts += 1
        phase = .align
        resetProgress()
    }

    private func onAlignFrame(
        _ face: DetectedFace,
        _ frameWidth: Int,
        _ frameHeight: Int,
        _ guideRect: CGRect
    ) {
        let framing = framingNotice(face, frameWidth, frameHeight, guideRect)
        notice = framing
        if framing != .none {
            alignHoldFrames = 0
            return
        }
        // Face must stay inside the oval for a few frames before the session advances —
        // one lucky frame must not start the passive gate.
        alignHoldFrames += 1
        if alignHoldFrames < Self.alignHoldFrames { return }

        phase = .passive
        passive = .active
        framesOnPassive = 0
        alignHoldFrames = 0
        onPassiveFrame(face, frameWidth, frameHeight, guideRect)
    }

    /// The anti-spoofing gate: average a few well-framed frames, then decide once.
    private func onPassiveFrame(
        _ face: DetectedFace,
        _ frameWidth: Int,
        _ frameHeight: Int,
        _ guideRect: CGRect
    ) {
        framesOnPassive += 1

        let framing = framingNotice(face, frameWidth, frameHeight, guideRect)
        if framing != .none {
            notice = framing
            if framesOnPassive >= options.framesWait {
                failure = .timeout
                finish(.failed)
            }
            return
        }

        if !face.hasLiveness {
            notice = .notScorable
            if framesOnPassive >= options.framesWait {
                passive = .failed
                failure = .spoof
                finish(.failed)
            }
            return
        }

        notice = .none
        passiveSum += face.liveness
        passiveCount += 1
        passiveScore = passiveSum / Float(passiveCount)

        if passiveCount >= max(options.passiveSamples, 1) {
            if passiveScore >= options.livenessThreshold {
                passive = .passed
                phase = .running
                advanceTo(0, face)
            } else {
                passive = .failed
                failure = .spoof
                finish(.failed)
            }
        }
    }

    private func onChallengeFrame(_ face: DetectedFace) {
        guard activeIndex >= 0, activeIndex < plan.count else { return }
        let check = plan[activeIndex]
        framesOnCheck += 1
        notice = .none

        let result = evaluate(check, face)
        checkProgress = min(max(result.progress, 0), 1)
        if result.wrongWay { notice = .wrongWay }

        if result.satisfied {
            holdFrames += 1
            if holdFrames >= Self.holdFrames {
                steps[activeIndex] = .passed
                let next = activeIndex + 1
                if next >= plan.count {
                    finish(.passed)
                } else {
                    advanceTo(next, face)
                }
                return
            }
        } else {
            holdFrames = 0
        }

        if framesOnCheck >= options.framesWait {
            failedCheck = check
            steps[activeIndex] = .failed
            failure = .check
            finish(.failed)
        }
    }

    func snapshot() -> State {
        let passed = steps.filter { $0 == .passed }.count
        // The gate is the first segment of the ring, the challenges share the rest.
        let segments = Float(plan.count + 1)
        let ring: Float
        switch phase {
        case .passed:
            ring = 1
        case .idle, .align:
            ring = 0
        case .passive:
            let wanted = Float(max(options.passiveSamples, 1))
            ring = min(max(Float(passiveCount) / wanted / segments, 0), 1 / segments)
        default:
            let base = (1 + Float(passed)) / segments
            ring = max(min(base + checkProgress / segments, 1), base)
        }
        let end = finishedAt > 0 ? finishedAt : Self.nowMs()
        return State(
            phase: phase,
            passive: passive,
            passiveScore: passiveScore,
            steps: steps,
            activeIndex: activeIndex,
            current: (activeIndex >= 0 && activeIndex < plan.count) ? plan[activeIndex] : nil,
            progress: ring,
            passedCount: passed,
            total: plan.count,
            failedCheck: failedCheck,
            failure: failure,
            notice: notice,
            restarts: restarts,
            elapsedMs: startedAt > 0 ? end - startedAt : 0
        )
    }

    // MARK: - Framing

    /// Whether this face can be judged at all, and if not, what the user should change. The order is
    /// the order a user would fix things in: get into the circle, get the distance right, face the
    /// camera, then the light.
    ///
    /// When `guideRect` is the oval cut-out in image space, the face must enter that circle, sit in
    /// its middle and fit inside it before the session leaves align / stays on the passive gate.
    private func framingNotice(
        _ face: DetectedFace,
        _ frameWidth: Int,
        _ frameHeight: Int,
        _ guideRect: CGRect
    ) -> Notice {
        if frameWidth > 0 && frameHeight > 0 {
            let bounds = face.bounds
            let faceSide = Float(max(face.width, face.height))

            if guideRect.width > 1 && guideRect.height > 1 {
                let guideShort = Float(min(guideRect.width, guideRect.height))
                let insetX = guideRect.width * CGFloat(Self.guideInsetFraction)
                let insetY = guideRect.height * CGFloat(Self.guideInsetFraction)
                let inner = guideRect.insetBy(dx: insetX, dy: insetY)

                // Too close / spilling out of the oval.
                if faceSide > guideShort * Self.guideMaxFaceFraction ||
                    bounds.minX < guideRect.minX - guideRect.width * 0.05 ||
                    bounds.maxX > guideRect.maxX + guideRect.width * 0.05 ||
                    bounds.minY < guideRect.minY - guideRect.height * 0.05 ||
                    bounds.maxY > guideRect.maxY + guideRect.height * 0.05 {
                    return .tooClose
                }

                // Too far — face does not fill enough of the oval.
                if faceSide < guideShort * max(options.minFaceFraction, Self.guideMinFaceFraction) {
                    return .tooFar
                }

                // Not in the middle of the circle.
                let dx = abs(Float(bounds.midX) - Float(guideRect.midX)) / Float(guideRect.width)
                let dy = abs(Float(bounds.midY) - Float(guideRect.midY)) / Float(guideRect.height)
                if dx > Self.guideMaxOffCenter || dy > Self.guideMaxOffCenter {
                    return .offCenter
                }

                // Face box must mostly sit inside the oval's inner area.
                let overlap = bounds.intersection(inner)
                let overlapArea = max(overlap.width, 0) * max(overlap.height, 0)
                let faceArea = max(bounds.width * bounds.height, 1)
                if Float(overlapArea / faceArea) < Self.guideMinOverlap {
                    return .offCenter
                }
            } else {
                let shortSide = Float(min(frameWidth, frameHeight))
                let margin = shortSide * Self.edgeMarginFraction
                let cropped = Float(bounds.minX) < -margin || Float(bounds.minY) < -margin ||
                    Float(bounds.maxX) > Float(frameWidth) + margin ||
                    Float(bounds.maxY) > Float(frameHeight) + margin
                if cropped || faceSide > shortSide * Self.maxFaceFraction { return .tooClose }

                if faceSide < shortSide * options.minFaceFraction { return .tooFar }

                let dx = abs(Float(bounds.midX) - Float(frameWidth) / 2) / Float(frameWidth)
                let dy = abs(Float(bounds.midY) - Float(frameHeight) / 2) / Float(frameHeight)
                if dx > Self.maxOffCenter || dy > Self.maxOffCenter { return .offCenter }
            }
        }

        if !isAligned(face) { return .lookStraight }

        if !face.quality.isNaN && face.quality < options.qualityThreshold {
            return .lowQuality
        }

        return .none
    }

    /// The face has to be reasonably square to the camera before the attempt starts.
    private func isAligned(_ face: DetectedFace) -> Bool {
        if !face.hasPose { return true }
        let limit = max(options.alignAngle, 1)
        return abs(face.yaw) <= limit && abs(face.pitch) <= limit &&
            (face.roll.isNaN || abs(face.roll) <= limit)
    }

    // MARK: - Evaluation

    private struct Eval {
        let satisfied: Bool
        let progress: Float
        var wrongWay: Bool = false
    }

    private func evaluate(_ check: ActiveCheck, _ face: DetectedFace) -> Eval {
        switch check {
        case .smile: return ratio(face.smile, options.smileThreshold)
        case .blink: return blink(face)
        case .turnLeft, .turnRight:
            return angle(face.yaw, options.yawThreshold, options.yawSign(check))
        case .turnUp, .turnDown:
            return angle(face.pitch, options.pitchThreshold, options.pitchSign(check))
        case .perspective: return perspective(face)
        }
    }

    private func ratio(_ value: Float, _ threshold: Float) -> Eval {
        if value.isNaN { return Eval(satisfied: false, progress: checkProgress) }
        let target = max(threshold, 0.01)
        return Eval(satisfied: value >= threshold, progress: value / target)
    }

    private func angle(_ value: Float, _ threshold: Float, _ sign: Float) -> Eval {
        if value.isNaN { return Eval(satisfied: false, progress: checkProgress) }
        let target = max(threshold, 1)
        let towards = value * sign
        if towards <= 0 && abs(value) >= target * Self.wrongWayFraction {
            return Eval(satisfied: false, progress: 0, wrongWay: true)
        }
        return Eval(satisfied: towards >= target, progress: max(towards / target, 0))
    }

    private func blink(_ face: DetectedFace) -> Eval {
        let eyesOpen = face.eyesOpen
        if !eyesOpen.isNaN {
            let closed = eyesOpen <= options.blinkThreshold
            let open = eyesOpen >= options.blinkThreshold + Self.blinkHysteresis
            if closed {
                eyesWereClosed = true
            } else if open && eyesWereClosed {
                eyesWereClosed = false
                blinks += 1
            }
        }
        let target = max(options.blinksNumber, 1)
        return Eval(satisfied: blinks >= target, progress: Float(blinks) / Float(target))
    }

    private func perspective(_ face: DetectedFace) -> Eval {
        let width = Float(face.width)
        if width <= 0 { return Eval(satisfied: false, progress: checkProgress) }
        if baselineWidth <= 0 {
            baselineWidth = width
            return Eval(satisfied: false, progress: 0)
        }
        let growth = width / baselineWidth - 1
        let target = max(options.perspectiveThreshold, 0.01)
        return Eval(satisfied: growth >= target, progress: max(growth / target, 0))
    }

    private func advanceTo(_ index: Int, _ face: DetectedFace) {
        activeIndex = index
        steps[index] = .active
        resetCheckState()
        if plan[index] == .perspective {
            baselineWidth = Float(face.width)
        }
    }

    private func resetProgress() {
        for i in steps.indices { steps[i] = .pending }
        passive = .pending
        activeIndex = -1
        notice = .none
        passiveSum = 0
        passiveCount = 0
        passiveScore = -1
        framesOnPassive = 0
        alignHoldFrames = 0
        alignStartedAt = Self.nowMs()
        resetCheckState()
    }

    private func resetCheckState() {
        checkProgress = 0
        framesOnCheck = 0
        holdFrames = 0
        blinks = 0
        eyesWereClosed = false
        baselineWidth = 0
    }

    private func finish(_ result: Phase) {
        if result == .failed {
            if passive == .active { passive = .failed }
            if activeIndex >= 0 && activeIndex < steps.count && steps[activeIndex] != .passed {
                steps[activeIndex] = .failed
            }
        }
        if result == .passed {
            passive = .passed
            for i in steps.indices { steps[i] = .passed }
            checkProgress = 1
        }
        phase = result
        finishedAt = Self.nowMs()
    }

    private static func nowMs() -> Int64 { Int64(CACurrentMediaTime() * 1000) }

    /// How long the face has to come into the circle and face the camera.
    private static let alignBudgetMs: Int64 = 20_000
    /// A face gone for longer than this starts the attempt over.
    private static let faceLostGraceMs: Int64 = 1_000
    /// Frames the condition has to hold, so one noisy frame cannot pass a challenge.
    private static let holdFrames = 2
    /// Frames the face must stay well framed in the oval before the passive gate starts.
    private static let alignHoldFrames = 8
    /// Eyes count as open again this far above the closed threshold.
    private static let blinkHysteresis: Float = 0.2
    /// Turning this far the wrong way earns a nudge.
    private static let wrongWayFraction: Float = 0.6
    /// Past this much of the frame's short side the face is too close to fit.
    private static let maxFaceFraction: Float = 0.92
    /// How far outside the frame a face box may sit before it counts as cropped.
    private static let edgeMarginFraction: Float = 0.02
    /// How far the face centre may sit from the frame centre, as a fraction of the frame.
    private static let maxOffCenter: Float = 0.22
    /// Oval inset used when checking the face sits inside the guide.
    private static let guideInsetFraction: Float = 0.08
    /// Smallest face vs the oval's short side.
    private static let guideMinFaceFraction: Float = 0.45
    /// Largest face vs the oval's short side.
    private static let guideMaxFaceFraction: Float = 0.98
    /// How far the face centre may sit from the oval centre, as a fraction of the oval.
    private static let guideMaxOffCenter: Float = 0.18
    /// Minimum fraction of the face box that must overlap the oval's inner area.
    private static let guideMinOverlap: Float = 0.70
}
