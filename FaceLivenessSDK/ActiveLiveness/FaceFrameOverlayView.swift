import UIKit

/// Active-liveness palette, ported from Android `fp_al_colors.xml`. Prefixed so it cannot collide
/// with the home screen's `FPColor`.
enum FPAL {
    static let scrim = UIColor(white: 0, alpha: 0.70)       // #B3000000
    static let glass = UIColor(white: 1, alpha: 0.30)       // #4DFFFFFF
    static let overlay = UIColor(rgb: 0x06060A, alpha: 0.80) // #CC06060A
    static let surface = UIColor(rgb: 0x14141D)
    static let stroke = UIColor(rgb: 0x262635)
    static let text = UIColor(rgb: 0xF2F0F7)
    static let muted = UIColor(rgb: 0x9B96AC)
    static let accent = UIColor(rgb: 0x7C5CFF)
    static let accentDeep = UIColor(rgb: 0x4A2BB5)
    static let accentDim = UIColor(rgb: 0x2A2140)
    static let ring = UIColor(rgb: 0x2EE6C8)
    static let pass = UIColor(rgb: 0x2EE6A6)
    static let fail = UIColor(rgb: 0xE5484D)
    static let track = UIColor(white: 1, alpha: 0.20)       // 0x33FFFFFF
    static let pendingDot = UIColor(white: 1, alpha: 0.25)  // 0x40FFFFFF
}

/// Camera scrim with an oval cut-out for the face, plus the progress ring the active-liveness
/// sequence fills in. The cut-out is also the target the user is asked to fill, so `faceFrame` is
/// exposed for laying text out underneath it.
///
/// Mirrors Android `face-liveness-active/FaceFrameOverlayView`.
final class FaceFrameOverlayView: UIView {

    private let scrimLayer = CAShapeLayer()
    private let edgeLayer = CAShapeLayer()
    private let trackLayer = CAShapeLayer()
    private let progressLayer = CAShapeLayer()
    private let haloLayer = CAShapeLayer()

    private var oval: CGRect = .zero
    private var ring: CGRect = .zero
    private var progress: CGFloat = 0

    /// Oval the face should fill, in this view's coordinates.
    var faceFrame: CGRect { oval }

    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }

    private func setup() {
        backgroundColor = .clear
        isUserInteractionEnabled = false

        scrimLayer.fillRule = .evenOdd
        scrimLayer.fillColor = FPAL.scrim.cgColor

        edgeLayer.fillColor = UIColor.clear.cgColor
        edgeLayer.strokeColor = FPAL.glass.cgColor
        edgeLayer.lineWidth = 1.5

        trackLayer.fillColor = UIColor.clear.cgColor
        trackLayer.strokeColor = FPAL.track.cgColor
        trackLayer.lineWidth = 5
        trackLayer.lineCap = .round

        progressLayer.fillColor = UIColor.clear.cgColor
        progressLayer.strokeColor = FPAL.ring.cgColor
        progressLayer.lineWidth = 5
        progressLayer.lineCap = .round
        progressLayer.strokeEnd = 0

        haloLayer.fillColor = UIColor.clear.cgColor
        haloLayer.strokeColor = UIColor.clear.cgColor
        haloLayer.lineWidth = 14
        haloLayer.opacity = 0

        [scrimLayer, edgeLayer, trackLayer, progressLayer, haloLayer].forEach { layer.addSublayer($0) }
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        layoutFrame(bounds.size)
    }

    private func layoutFrame(_ size: CGSize) {
        let w = size.width, h = size.height
        guard w > 0, h > 0 else { return }
        let width = min(w * 0.74, h * 0.52)
        let height = width * 1.30
        let cx = w / 2
        let cy = h * 0.42
        oval = CGRect(x: cx - width / 2, y: cy - height / 2, width: width, height: height)
        let inset: CGFloat = 9
        ring = oval.insetBy(dx: -inset, dy: -inset)

        CATransaction.begin()
        CATransaction.setDisableActions(true)

        let scrimPath = UIBezierPath(rect: bounds)
        scrimPath.append(UIBezierPath(ovalIn: oval))
        scrimLayer.path = scrimPath.cgPath
        edgeLayer.path = UIBezierPath(ovalIn: oval).cgPath

        let ringPath = Self.ellipsePath(ring)
        trackLayer.path = ringPath
        progressLayer.path = ringPath
        haloLayer.path = UIBezierPath(ovalIn: ring).cgPath

        CATransaction.commit()
    }

    /// A full ellipse starting at the top (−90°) and sweeping clockwise, so `strokeEnd` fills from
    /// the top like Android's `drawArc(-90, 360)`.
    private static func ellipsePath(_ rect: CGRect) -> CGPath {
        let unit = UIBezierPath(
            arcCenter: .zero,
            radius: 1,
            startAngle: -.pi / 2,
            endAngle: .pi * 1.5,
            clockwise: true
        )
        var transform = CGAffineTransform(scaleX: rect.width / 2, y: rect.height / 2)
            .concatenating(CGAffineTransform(translationX: rect.midX, y: rect.midY))
        return unit.cgPath.copy(using: &transform) ?? unit.cgPath
    }

    /// Ring fill, 0–1.
    func setProgress(_ value: CGFloat, animated: Bool = true) {
        let target = min(max(value, 0), 1)
        progress = target
        CATransaction.begin()
        if animated {
            CATransaction.setAnimationDuration(0.26)
            CATransaction.setAnimationTimingFunction(CAMediaTimingFunction(name: .easeOut))
        } else {
            CATransaction.setDisableActions(true)
        }
        progressLayer.strokeEnd = target
        CATransaction.commit()
    }

    func setAccentColor(_ color: UIColor) {
        progressLayer.strokeColor = color.cgColor
    }

    /// One soft pulse around the frame — used when a challenge is completed.
    func pulse(_ color: UIColor) {
        haloLayer.strokeColor = color.cgColor
        let animation = CABasicAnimation(keyPath: "opacity")
        animation.fromValue = 0.55
        animation.toValue = 0
        animation.duration = 0.62
        haloLayer.add(animation, forKey: "pulse")
    }
}
