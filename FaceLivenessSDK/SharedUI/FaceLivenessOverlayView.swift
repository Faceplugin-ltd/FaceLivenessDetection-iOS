import UIKit
import FaceLivenessKit

/// Android `FaceView` — per-face TrackID / Liveness / Luminance / Score.
final class FaceLivenessOverlayView: UIView {
    private var frameSize: CGSize = .zero
    private var faces: [DetectedFace] = []
    private var mirror = true

    override init(frame: CGRect) {
        super.init(frame: frame)
        isOpaque = false
        backgroundColor = .clear
        contentMode = .redraw
    }

    required init?(coder: NSCoder) { nil }

    func update(faces: [DetectedFace], frameSize: CGSize, mirror: Bool) {
        self.faces = faces
        self.frameSize = frameSize
        self.mirror = mirror
        setNeedsDisplay()
    }

    override func draw(_ rect: CGRect) {
        guard frameSize.width > 0, frameSize.height > 0 else { return }
        let bounds = self.bounds

        for face in faces {
            guard let box = FaceJSON.mapRectToOverlay(
                face.boxRect,
                frameSize: frameSize,
                overlayBounds: bounds,
                mirror: mirror
            ) else { continue }

            let livenessKnown = hasLiveness(face)
            let live = livenessKnown && AppSettings.livenessPassed(
                score: face.livenessScore,
                label: face.livenessLabel
            )
            let color: UIColor
            if !livenessKnown {
                color = UIColor.cyan
            } else if live {
                color = UIColor.green
            } else {
                color = UIColor.red
            }

            guard let ctx = UIGraphicsGetCurrentContext() else { continue }
            ctx.setStrokeColor(color.cgColor)
            ctx.setLineWidth(4)
            ctx.stroke(box)

            drawInfoBlock(ctx: ctx, face: face, box: box, live: live, livenessKnown: livenessKnown, color: color)

            ctx.setFillColor(color.cgColor)
            let landmarks = FaceJSON.mapPointsToOverlay(
                face.landmarks,
                frameSize: frameSize,
                overlayBounds: bounds,
                mirror: mirror
            )
            let r: CGFloat = 2.5
            for pt in landmarks {
                ctx.fillEllipse(in: CGRect(x: pt.x - r, y: pt.y - r, width: r * 2, height: r * 2))
            }
        }
    }

    private func drawInfoBlock(
        ctx: CGContext,
        face: DetectedFace,
        box: CGRect,
        live: Bool,
        livenessKnown: Bool,
        color: UIColor
    ) {
        let lines = buildLines(face: face, live: live, livenessKnown: livenessKnown)
        let font = UIFont.boldSystemFont(ofSize: 13)
        let attrs: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: UIColor.white,
        ]
        let padX: CGFloat = 8
        let padY: CGFloat = 6
        let lineH = font.lineHeight * 1.15
        var maxWidth: CGFloat = 0
        for line in lines {
            maxWidth = max(maxWidth, (line as NSString).size(withAttributes: attrs).width)
        }
        let blockW = maxWidth + padX * 2
        let blockH = CGFloat(lines.count) * lineH + padY * 2
        var left = box.minX
        var top = box.minY - blockH - 6
        if top < 4 {
            top = min(box.minY + 6, bounds.height - blockH - 4)
        }
        if left + blockW > bounds.width - 4 {
            left = max(4, bounds.width - blockW - 4)
        }

        ctx.setFillColor(UIColor(white: 0, alpha: 0.6).cgColor)
        ctx.fill(CGRect(x: left, y: top, width: blockW, height: blockH))

        var textY = top + padY
        for line in lines {
            (line as NSString).draw(at: CGPoint(x: left + padX, y: textY), withAttributes: attrs)
            textY += lineH
        }
        _ = color
    }

    private func buildLines(face: DetectedFace, live: Bool, livenessKnown: Bool) -> [String] {
        var lines: [String] = []
        lines.append(String(format: "TrackID : %d", max(0, face.faceId)))

        if livenessKnown {
            let verdict = live ? "Real" : "Spoof"
            let pct = Int((max(0, min(1, face.livenessScore)) * 100).rounded())
            lines.append(String(format: "Liveness : %@ %d%%", verdict, pct))
        } else {
            lines.append("Liveness : —")
        }

        let lum = face.faceLuminance
        if lum > 0.001 {
            let pct = Int((max(0, min(1, lum)) * 100).rounded())
            lines.append(String(format: "Luminance : %d%%", pct))
        } else {
            lines.append("Luminance : —")
        }

        var score = face.faceQualityScore
        if score < 0.001 { score = face.livenessScore }
        if score >= 0.001 {
            let pct = Int((max(0, min(1, score)) * 100).rounded())
            lines.append(String(format: "Score %d%%", pct))
        } else {
            lines.append("Score —")
        }
        return lines
    }

    private func hasLiveness(_ face: DetectedFace) -> Bool {
        if let label = face.livenessLabel, !label.isEmpty { return true }
        return face.livenessScore > 0.001
    }
}
