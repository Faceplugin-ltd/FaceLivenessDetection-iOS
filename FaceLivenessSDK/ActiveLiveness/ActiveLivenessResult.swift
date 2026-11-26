import Foundation

/// What one attempt came to, handed back by `ActiveLivenessViewController`.
///
/// `passed` is the only thing most callers need: it is true when the passive anti-spoofing gate
/// cleared *and* every challenge was completed. `failure` says why it did not.
///
/// Mirrors Android `face-liveness-active/ActiveLivenessResult`.
struct ActiveLivenessResult {
    let passed: Bool
    let failure: ActiveLivenessSession.Failure
    /// Averaged passive anti-spoofing score, or -1 when the engine never returned one.
    let passiveScore: Float
    let passivePassed: Bool
    /// The challenges asked, in the order they were asked.
    let challenges: [ActiveCheck]
    /// One outcome per entry of `challenges`.
    let outcomes: [ActiveLivenessSession.StepState]
    let durationMs: Int64

    /// The challenge that ended the attempt, when one did.
    var failedCheck: ActiveCheck? {
        guard let index = outcomes.firstIndex(of: .failed), index < challenges.count else { return nil }
        return challenges[index]
    }

    static func from(state: ActiveLivenessSession.State, plan: [ActiveCheck]) -> ActiveLivenessResult {
        ActiveLivenessResult(
            passed: state.phase == .passed,
            failure: state.failure,
            passiveScore: state.passiveScore,
            passivePassed: state.passive == .passed,
            challenges: plan,
            outcomes: state.steps,
            durationMs: state.elapsedMs
        )
    }
}
