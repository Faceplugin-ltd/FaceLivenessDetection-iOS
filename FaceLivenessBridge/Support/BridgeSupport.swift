import AVFoundation
import UIKit

/// Small shims the screens expect from their host app.
///
/// This framework compiles the *same* source files the FaceLivenessSDK app does — the
/// ActiveLiveness group, the camera base and the passive overlay — rather than copies of them, so
/// the two cannot drift. Those files reference a handful of things that live in the app target
/// rather than in `FaceLivenessKit`: the palette, a padded label, the nav chrome and the
/// lens/threshold preference. This file supplies them under the same names, which is what lets the
/// screens come across unchanged.
///
/// The one behavioural difference from the app is deliberate: the app's `AppSettings` reads
/// `UserDefaults`, and a framework has no business owning a host's preferences. Here they are
/// plain static values that `FPLLiveness` writes just before it presents a screen.
enum ScreenChrome {
    /// The app shows a labelled Back control on pushed screens. The bridge presents its screens
    /// modally, with their own close buttons, so there is no navigation bar to style.
    static func showInnerBar(on viewController: UIViewController) {
        viewController.navigationController?.setNavigationBarHidden(true, animated: false)
    }
}

/// The lens and score threshold the host passed in for this presentation.
enum AppSettings {
    static var useFrontCamera: Bool = true

    static var cameraPosition: AVCaptureDevice.Position { useFrontCamera ? .front : .back }

    /// Lowest score that counts as a live face.
    static var livenessThreshold: Float = 0.5

    /// The same rule the app applies: a spoof label wins over any score.
    static func livenessPassed(score: Float, label: String?) -> Bool {
        let lower = (label ?? "").lowercased()
        if lower.contains("spoof") || lower.contains("fake") { return false }
        return score >= livenessThreshold
    }
}

/// Passive-liveness verdict colours, matching the app's `liveness_*` palette.
enum FPColor {
    static let livenessReal = UIColor(rgb: 0x2EE6A6)
    static let livenessSpoof = UIColor(rgb: 0xFF6B6B)
    static let livenessNeutral = UIColor.white
}

/// A label with text insets, used for the passive screen's title and hint pills.
final class PaddedLabel: UILabel {
    var insets = UIEdgeInsets(top: 8, left: 14, bottom: 8, right: 14)

    override func drawText(in rect: CGRect) {
        super.drawText(in: rect.inset(by: insets))
    }

    override var intrinsicContentSize: CGSize {
        let size = super.intrinsicContentSize
        return CGSize(
            width: size.width + insets.left + insets.right,
            height: size.height + insets.top + insets.bottom
        )
    }
}

extension UIColor {
    convenience init(rgb: UInt32, alpha: CGFloat = 1) {
        self.init(
            red: CGFloat((rgb >> 16) & 0xFF) / 255,
            green: CGFloat((rgb >> 8) & 0xFF) / 255,
            blue: CGFloat(rgb & 0xFF) / 255,
            alpha: alpha
        )
    }
}
