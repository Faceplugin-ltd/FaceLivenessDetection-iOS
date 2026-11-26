import AVFoundation
import UIKit
import FaceLivenessKit

/// Guided active-liveness screen.
///
/// One attempt runs in three stages, in this order: the face is found and aligned, the **passive
/// anti-spoofing check** scores it, and only then are the challenges asked. A printed photo or a
/// replayed video is turned away at the gate, before it is ever invited to blink.
///
/// Present it for a result:
/// ```swift
/// ActiveLivenessViewController.present(from: self, options: options) { result in
///     if result?.passed == true { /* live person */ }
/// }
/// ```
/// `FaceEngine.shared.start` has to have succeeded before this screen opens.
///
/// Mirrors Android `face-liveness-active/ActiveLivenessActivity`.
final class ActiveLivenessViewController: BaseCameraViewController {

    static func present(
        from presenter: UIViewController,
        options: ActiveLivenessOptions = ActiveLivenessOptions(),
        completion: @escaping (ActiveLivenessResult?) -> Void
    ) {
        let controller = ActiveLivenessViewController(options: options)
        controller.completion = completion
        controller.modalPresentationStyle = .fullScreen
        presenter.present(controller, animated: true)
    }

    private let options: ActiveLivenessOptions
    private var completion: ((ActiveLivenessResult?) -> Void)?

    private let overlay = FaceFrameOverlayView()
    private let stepCounter = UILabel()
    private let instructionCard = UIView()
    private let challengeIcon = UIImageView()
    private let challengeTitle = UILabel()
    private let challengeHint = UILabel()
    private let stepDots = UIStackView()

    private let preparePanel = UIView()
    private let prepareBody = UILabel()

    private let resultPanel = UIView()
    private let resultIcon = UIImageView()
    private let resultTitle = UILabel()
    private let resultBody = UILabel()
    private let chipDuration = PillLabel()
    private let chipPassive = PillLabel()
    private let resultSteps = UIStackView()

    private var livenessSession: ActiveLivenessSession?
    private var plan: [ActiveCheck] = []
    private var attemptRunning = false
    private var lastPassedCount = 0
    private var renderedInstruction: String?
    private var lastResult: ActiveLivenessResult?
    private var watchdog: DispatchWorkItem?

    init(options: ActiveLivenessOptions) {
        self.options = options
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func viewDidLoad() {
        super.viewDidLoad()
        buildUI()
        showPrepare()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        if attemptRunning {
            stopAttempt()
            livenessSession?.cancel()
        }
    }

    // MARK: - Attempt lifecycle

    private func showPrepare() {
        stopAttempt()
        plan = options.buildPlan()
        livenessSession = ActiveLivenessSession(plan: plan, options: options)
        lastPassedCount = 0
        renderedInstruction = nil

        resultPanel.isHidden = true
        preparePanel.isHidden = false
        instructionCard.isHidden = true
        stepCounter.isHidden = true
        stepDots.isHidden = true
        overlay.setProgress(0, animated: false)
        overlay.setAccentColor(FPAL.ring)

        // How many actions, not which ones: naming the sequence in advance is exactly what
        // options.randomize exists to prevent. The result card lists every step afterwards.
        prepareBody.text = String(
            format: "Your face is checked for spoofing first, then you will be asked to perform %d short actions. Hold the phone at eye level in even light, with your whole face inside the circle, and follow the instruction on screen.",
            plan.count
        )
    }

    private func startAttempt() {
        preparePanel.isHidden = true
        resultPanel.isHidden = true
        instructionCard.isHidden = false
        stepCounter.isHidden = false
        stepDots.isHidden = false
        buildStepDots()
        renderedInstruction = nil
        livenessSession?.start()
        attemptRunning = true
        renderState()
        scheduleWatchdog()
    }

    private func stopAttempt() {
        watchdog?.cancel()
        watchdog = nil
        attemptRunning = false
    }

    private func scheduleWatchdog() {
        watchdog?.cancel()
        let perStage = Double(options.framesWait) * 200.0
        let ms = min(25_000.0 + Double(plan.count + 1) * perStage, 300_000.0)
        let work = DispatchWorkItem { [weak self] in
            guard let self, let active = self.livenessSession, !active.isFinished else { return }
            active.timeOut()
            self.renderState()
        }
        watchdog = work
        DispatchQueue.main.asyncAfter(deadline: .now() + ms / 1000.0, execute: work)
    }

    // MARK: - Camera frames

    override func onSampleBuffer(_ sampleBuffer: CMSampleBuffer, connection: AVCaptureConnection) {
        guard attemptRunning, FaceEngine.shared.isReady,
              let active = livenessSession, !active.isFinished,
              let image = CameraFrameUtils.liveEngineImage(from: sampleBuffer, frontCamera: useFrontCamera)
        else { return }

        let frameWidth = Int(image.size.width)
        let frameHeight = Int(image.size.height)
        // Map the on-screen oval into image coordinates so align waits for the face to
        // enter / centre / fit the circle, not just the full camera frame.
        let guideRect = Self.imageRect(
            forViewRect: overlay.faceFrame,
            in: cameraView.bounds,
            imageSize: image.size
        )
        let detectOptions: DetectOptions = active.needsLiveness ? .active : .activeFast

        beginSDKWork()
        FaceEngine.shared.async { [weak self] in
            guard let self else { return }
            let faces = FaceEngine.shared.detect(image, options: detectOptions)
            if !active.isFinished, self.attemptRunning {
                active.onFrame(
                    faces: faces,
                    frameWidth: frameWidth,
                    frameHeight: frameHeight,
                    guideRect: guideRect
                )
            }
            DispatchQueue.main.async {
                self.endSDKWork()
                if self.attemptRunning { self.renderState() }
            }
        }
    }

    /// Inverse of the preview's aspect-fill mapping: view oval → upright engine image.
    private static func imageRect(forViewRect viewRect: CGRect, in viewBounds: CGRect, imageSize: CGSize) -> CGRect {
        let viewW = viewBounds.width, viewH = viewBounds.height
        let frameW = imageSize.width, frameH = imageSize.height
        guard viewW > 1, viewH > 1, frameW > 1, frameH > 1, viewRect.width > 1, viewRect.height > 1 else {
            return .zero
        }
        let scale = max(viewW / frameW, viewH / frameH)
        let dx = (viewW - frameW * scale) / 2
        let dy = (viewH - frameH * scale) / 2
        return CGRect(
            x: (viewRect.minX - dx) / scale,
            y: (viewRect.minY - dy) / scale,
            width: viewRect.width / scale,
            height: viewRect.height / scale
        )
    }

    // MARK: - Rendering

    private func renderState() {
        guard let active = livenessSession else { return }
        let state = active.snapshot()
        overlay.setProgress(CGFloat(state.progress))
        renderStepDots(state)

        switch state.phase {
        case .idle:
            break
        case .align:
            overlay.setAccentColor(FPAL.ring)
            stepCounter.text = "Step 1 of \(state.total)"
            setInstruction(
                icon: noticeIcon(state.notice),
                title: noticeText(
                    state.notice,
                    fallback: "Place your face in the circle and look straight ahead"
                ),
                hint: restartHint(state)
            )
        case .passive:
            overlay.setAccentColor(FPAL.ring)
            stepCounter.text = "Anti-spoofing check"
            setInstruction(
                icon: state.notice == .none ? "checkerboard.shield" : noticeIcon(state.notice),
                title: noticeText(state.notice, fallback: "Hold still — checking for a live face"),
                hint: restartHint(state)
            )
        case .running:
            overlay.setAccentColor(FPAL.ring)
            stepCounter.text = "Step \(max(state.activeIndex + 1, 1)) of \(state.total)"
            renderChallenge(state)
            if state.passedCount < lastPassedCount { lastPassedCount = state.passedCount }
            if state.passedCount > lastPassedCount {
                overlay.pulse(FPAL.pass)
                haptic()
            }
            lastPassedCount = state.passedCount
        case .passed:
            overlay.setAccentColor(FPAL.pass)
            overlay.pulse(FPAL.pass)
            showResult(state)
        case .failed:
            overlay.setAccentColor(FPAL.fail)
            showResult(state)
        }
    }

    private func renderChallenge(_ state: ActiveLivenessSession.State) {
        let blocked = state.notice != .none && state.notice != .wrongWay
        if blocked {
            setInstruction(
                icon: noticeIcon(state.notice),
                title: noticeText(state.notice, fallback: "Hold still…", noFace: "Face lost — the check starts again"),
                hint: ""
            )
        } else if let check = state.current {
            setInstruction(
                icon: check.iconName,
                title: check.title,
                hint: state.notice == .wrongWay ? "The other way round" : check.hint
            )
        } else {
            setInstruction(icon: "faceid", title: "Hold still…", hint: "")
        }
    }

    private func restartHint(_ state: ActiveLivenessSession.State) -> String {
        state.restarts > 0 ? "Starting again" : ""
    }

    private func noticeText(
        _ notice: ActiveLivenessSession.Notice,
        fallback: String,
        noFace: String = "Looking for your face…"
    ) -> String {
        switch notice {
        case .noFace: return noFace
        case .manyFaces: return "Only one face in the frame, please"
        case .tooFar: return "Move closer — fill the circle with your face"
        case .tooClose: return "Move back a little — keep your whole face inside the circle"
        case .offCenter: return "Move your face into the middle of the circle"
        case .lookStraight: return "Look straight at the camera"
        case .lowQuality: return "Too dark or blurry — find steadier, even light"
        case .notScorable: return "Cannot read your face — hold still and face the light"
        default: return fallback
        }
    }

    private func noticeIcon(_ notice: ActiveLivenessSession.Notice) -> String {
        switch notice {
        case .tooFar: return "arrow.up.left.and.arrow.down.right"
        case .lowQuality, .notScorable: return "checkerboard.shield"
        default: return "faceid"
        }
    }

    private func setInstruction(icon: String, title: String, hint: String) {
        let key = "\(icon)|\(title)|\(hint)"
        if key == renderedInstruction { return }
        renderedInstruction = key
        challengeIcon.image = UIImage(systemName: icon)
        challengeTitle.text = title
        challengeHint.text = hint
        challengeHint.isHidden = hint.isEmpty
    }

    private func buildStepDots() {
        stepDots.arrangedSubviews.forEach { $0.removeFromSuperview() }
        for _ in 0..<(plan.count + 1) {
            let dot = UIView()
            dot.backgroundColor = FPAL.pendingDot
            dot.layer.cornerRadius = 2.5
            dot.translatesAutoresizingMaskIntoConstraints = false
            dot.widthAnchor.constraint(equalToConstant: 26).isActive = true
            dot.heightAnchor.constraint(equalToConstant: 5).isActive = true
            stepDots.addArrangedSubview(dot)
        }
    }

    private func renderStepDots(_ state: ActiveLivenessSession.State) {
        let all = [state.passive] + state.steps
        guard stepDots.arrangedSubviews.count == all.count else { return }
        for (index, step) in all.enumerated() {
            stepDots.arrangedSubviews[index].backgroundColor = dotColor(step)
        }
    }

    private func dotColor(_ step: ActiveLivenessSession.StepState) -> UIColor {
        switch step {
        case .passed: return FPAL.pass
        case .failed: return FPAL.fail
        case .active: return FPAL.ring
        case .pending: return FPAL.pendingDot
        }
    }

    private func showResult(_ state: ActiveLivenessSession.State) {
        guard resultPanel.isHidden else { return }
        stopAttempt()
        instructionCard.isHidden = true
        stepCounter.isHidden = true
        stepDots.isHidden = true
        resultPanel.isHidden = false
        haptic()
        lastResult = ActiveLivenessResult.from(state: state, plan: plan)

        let passed = state.phase == .passed
        resultIcon.image = UIImage(systemName: passed ? "checkmark.circle.fill" : "xmark.circle.fill")
        resultIcon.tintColor = passed ? FPAL.pass : FPAL.fail
        resultTitle.text = passed ? "Liveness confirmed" : "Liveness not confirmed"
        if passed {
            resultBody.text = String(format: "The anti-spoofing check passed and all %d challenges were completed by a live person.", state.total)
        } else if state.failure == .spoof {
            resultBody.text = "The anti-spoofing check did not pass, so the challenges were not asked."
        } else if state.failure == .cancelled {
            resultBody.text = "The check was stopped before it finished."
        } else if let failed = state.failedCheck {
            resultBody.text = String(format: "The “%@” challenge was not completed in time.", failed.title)
        } else {
            resultBody.text = "The sequence timed out before every challenge was completed."
        }

        chipDuration.text = String(format: "Completed in %.1f s", Double(state.elapsedMs) / 1000.0)
        if state.passiveScore >= 0 {
            chipPassive.text = String(format: "Passive score %d%%", Int((min(max(state.passiveScore, 0), 1) * 100).rounded()))
        } else {
            chipPassive.text = "Passive score —"
        }

        resultSteps.arrangedSubviews.forEach { $0.removeFromSuperview() }
        resultSteps.addArrangedSubview(row(icon: "checkerboard.shield", title: "Anti-spoofing check", stateText: stateLabel(state.passive), stateColor: dotColor(state.passive)))
        for (index, check) in plan.enumerated() {
            let step = index < state.steps.count ? state.steps[index] : .pending
            resultSteps.addArrangedSubview(row(icon: check.iconName, title: check.title, stateText: stateLabel(step), stateColor: dotColor(step)))
        }
    }

    private func stateLabel(_ step: ActiveLivenessSession.StepState) -> String {
        switch step {
        case .passed: return "Passed"
        case .failed: return "Failed"
        default: return "Not reached"
        }
    }

    // MARK: - Actions

    @objc private func didTapClose() {
        dismissSelf()
    }

    @objc private func didTapSwitchCamera() {
        switchCamera()
        showPrepare()
    }

    @objc private func didTapStart() { startAttempt() }
    @objc private func didTapRetry() { showPrepare() }
    @objc private func didTapDone() { dismissSelf() }

    private func dismissSelf() {
        let result = lastResult
        let handler = completion
        completion = nil
        dismiss(animated: true) { handler?(result) }
    }

    private func haptic() {
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
    }

    // MARK: - UI construction

    private func buildUI() {
        overlay.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(overlay)
        NSLayoutConstraint.activate([
            overlay.topAnchor.constraint(equalTo: view.topAnchor),
            overlay.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            overlay.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            overlay.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])

        let close = roundButton(systemName: "xmark", action: #selector(didTapClose))
        let switchCam = roundButton(systemName: "arrow.triangle.2.circlepath.camera", action: #selector(didTapSwitchCamera))
        view.addSubview(close)
        view.addSubview(switchCam)
        NSLayoutConstraint.activate([
            close.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 8),
            close.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            switchCam.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 8),
            switchCam.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
        ])

        stepCounter.font = .systemFont(ofSize: 13, weight: .semibold)
        stepCounter.textColor = FPAL.muted
        stepCounter.textAlignment = .center
        stepCounter.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(stepCounter)
        NSLayoutConstraint.activate([
            stepCounter.topAnchor.constraint(equalTo: close.bottomAnchor, constant: 12),
            stepCounter.centerXAnchor.constraint(equalTo: view.centerXAnchor),
        ])

        buildInstructionCard()
        buildStepDotsContainer()
        buildPreparePanel()
        buildResultPanel()
    }

    private func buildInstructionCard() {
        challengeIcon.contentMode = .scaleAspectFit
        challengeIcon.tintColor = FPAL.text
        challengeIcon.preferredSymbolConfiguration = UIImage.SymbolConfiguration(pointSize: 30, weight: .semibold)
        challengeIcon.translatesAutoresizingMaskIntoConstraints = false
        challengeIcon.widthAnchor.constraint(equalToConstant: 48).isActive = true
        challengeIcon.heightAnchor.constraint(equalToConstant: 48).isActive = true

        challengeTitle.font = .systemFont(ofSize: 20, weight: .bold)
        challengeTitle.textColor = FPAL.text
        challengeTitle.textAlignment = .center
        challengeTitle.numberOfLines = 0
        challengeTitle.lineBreakMode = .byWordWrapping
        challengeTitle.setContentCompressionResistancePriority(.required, for: .vertical)

        challengeHint.font = .systemFont(ofSize: 14)
        challengeHint.textColor = FPAL.muted
        challengeHint.textAlignment = .center
        challengeHint.numberOfLines = 0
        challengeHint.lineBreakMode = .byWordWrapping
        challengeHint.setContentCompressionResistancePriority(.required, for: .vertical)

        let stack = UIStackView(arrangedSubviews: [challengeIcon, challengeTitle, challengeHint])
        stack.axis = .vertical
        stack.alignment = .center
        stack.spacing = 8
        stack.translatesAutoresizingMaskIntoConstraints = false

        instructionCard.backgroundColor = FPAL.overlay
        instructionCard.layer.cornerRadius = 20
        instructionCard.translatesAutoresizingMaskIntoConstraints = false
        instructionCard.addSubview(stack)
        view.addSubview(instructionCard)
        // Sit the instruction card below the oval (the oval centre is at ~42% of the height).
        let cardTop = NSLayoutConstraint(
            item: instructionCard, attribute: .top,
            relatedBy: .equal,
            toItem: view, attribute: .bottom,
            multiplier: 0.60, constant: 0
        )
        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: instructionCard.topAnchor, constant: 16),
            stack.leadingAnchor.constraint(equalTo: instructionCard.leadingAnchor, constant: 20),
            stack.trailingAnchor.constraint(equalTo: instructionCard.trailingAnchor, constant: -20),
            stack.bottomAnchor.constraint(equalTo: instructionCard.bottomAnchor, constant: -16),
            // Span the screen so long copy wraps at a normal reading width (not content-hugged skinny).
            instructionCard.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 28),
            instructionCard.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -28),
            challengeTitle.widthAnchor.constraint(equalTo: stack.widthAnchor),
            challengeHint.widthAnchor.constraint(equalTo: stack.widthAnchor),
            cardTop,
        ])
    }

    private func buildStepDotsContainer() {
        stepDots.axis = .horizontal
        stepDots.spacing = 6
        stepDots.alignment = .center
        stepDots.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(stepDots)
        NSLayoutConstraint.activate([
            stepDots.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            stepDots.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -24),
        ])
    }

    private func buildPreparePanel() {
        let title = sheetTitle("Get ready")
        prepareBody.font = .systemFont(ofSize: 14)
        prepareBody.textColor = FPAL.muted
        prepareBody.numberOfLines = 0

        let start = filledButton("Start check", action: #selector(didTapStart))

        let stack = UIStackView(arrangedSubviews: [title, prepareBody, start])
        stack.axis = .vertical
        stack.spacing = 16
        layoutSheet(preparePanel, content: stack)
    }

    private func buildResultPanel() {
        resultIcon.contentMode = .scaleAspectFit
        resultIcon.preferredSymbolConfiguration = UIImage.SymbolConfiguration(pointSize: 44, weight: .semibold)
        resultIcon.translatesAutoresizingMaskIntoConstraints = false
        resultIcon.heightAnchor.constraint(equalToConstant: 56).isActive = true

        resultTitle.font = .systemFont(ofSize: 22, weight: .bold)
        resultTitle.textColor = FPAL.text
        resultTitle.textAlignment = .center

        resultBody.font = .systemFont(ofSize: 14)
        resultBody.textColor = FPAL.muted
        resultBody.textAlignment = .center
        resultBody.numberOfLines = 0

        let chips = UIStackView(arrangedSubviews: [chipDuration, chipPassive])
        chips.axis = .horizontal
        chips.spacing = 8
        chips.alignment = .center
        chips.distribution = .fillProportionally

        resultSteps.axis = .vertical
        resultSteps.spacing = 10

        let retry = filledButton("Try again", action: #selector(didTapRetry))
        let done = outlineButton("Done", action: #selector(didTapDone))

        let stack = UIStackView(arrangedSubviews: [resultIcon, resultTitle, resultBody, chips, resultSteps, retry, done])
        stack.axis = .vertical
        stack.spacing = 14
        stack.setCustomSpacing(18, after: chips)
        layoutSheet(resultPanel, content: stack)
    }

    // MARK: - UI helpers

    private func layoutSheet(_ panel: UIView, content: UIStackView) {
        panel.backgroundColor = FPAL.surface
        panel.layer.cornerRadius = 28
        panel.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
        panel.layer.borderWidth = 1
        panel.layer.borderColor = FPAL.stroke.cgColor
        panel.translatesAutoresizingMaskIntoConstraints = false
        content.translatesAutoresizingMaskIntoConstraints = false
        panel.addSubview(content)
        view.addSubview(panel)
        NSLayoutConstraint.activate([
            panel.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            panel.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            panel.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            content.topAnchor.constraint(equalTo: panel.topAnchor, constant: 22),
            content.leadingAnchor.constraint(equalTo: panel.leadingAnchor, constant: 22),
            content.trailingAnchor.constraint(equalTo: panel.trailingAnchor, constant: -22),
            content.bottomAnchor.constraint(equalTo: panel.safeAreaLayoutGuide.bottomAnchor, constant: -18),
        ])
    }

    private func sheetTitle(_ text: String) -> UILabel {
        let label = UILabel()
        label.text = text
        label.font = .systemFont(ofSize: 22, weight: .bold)
        label.textColor = FPAL.text
        return label
    }

    private func row(icon: String, title: String, stateText: String, stateColor: UIColor) -> UIView {
        let iconView = UIImageView(image: UIImage(systemName: icon))
        iconView.tintColor = FPAL.text
        iconView.contentMode = .scaleAspectFit
        iconView.translatesAutoresizingMaskIntoConstraints = false
        iconView.widthAnchor.constraint(equalToConstant: 24).isActive = true
        iconView.heightAnchor.constraint(equalToConstant: 24).isActive = true

        let titleLabel = UILabel()
        titleLabel.text = title
        titleLabel.font = .systemFont(ofSize: 15, weight: .medium)
        titleLabel.textColor = FPAL.text

        let stateLabel = UILabel()
        stateLabel.text = stateText
        stateLabel.font = .systemFont(ofSize: 14, weight: .semibold)
        stateLabel.textColor = stateColor
        stateLabel.setContentHuggingPriority(.required, for: .horizontal)

        let stack = UIStackView(arrangedSubviews: [iconView, titleLabel, stateLabel])
        stack.axis = .horizontal
        stack.spacing = 12
        stack.alignment = .center
        return stack
    }

    private func roundButton(systemName: String, action: Selector) -> UIButton {
        let button = UIButton(type: .system)
        button.setImage(UIImage(systemName: systemName), for: .normal)
        button.tintColor = .white
        button.backgroundColor = UIColor(white: 0, alpha: 0.35)
        button.layer.cornerRadius = 22
        button.translatesAutoresizingMaskIntoConstraints = false
        button.widthAnchor.constraint(equalToConstant: 44).isActive = true
        button.heightAnchor.constraint(equalToConstant: 44).isActive = true
        button.addTarget(self, action: action, for: .touchUpInside)
        return button
    }

    private func filledButton(_ title: String, action: Selector) -> UIButton {
        let button = UIButton(type: .system)
        button.setTitle(title, for: .normal)
        button.setTitleColor(.white, for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 17, weight: .semibold)
        button.backgroundColor = FPAL.accent
        button.layer.cornerRadius = 26
        button.translatesAutoresizingMaskIntoConstraints = false
        button.heightAnchor.constraint(equalToConstant: 52).isActive = true
        button.addTarget(self, action: action, for: .touchUpInside)
        return button
    }

    private func outlineButton(_ title: String, action: Selector) -> UIButton {
        let button = UIButton(type: .system)
        button.setTitle(title, for: .normal)
        button.setTitleColor(FPAL.text, for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 17, weight: .semibold)
        button.backgroundColor = .clear
        button.layer.cornerRadius = 26
        button.layer.borderWidth = 1
        button.layer.borderColor = FPAL.stroke.cgColor
        button.translatesAutoresizingMaskIntoConstraints = false
        button.heightAnchor.constraint(equalToConstant: 52).isActive = true
        button.addTarget(self, action: action, for: .touchUpInside)
        return button
    }
}

/// Rounded chip label, used for the result's duration / passive-score pills.
final class PillLabel: UILabel {
    override init(frame: CGRect) {
        super.init(frame: frame)
        configure()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        configure()
    }

    private func configure() {
        font = .systemFont(ofSize: 13, weight: .semibold)
        textColor = FPAL.accent
        backgroundColor = FPAL.accentDim
        textAlignment = .center
        layer.cornerRadius = 15
        clipsToBounds = true
    }

    override var intrinsicContentSize: CGSize {
        let base = super.intrinsicContentSize
        return CGSize(width: base.width + 28, height: 30)
    }
}

private extension NSLayoutConstraint {
    func withPriority(_ priority: UILayoutPriority) -> NSLayoutConstraint {
        self.priority = priority
        return self
    }
}
