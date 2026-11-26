import UIKit
import FaceLivenessKit

/// Home: engine status, the two liveness demos, settings and about.
///
/// Mirrors Android `ui/MainActivity` + `activity_main.xml` — hero header with the status pill, an
/// Active-liveness and a Passive-liveness card, a Settings and an About tile, and a row that opens
/// the integration guide.
final class ViewController: UIViewController {

    /// `FP1.…` from FacePlugin, for this app's bundle id on the `facerecognitionsdk` runtime.
    ///
    /// The app moved to the `facerecognitionsdk` engine (the same build the recognition iOS app
    /// ships), which checks licences with its own library. A key issued for the previous engine
    /// shows "Invalid license" / "Not activated" on a clean install — contact FacePlugin for one
    /// issued for this bundle id on this runtime.
    private let licenseKey =
        "FP1.RlBMMQMAAQASR/8KSL077W41P1kMAgAAeO7xq/Xl9I9RNUeW4pnmgceT4iFnB+TD8L9TLjv/sMFVSjIdVCrozc1SwyhqssZ0EKH7kkLlU3zvAMC7Xpo8wkXKpY7RDmOjTkeArkBQZLzMclidnMZbpWIR41ibyzDpx5iKRMLGl682MdlD5IquD9eqzd6UbQMzHOq2g6HioUbvwyX+pWZcu2Qd8oA6XSFj7sCACjxTeYv6bL0FMFF7coN+Cq3olfFo35SrX98cnPxmShbxlRw1bMUKNLHa2veFnHTlajJU4arOArKaXYQdZOEAYpMKJ7S6LVU+5raMj9uhOK0ZRdTi5YFpn5QjP7nYEk9QzNr3MRJaet1QC6dg8C9EDhIEihN867TLj9LjERMMrxANAboJ5f4eGaoo9xmFUNsdlSddEthXGBQDQVPYRR/ASx0XetPTgMvf+UrBoTGpV3s/h/hqSAjYFRSFBoq2PWgXypn1WNNvek3884fi1ROKCJdAp3F9LWG7fulICMOPhfO7UP31JiAkufGQHmJiVuwgBmPgPw//wg6O/V0MZAaNUsKe254he9Iqh7fDuqoapkaiZeN4ayHwvAz+plT0Xg/IIBVKA3r8wYxrn6Bv7tQ0nKiexb2TFQuP7nnmkG91oQxU2j4q2LAVeGmvU1X2WWtGkFCXP1LKs40vT4zbZCXiS8xTIGg7bAPimJa2HT/LdxbxrzB5uReoySyLADCBiAJCAN5t4UUmEa7GTXPJJQTLCBUWAxAS45ZVX+Gvl/NfD8cBDuot2X21yi2ii8C8KhawBXpK+lNM9v2+j7j2WjazqHV1AkIB2fbWuTH6G98Fej+s5TtDOI+wKKFcdWXz9+Osxk2yWEiSd5ohBshk0WGS92oOqsIbOSqphrnel16T5DjbLjuPl3s="

    private let statusPill = PaddedLabel()
    private var activeCard: UIControl!
    private var passiveCard: UIControl!
    private var sdkReady = false
    private var livenessAllowed = false

    override func viewDidLoad() {
        super.viewDidLoad()
        AppSettings.applyDefaults()
        view.backgroundColor = FPColor.bg
        navigationController?.setNavigationBarHidden(true, animated: false)
        buildUI()
        // Paint the home UI first; engine start loads models and can take a while.
        DispatchQueue.main.async { [weak self] in
            self?.startEngine()
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: animated)
    }

    // MARK: - Engine

    private func startEngine() {
        setStatus("Loading on-device models…", color: FPColor.statusInfo)
        FaceEngine.shared.start(license: licenseKey) { [weak self] code in
            guard let self else { return }
            self.sdkReady = code == Int(FaceRecognitionSDK.sdk_SUCCESS())
            FaceEngine.shared.async {
                let status = FaceEngine.shared.licenseStatus()
                DispatchQueue.main.async {
                    self.applyLicense(status)
                    if self.sdkReady {
                        self.setStatus("Ready · \(status.label)", color: FPColor.statusOk)
                    } else {
                        self.setStatus(self.licenseMessage(code), color: FPColor.statusError)
                    }
                }
            }
        }
    }

    private func applyLicense(_ status: LicenseStatus) {
        livenessAllowed = status.liveness
        for card in [activeCard, passiveCard].compactMap({ $0 }) {
            card.isEnabled = status.liveness
            card.alpha = status.liveness ? 1 : 0.45
        }
    }

    private func licenseMessage(_ code: Int) -> String {
        switch Int32(code) {
        case FaceRecognitionSDK.sdk_LICENSE_INVALID(): return "Invalid license!"
        case FaceRecognitionSDK.sdk_LICENSE_EXPIRED(): return "License expired!"
        case FaceRecognitionSDK.sdk_NOT_ACTIVATED(): return "No activated!"
        case FaceRecognitionSDK.sdk_INIT_FAILED():
            let detail = FaceEngine.shared.lastLicenseError().trimmingCharacters(in: .whitespaces)
            return detail.isEmpty ? "Init error!" : "Init error! \(detail)"
        default: return "SDK not ready: \(code)"
        }
    }

    private func setStatus(_ message: String, color: UIColor) {
        statusPill.text = message
        statusPill.textColor = color
        statusPill.backgroundColor = color.withAlphaComponent(0.15)
        statusPill.layer.borderColor = color.withAlphaComponent(0.40).cgColor
        statusPill.layer.borderWidth = 1
    }

    // MARK: - Actions

    @objc private func openActive() {
        guard ensureLivenessAllowed() else { return }
        ActiveLivenessViewController.present(from: self, options: AppSettings.activeLiveness()) { [weak self] result in
            guard let self, let result else { return }
            self.reportActiveResult(result)
        }
    }

    @objc private func openPassive() {
        guard ensureLivenessAllowed() else { return }
        navigationController?.pushViewController(LivenessCameraViewController(), animated: true)
    }

    @objc private func openSettings() {
        navigationController?.pushViewController(SettingsViewController(), animated: true)
    }

    @objc private func openAbout() {
        navigationController?.pushViewController(AboutViewController(), animated: true)
    }

    @objc private func openDocs() { openURL("https://doc.faceplugin.com") }
    @objc private func openSite() { openURL("https://faceplugin.com") }

    private func openURL(_ string: String) {
        guard let url = URL(string: string) else { return }
        UIApplication.shared.open(url)
    }

    private func ensureLivenessAllowed() -> Bool {
        if !sdkReady { toast("SDK not ready"); return false }
        if !livenessAllowed { toast("Liveness is not available on this license"); return false }
        return true
    }

    private func reportActiveResult(_ result: ActiveLivenessResult) {
        let message: String
        if result.passed {
            message = "Liveness confirmed — live person"
        } else if !result.passivePassed {
            message = "Anti-spoofing check failed — no challenges were asked"
        } else if let failed = result.failedCheck {
            message = "Liveness not confirmed — “\(failed.title)” was not completed"
        } else {
            message = "Liveness not confirmed"
        }
        toast(message)
    }

    private func toast(_ message: String) {
        let label = PaddedLabel()
        label.text = message
        label.textColor = .white
        label.backgroundColor = UIColor(white: 0, alpha: 0.85)
        label.font = .systemFont(ofSize: 14, weight: .medium)
        label.numberOfLines = 0
        label.textAlignment = .center
        label.layer.cornerRadius = 12
        label.clipsToBounds = true
        label.alpha = 0
        label.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(label)
        NSLayoutConstraint.activate([
            label.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 32),
            label.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -32),
            label.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -24),
        ])
        UIView.animate(withDuration: 0.2, animations: { label.alpha = 1 }) { _ in
            UIView.animate(withDuration: 0.3, delay: 2.4, options: []) { label.alpha = 0 } completion: { _ in
                label.removeFromSuperview()
            }
        }
    }

    // MARK: - UI

    private func buildUI() {
        let hero = buildHero()
        let checksHeader = sectionHeader("LIVENESS CHECKS")
        activeCard = buildBigCard(
            icon: "bolt.fill",
            title: "Active liveness",
            subtitle: "Anti-spoofing gate, then blink, smile, turn your head",
            gradient: true,
            action: #selector(openActive)
        )
        passiveCard = buildBigCard(
            icon: "viewfinder",
            title: "Passive liveness",
            subtitle: "Single-frame anti-spoofing with a live score HUD",
            gradient: false,
            action: #selector(openPassive)
        )
        let moreHeader = sectionHeader("MORE")
        let settingsTile = buildSmallTile(icon: "slider.horizontal.3", title: "Settings", subtitle: "Camera, thresholds, challenge sequence", action: #selector(openSettings))
        let aboutTile = buildSmallTile(icon: "info.circle", title: "About", subtitle: "SDK, license and contact", action: #selector(openAbout))
        let tilesRow = UIStackView(arrangedSubviews: [settingsTile, aboutTile])
        tilesRow.axis = .horizontal
        tilesRow.spacing = 12
        tilesRow.distribution = .fillEqually
        let docs = buildDocsRow()

        let column = UIStackView(arrangedSubviews: [hero, checksHeader, activeCard, passiveCard, moreHeader, tilesRow, docs])
        column.axis = .vertical
        column.spacing = 12
        column.setCustomSpacing(22, after: hero)
        column.setCustomSpacing(22, after: passiveCard)
        column.translatesAutoresizingMaskIntoConstraints = false

        let scroll = UIScrollView()
        scroll.alwaysBounceVertical = true
        scroll.translatesAutoresizingMaskIntoConstraints = false
        scroll.addSubview(column)
        view.addSubview(scroll)
        NSLayoutConstraint.activate([
            scroll.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scroll.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scroll.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scroll.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            column.topAnchor.constraint(equalTo: scroll.contentLayoutGuide.topAnchor, constant: 16),
            column.leadingAnchor.constraint(equalTo: scroll.contentLayoutGuide.leadingAnchor, constant: 16),
            column.trailingAnchor.constraint(equalTo: scroll.contentLayoutGuide.trailingAnchor, constant: -16),
            column.bottomAnchor.constraint(equalTo: scroll.contentLayoutGuide.bottomAnchor, constant: -24),
            column.widthAnchor.constraint(equalTo: scroll.frameLayoutGuide.widthAnchor, constant: -32),
        ])
    }

    private func buildHero() -> UIView {
        let card = GradientCard()
        card.setColors([UIColor(rgb: 0x201A2E), UIColor(rgb: 0x16151D)])
        card.layer.cornerRadius = 20
        card.layer.borderWidth = 1
        card.layer.borderColor = FPColor.stroke.cgColor

        let logo = UIImageView(image: UIImage(named: "FacePluginLogo")?.withRenderingMode(.alwaysOriginal))
        logo.contentMode = .scaleAspectFit
        logo.isUserInteractionEnabled = true
        logo.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(openSite)))
        logo.translatesAutoresizingMaskIntoConstraints = false
        logo.heightAnchor.constraint(equalToConstant: 40).isActive = true
        logo.setContentHuggingPriority(.required, for: .horizontal)

        let logoRow = UIStackView(arrangedSubviews: [logo, UIView()])
        logoRow.axis = .horizontal

        let tagline = UILabel()
        tagline.text = "On-device face liveness"
        tagline.font = .systemFont(ofSize: 26, weight: .bold)
        tagline.textColor = FPColor.text
        tagline.numberOfLines = 0

        let subtitle = UILabel()
        subtitle.text = "Passive anti-spoofing and guided active checks. Every frame is processed on this phone — no biometric data leaves the device."
        subtitle.font = .systemFont(ofSize: 14)
        subtitle.textColor = FPColor.muted
        subtitle.numberOfLines = 0

        statusPill.font = .systemFont(ofSize: 13, weight: .semibold)
        statusPill.layer.cornerRadius = 16
        statusPill.clipsToBounds = true
        statusPill.setContentHuggingPriority(.required, for: .horizontal)
        let pillRow = UIStackView(arrangedSubviews: [statusPill, UIView()])
        pillRow.axis = .horizontal

        let stack = UIStackView(arrangedSubviews: [logoRow, tagline, subtitle, pillRow])
        stack.axis = .vertical
        stack.spacing = 10
        stack.setCustomSpacing(16, after: logoRow)
        stack.setCustomSpacing(14, after: subtitle)
        stack.translatesAutoresizingMaskIntoConstraints = false
        card.addSubview(stack)
        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: card.topAnchor, constant: 22),
            stack.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 20),
            stack.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -20),
            stack.bottomAnchor.constraint(equalTo: card.bottomAnchor, constant: -22),
        ])
        return card
    }

    private func sectionHeader(_ text: String) -> UILabel {
        let label = UILabel()
        label.text = text
        label.font = .systemFont(ofSize: 12, weight: .semibold)
        label.textColor = FPColor.muted
        return label
    }

    private func buildBigCard(icon: String, title: String, subtitle: String, gradient: Bool, action: Selector) -> UIControl {
        let card = CardControl()
        if gradient {
            card.setColors([UIColor(rgb: 0x7C4DD6), UIColor(rgb: 0x5A2FB0)])
        } else {
            card.backgroundColor = FPColor.surface
            card.layer.borderWidth = 1
            card.layer.borderColor = FPColor.stroke.cgColor
        }
        card.layer.cornerRadius = 18
        card.addTarget(self, action: action, for: .touchUpInside)

        let iconCircle = iconBubble(icon, tint: gradient ? .white : FPColor.accent, background: gradient ? UIColor(white: 1, alpha: 0.18) : FPColor.accentDim)

        let titleLabel = UILabel()
        titleLabel.text = title
        titleLabel.font = .systemFont(ofSize: 18, weight: .bold)
        titleLabel.textColor = gradient ? .white : FPColor.text

        let subtitleLabel = UILabel()
        subtitleLabel.text = subtitle
        subtitleLabel.font = .systemFont(ofSize: 13)
        subtitleLabel.textColor = gradient ? UIColor(white: 1, alpha: 0.85) : FPColor.muted
        subtitleLabel.numberOfLines = 0

        let text = UIStackView(arrangedSubviews: [titleLabel, subtitleLabel])
        text.axis = .vertical
        text.spacing = 4

        let chevron = UIImageView(image: UIImage(systemName: "chevron.right"))
        chevron.tintColor = gradient ? .white : FPColor.muted
        chevron.setContentHuggingPriority(.required, for: .horizontal)

        let row = UIStackView(arrangedSubviews: [iconCircle, text, chevron])
        row.axis = .horizontal
        row.spacing = 14
        row.alignment = .center
        row.isUserInteractionEnabled = false
        row.translatesAutoresizingMaskIntoConstraints = false
        card.addSubview(row)
        NSLayoutConstraint.activate([
            row.topAnchor.constraint(equalTo: card.topAnchor, constant: 18),
            row.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 16),
            row.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -16),
            row.bottomAnchor.constraint(equalTo: card.bottomAnchor, constant: -18),
        ])
        return card
    }

    private func buildSmallTile(icon: String, title: String, subtitle: String, action: Selector) -> UIControl {
        let card = CardControl()
        card.backgroundColor = FPColor.surface
        card.layer.cornerRadius = 16
        card.layer.borderWidth = 1
        card.layer.borderColor = FPColor.stroke.cgColor
        card.addTarget(self, action: action, for: .touchUpInside)

        let iconCircle = iconBubble(icon, tint: FPColor.accent, background: FPColor.accentDim)
        let titleLabel = UILabel()
        titleLabel.text = title
        titleLabel.font = .systemFont(ofSize: 16, weight: .semibold)
        titleLabel.textColor = FPColor.text
        let subtitleLabel = UILabel()
        subtitleLabel.text = subtitle
        subtitleLabel.font = .systemFont(ofSize: 12)
        subtitleLabel.textColor = FPColor.muted
        subtitleLabel.numberOfLines = 0

        let stack = UIStackView(arrangedSubviews: [iconCircle, titleLabel, subtitleLabel])
        stack.axis = .vertical
        stack.spacing = 8
        stack.alignment = .leading
        stack.isUserInteractionEnabled = false
        stack.translatesAutoresizingMaskIntoConstraints = false
        card.addSubview(stack)
        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: card.topAnchor, constant: 16),
            stack.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 16),
            stack.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -16),
            stack.bottomAnchor.constraint(equalTo: card.bottomAnchor, constant: -16),
        ])
        return card
    }

    private func buildDocsRow() -> UIControl {
        let card = CardControl()
        card.backgroundColor = FPColor.surface
        card.layer.cornerRadius = 16
        card.layer.borderWidth = 1
        card.layer.borderColor = FPColor.stroke.cgColor
        card.addTarget(self, action: #selector(openDocs), for: .touchUpInside)

        let iconView = UIImageView(image: UIImage(systemName: "book"))
        iconView.tintColor = FPColor.accent
        iconView.setContentHuggingPriority(.required, for: .horizontal)
        let label = UILabel()
        label.text = "Open the integration guide"
        label.font = .systemFont(ofSize: 15, weight: .medium)
        label.textColor = FPColor.text
        let chevron = UIImageView(image: UIImage(systemName: "chevron.right"))
        chevron.tintColor = FPColor.muted
        chevron.setContentHuggingPriority(.required, for: .horizontal)

        let row = UIStackView(arrangedSubviews: [iconView, label, chevron])
        row.axis = .horizontal
        row.spacing = 14
        row.alignment = .center
        row.isUserInteractionEnabled = false
        row.translatesAutoresizingMaskIntoConstraints = false
        card.addSubview(row)
        NSLayoutConstraint.activate([
            row.topAnchor.constraint(equalTo: card.topAnchor, constant: 16),
            row.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 16),
            row.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -16),
            row.bottomAnchor.constraint(equalTo: card.bottomAnchor, constant: -16),
        ])
        return card
    }

    private func iconBubble(_ systemName: String, tint: UIColor, background: UIColor) -> UIView {
        let container = UIView()
        container.backgroundColor = background
        container.layer.cornerRadius = 22
        container.translatesAutoresizingMaskIntoConstraints = false
        container.widthAnchor.constraint(equalToConstant: 44).isActive = true
        container.heightAnchor.constraint(equalToConstant: 44).isActive = true
        let image = UIImageView(image: UIImage(systemName: systemName))
        image.tintColor = tint
        image.contentMode = .scaleAspectFit
        image.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(image)
        NSLayoutConstraint.activate([
            image.centerXAnchor.constraint(equalTo: container.centerXAnchor),
            image.centerYAnchor.constraint(equalTo: container.centerYAnchor),
            image.widthAnchor.constraint(equalToConstant: 22),
            image.heightAnchor.constraint(equalToConstant: 22),
        ])
        return container
    }
}

/// A label with text insets, used for the status pill and the toast.
final class PaddedLabel: UILabel {
    var insets = UIEdgeInsets(top: 8, left: 14, bottom: 8, right: 14)
    override func drawText(in rect: CGRect) { super.drawText(in: rect.inset(by: insets)) }
    override var intrinsicContentSize: CGSize {
        let size = super.intrinsicContentSize
        return CGSize(width: size.width + insets.left + insets.right, height: size.height + insets.top + insets.bottom)
    }
    override func layoutSubviews() {
        super.layoutSubviews()
        let usable = bounds.width - insets.left - insets.right
        if usable > 0, preferredMaxLayoutWidth != usable {
            preferredMaxLayoutWidth = usable
            invalidateIntrinsicContentSize()
        }
    }
}

/// A tappable card that keeps its gradient (if any) sized to the layer.
final class CardControl: UIControl {
    private let gradient = CAGradientLayer()
    private var usesGradient = false

    override init(frame: CGRect) {
        super.init(frame: frame)
        gradient.startPoint = CGPoint(x: 0, y: 0)
        gradient.endPoint = CGPoint(x: 1, y: 1)
        layer.insertSublayer(gradient, at: 0)
    }
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    func setColors(_ colors: [UIColor]) {
        usesGradient = true
        gradient.colors = colors.map { $0.cgColor }
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        gradient.frame = bounds
        gradient.cornerRadius = layer.cornerRadius
        gradient.isHidden = !usesGradient
    }

    override var isHighlighted: Bool {
        didSet { alpha = isHighlighted ? 0.8 : (isEnabled ? 1 : 0.45) }
    }
}

/// A non-interactive gradient container (hero header).
final class GradientCard: UIView {
    private let gradient = CAGradientLayer()
    override init(frame: CGRect) {
        super.init(frame: frame)
        gradient.startPoint = CGPoint(x: 0, y: 0)
        gradient.endPoint = CGPoint(x: 1, y: 1)
        layer.insertSublayer(gradient, at: 0)
    }
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
    func setColors(_ colors: [UIColor]) { gradient.colors = colors.map { $0.cgColor } }
    override func layoutSubviews() {
        super.layoutSubviews()
        gradient.frame = bounds
        gradient.cornerRadius = layer.cornerRadius
    }
}
