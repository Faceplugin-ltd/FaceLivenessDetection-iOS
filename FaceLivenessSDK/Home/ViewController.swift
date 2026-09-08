import UIKit
import FaceLivenessKit

/// Android `MainActivity` / `activity_main.xml` — logo, title, Liveness/Settings/About tiles, status.
final class ViewController: UIViewController {
    /// `FP1.…` from FacePlugin for bundle id `com.faceplugin.facelivenessdk` (product 1000).
    private let licenseKey =
        "FP1.RlBMMQMAAQASR/8KSL077W41P1kMAgAAeO7xq/Xl9I9RNUeW4pnmgceT4iFnB+TD8L9TLjv/sMFVSjIdVCrozc1SwyhqssZ0EKH7kkLlU3zvAMC7Xpo8wkXKpY7RDmOjTkeArkBQZLzMclidnMZbpWIR41ibyzDpx5iKRMLGl682MdlD5IquD9eqzd6UbQMzHOq2g6HioUbvwyX+pWZcu2Qd8oA6XSFj7sCACjxTeYv6bL0FMFF7coN+Cq3olfFo35SrX98cnPxmShbxlRw1bMUKNLHa2veFnHTlajJU4arOArKaXYQdZOEAYpMKJ7S6LVU+5raMj9uhOK0ZRdTi5YFpn5QjP7nYEk9QzNr3MRJaet1QC6dg8C9EDhIEihN867TLj9LjERMMrxANAboJ5f4eGaoo9xmFUNsdlSddEthXGBQDQVPYRR/ASx0XetPTgMvf+UrBoTGpV3s/h/hqSAjYFRSFBoq2PWgXypn1WNNvek3884fi1ROKCJdAp3F9LWG7fulICMOPhfO7UP31JiAkufGQHmJiVuwgBmPgPw//wg6O/V0MZAaNUsKe254he9Iqh7fDuqoapkaiZeN4ayHwvAz+plT0Xg/IIBVKA3r8wYxrn6Bv7tQ0nKiexb2TFQuP7nnmkG91oQxU2j4q2LAVeGmvU1X2WWtGkFCXP1LKs40vT4zbZCXiS8xTIGg7bAPimJa2HT/LdxbxrzB5uReoySyLADCBiAJCAN5t4UUmEa7GTXPJJQTLCBUWAxAS45ZVX+Gvl/NfD8cBDuot2X21yi2ii8C8KhawBXpK+lNM9v2+j7j2WjazqHV1AkIB2fbWuTH6G98Fej+s5TtDOI+wKKFcdWXz9+Osxk2yWEiSd5ohBshk0WGS92oOqsIbOSqphrnel16T5DjbLjuPl3s="

    private let warningLabel = UILabel()
    private var sdkReady = false
    private var sdkActionButtons: [UIButton] = []

    override func viewDidLoad() {
        super.viewDidLoad()
        AppSettings.applyEngineDefaults()
        view.backgroundColor = FPColor.bg
        navigationItem.backBarButtonItem = UIBarButtonItem(title: "Back", style: .plain, target: nil, action: nil)
        navigationController?.setNavigationBarHidden(true, animated: false)
        setupUI()
        activateSDK()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: animated)
    }

    private func setupUI() {
        let logo = UIButton(type: .custom)
        logo.setImage(UIImage(named: "FacePluginLogo")?.withRenderingMode(.alwaysOriginal), for: .normal)
        logo.imageView?.contentMode = .scaleAspectFit
        logo.accessibilityLabel = "FacePlugin"
        logo.addTarget(self, action: #selector(openBrand), for: .touchUpInside)

        let titleLabel = UILabel()
        titleLabel.text = "Face Liveness"
        titleLabel.textColor = FPColor.text
        titleLabel.font = .systemFont(ofSize: 20, weight: .regular)
        titleLabel.textAlignment = .center

        let tiles = [
            ("LIVENESS", "identify", #selector(openLiveness)),
            ("SETTINGS", "settings", #selector(openSettings)),
            ("ABOUT", "information", #selector(openAbout)),
        ]
        let buttons = tiles.map { makeTile(title: $0.0, assetName: $0.1, action: $0.2) }
        sdkActionButtons = [buttons[0]]
        setSdkActionsEnabled(false)
        let row = tileRow(buttons)

        warningLabel.text = "Loading native SDK…"
        warningLabel.textColor = FPColor.text
        warningLabel.font = .systemFont(ofSize: 14, weight: .medium)
        warningLabel.textAlignment = .center
        warningLabel.backgroundColor = FPColor.statusInfo
        warningLabel.layer.cornerRadius = 8
        warningLabel.clipsToBounds = true
        warningLabel.numberOfLines = 2

        let content = UIStackView(arrangedSubviews: [logo, titleLabel, row])
        content.axis = .vertical
        content.alignment = .center
        content.spacing = 16
        content.setCustomSpacing(28, after: titleLabel)
        content.translatesAutoresizingMaskIntoConstraints = false

        let scroll = UIScrollView()
        scroll.alwaysBounceVertical = true
        scroll.translatesAutoresizingMaskIntoConstraints = false
        scroll.addSubview(content)
        warningLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(scroll)
        view.addSubview(warningLabel)

        logo.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            warningLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            warningLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            warningLabel.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -16),
            warningLabel.heightAnchor.constraint(greaterThanOrEqualToConstant: 44),

            scroll.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scroll.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scroll.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scroll.bottomAnchor.constraint(equalTo: warningLabel.topAnchor, constant: -12),

            content.topAnchor.constraint(equalTo: scroll.contentLayoutGuide.topAnchor, constant: 36),
            content.leadingAnchor.constraint(equalTo: scroll.contentLayoutGuide.leadingAnchor, constant: 16),
            content.trailingAnchor.constraint(equalTo: scroll.contentLayoutGuide.trailingAnchor, constant: -16),
            content.bottomAnchor.constraint(equalTo: scroll.contentLayoutGuide.bottomAnchor, constant: -16),
            content.widthAnchor.constraint(equalTo: scroll.frameLayoutGuide.widthAnchor, constant: -32),

            logo.widthAnchor.constraint(equalToConstant: 120),
            logo.heightAnchor.constraint(equalToConstant: 120),
            row.heightAnchor.constraint(equalToConstant: 112),
            row.widthAnchor.constraint(equalTo: content.widthAnchor),
        ])
    }

    private func tileRow(_ tiles: [UIView]) -> UIStackView {
        let row = UIStackView()
        row.axis = .horizontal
        row.spacing = 12
        row.distribution = .fillEqually
        for tile in tiles {
            row.addArrangedSubview(tile)
        }
        return row
    }

    private func makeTile(title: String, assetName: String, action: Selector) -> UIButton {
        let button = HomeTileButton(title: title, assetName: assetName)
        button.addTarget(self, action: action, for: .touchUpInside)
        button.addTarget(self, action: #selector(tileTouchDown(_:)), for: .touchDown)
        button.addTarget(self, action: #selector(tileTouchUp(_:)), for: [.touchUpInside, .touchUpOutside, .touchCancel])
        return button
    }

    @objc private func tileTouchDown(_ sender: UIButton) {
        UIView.animate(withDuration: 0.08) { sender.alpha = 0.75 }
    }

    @objc private func tileTouchUp(_ sender: UIButton) {
        UIView.animate(withDuration: 0.12) { sender.alpha = 1 }
    }

    private func setSdkActionsEnabled(_ enabled: Bool) {
        for button in sdkActionButtons {
            button.isEnabled = enabled
            button.alpha = enabled ? 1 : 0.45
        }
    }

    private func activateSDK() {
        FaceLivenessClient.shared.activate(license: licenseKey) { [weak self] code in
            guard let self else { return }
            self.sdkReady = code == 0
            if self.sdkReady {
                let label = FaceLivenessClient.shared.getLicenseStatus().label
                self.warningLabel.text = label.isEmpty ? "Ready" : "Ready · \(label)"
                self.warningLabel.backgroundColor = FPColor.statusOk
                self.setSdkActionsEnabled(true)
            } else {
                self.warningLabel.text = self.licenseMessage(code)
                self.warningLabel.backgroundColor = FPColor.statusError
                self.setSdkActionsEnabled(false)
            }
        }
    }

    private func licenseMessage(_ code: Int) -> String {
        switch code {
        case 1: return "License invalid"
        case 2: return "License expired"
        case 3: return "SDK not activated"
        case 4: return "Init failed"
        default: return "SDK failed: \(code)"
        }
    }

    private func ensureReady() -> Bool {
        if sdkReady { return true }
        let alert = UIAlertController(title: nil, message: "SDK not ready", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
        return false
    }

    @objc private func openLiveness() {
        guard ensureReady() else { return }
        navigationController?.pushViewController(LivenessCameraViewController(), animated: true)
    }

    @objc private func openSettings() {
        navigationController?.pushViewController(SettingsViewController(), animated: true)
    }

    @objc private func openAbout() {
        navigationController?.pushViewController(AboutViewController(), animated: true)
    }

    @objc private func openBrand() {
        if let url = URL(string: "https://faceplugin.com") {
            UIApplication.shared.open(url)
        }
    }
}

/// Android home tile (`bg_btn_purple`, 112dp, bold 12sp caption).
private final class HomeTileButton: UIButton {
    private let iconView = UIImageView()
    private let caption = UILabel()

    init(title: String, assetName: String) {
        super.init(frame: .zero)
        backgroundColor = FPColor.purple
        layer.cornerRadius = 16
        clipsToBounds = true

        iconView.image = UIImage(named: assetName)?.withRenderingMode(.alwaysOriginal)
        iconView.contentMode = .scaleAspectFit
        iconView.isUserInteractionEnabled = false

        caption.text = title
        caption.textColor = FPColor.text
        caption.font = .systemFont(ofSize: 12, weight: .bold)
        caption.textAlignment = .center
        caption.adjustsFontSizeToFitWidth = true
        caption.minimumScaleFactor = 0.75
        caption.isUserInteractionEnabled = false

        let stack = UIStackView(arrangedSubviews: [iconView, caption])
        stack.axis = .vertical
        stack.alignment = .center
        stack.spacing = 8
        stack.isUserInteractionEnabled = false
        stack.translatesAutoresizingMaskIntoConstraints = false
        addSubview(stack)
        NSLayoutConstraint.activate([
            stack.centerXAnchor.constraint(equalTo: centerXAnchor),
            stack.centerYAnchor.constraint(equalTo: centerYAnchor),
            stack.leadingAnchor.constraint(greaterThanOrEqualTo: leadingAnchor, constant: 4),
            stack.trailingAnchor.constraint(lessThanOrEqualTo: trailingAnchor, constant: -4),
            iconView.widthAnchor.constraint(equalToConstant: 36),
            iconView.heightAnchor.constraint(equalToConstant: 36),
        ])
    }

    required init?(coder: NSCoder) { nil }
}
