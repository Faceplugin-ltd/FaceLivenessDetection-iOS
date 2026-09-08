import UIKit
import FaceLivenessKit

class SceneDelegate: UIResponder, UIWindowSceneDelegate {
    var window: UIWindow?

    func scene(
        _ scene: UIScene,
        willConnectTo session: UISceneSession,
        options connectionOptions: UIScene.ConnectionOptions
    ) {
        guard let windowScene = scene as? UIWindowScene else { return }
        let window = UIWindow(windowScene: windowScene)
        window.backgroundColor = FPColor.bg
        let nav = UINavigationController(rootViewController: ViewController())
        nav.view.backgroundColor = FPColor.bg
        window.rootViewController = nav
        window.tintColor = FPColor.accent
        window.overrideUserInterfaceStyle = .dark
        window.makeKeyAndVisible()
        self.window = window
    }
}

/// FaceLiveness-Android-App `colors.xml` / Material3 dark (`fp_*`, `btn_purple`, status).
enum FPColor {
    static let bg = UIColor(rgb: 0x1C1B1F)              // fp_bg / md_theme_dark_background
    static let text = UIColor(rgb: 0xE6E1E5)            // fp_text / onBackground
    static let muted = UIColor(rgb: 0x938F99)           // fp_muted / outline
    static let accent = UIColor(rgb: 0xD0BCFF)          // fp_accent / primary
    static let accentDim = UIColor(rgb: 0x4F378B)       // fp_accent_dim / primaryContainer
    static let purple = UIColor(rgb: 0x613D8E)          // btn_purple (home tiles)
    static let pinkTouch = UIColor(rgb: 0xBF41E3)       // pink_touch
    static let surface = UIColor(rgb: 0x252525)         // fp_surface / background1
    static let surfaceAlt = UIColor(rgb: 0x252525)      // cards
    static let stroke = UIColor(rgb: 0x2A3B55)          // fp_stroke
    static let statusInfo = UIColor(rgb: 0x1976D2)
    static let statusOk = UIColor(rgb: 0x388E3C)
    static let statusError = UIColor(rgb: 0xD32F2F)
    static let danger = UIColor(rgb: 0xFF6B6B)          // fp_danger
    static let overlay = UIColor(rgb: 0x0B1220).withAlphaComponent(0.80) // fp_overlay
    static let captureScrimStart = UIColor(rgb: 0x1C1B1F)
    static let captureScrimEnd = UIColor.black
    static let captureTertiary = UIColor(rgb: 0xEFB8C8) // md_theme_dark_tertiary
    static let livenessReal = UIColor(rgb: 0x2EE6A6)
    static let livenessSpoof = UIColor(rgb: 0xFF6B6B)
    static let livenessNeutral = UIColor.white
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

extension UIView {
    /// Android `bg_card.xml` — 16dp radius + 1dp stroke.
    func applyAndroidCardStyle(cornerRadius: CGFloat = 16) {
        backgroundColor = FPColor.surface
        layer.cornerRadius = cornerRadius
        layer.borderWidth = 1
        layer.borderColor = FPColor.stroke.cgColor
        clipsToBounds = true
    }
}

/// Shared nav bar so every pushed screen shows a labeled Back control.
enum ScreenChrome {
    static func showInnerBar(on viewController: UIViewController) {
        guard let navigationController = viewController.navigationController else { return }
        let appearance = UINavigationBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = FPColor.bg
        appearance.shadowColor = .clear
        appearance.titleTextAttributes = [
            .foregroundColor: FPColor.text,
            .font: UIFont.systemFont(ofSize: 17, weight: .semibold),
        ]
        let button = UIBarButtonItemAppearance()
        button.normal.titleTextAttributes = [.foregroundColor: FPColor.accent]
        appearance.buttonAppearance = button
        appearance.backButtonAppearance = button
        navigationController.navigationBar.standardAppearance = appearance
        navigationController.navigationBar.scrollEdgeAppearance = appearance
        navigationController.navigationBar.compactAppearance = appearance
        navigationController.navigationBar.tintColor = FPColor.accent
        navigationController.navigationBar.barStyle = .black
        viewController.navigationItem.largeTitleDisplayMode = .never
        navigationController.setNavigationBarHidden(false, animated: false)
    }
}
