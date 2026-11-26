import UIKit
import FaceLivenessKit

/// Face boxes and the passive-liveness read-out, drawn over the camera preview.
///
/// Mirrors Android `ui/FaceView`: a rounded box per face coloured by the anti-spoofing verdict,
/// with a Liveness / Quality / Pose block above it.
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
        guard !faces.isEmpty, frameSize.width > 0, frameSize.height > 0,
              let ctx = UIGraphicsGetCurrentContext() else { return }
        let viewW = bounds.width, viewH = bounds.height
        let frameW = frameSize.width, frameH = frameSize.height
        guard viewW > 0, viewH > 0 else { return }

        // Preview is aspect-fill, so the frame is scaled up and cropped the same way.
        let scale = max(viewW / frameW, viewH / frameH)
        let dx = (viewW - frameW * scale) / 2
        let dy = (viewH - frameH * scale) / 2

        for face in faces {
            var left = mapX(face.bounds.minX, scale: scale, dx: dx, viewW: viewW)
            var right = mapX(face.bounds.maxX, scale: scale, dx: dx, viewW: viewW)
            if left > right { swap(&left, &right) }
            let top = face.bounds.minY * scale + dy
            let bottom = face.bounds.maxY * scale + dy

            let known = face.hasLiveness
            let live = known && AppSettings.livenessPassed(score: face.liveness, label: face.livenessLabel)
            let color: UIColor = !known ? FPColor.livenessNeutral : (live ? FPColor.livenessReal : FPColor.livenessSpoof)

            let box = CGRect(x: left, y: top, width: right - left, height: bottom - top)
            let corner = min(box.width, box.height) * 0.22
            let path = UIBezierPath(roundedRect: box, cornerRadius: corner)
            ctx.setStrokeColor(color.cgColor)
            ctx.setLineWidth(4)
            ctx.setLineJoin(.round)
            path.stroke()

            drawInfoBlock(face: face, box: box, live: live, known: known)
        }
    }

    private func drawInfoBlock(face: DetectedFace, box: CGRect, live: Bool, known: Bool) {
        let lines = buildLines(face: face, live: live, known: known)
        let font = UIFont.systemFont(ofSize: 13, weight: .medium)
        let attrs: [NSAttributedString.Key: Any] = [.font: font, .foregroundColor: UIColor.white]
        let padX: CGFloat = 10, padY: CGFloat = 7
        let lineH = font.lineHeight * 1.25
        var maxWidth: CGFloat = 0
        for line in lines {
            maxWidth = max(maxWidth, (line as NSString).size(withAttributes: attrs).width)
        }
        let blockW = maxWidth + padX * 2
        let blockH = CGFloat(lines.count) * lineH + padY * 2
        var left = box.minX
        var top = box.minY - blockH - 8
        if top < 4 { top = min(box.minY + 8, bounds.height - blockH - 4) }
        if left + blockW > bounds.width - 4 { left = max(4, bounds.width - blockW - 4) }

        let bg = UIBezierPath(roundedRect: CGRect(x: left, y: top, width: blockW, height: blockH), cornerRadius: 14)
        UIColor(white: 0, alpha: 0.70).setFill()
        bg.fill()

        var textY = top + padY
        for line in lines {
            (line as NSString).draw(at: CGPoint(x: left + padX, y: textY), withAttributes: attrs)
            textY += lineH
        }
    }

    private func buildLines(face: DetectedFace, live: Bool, known: Bool) -> [String] {
        var lines: [String] = []
        if known {
            lines.append(String(format: "Liveness : %@ %d%%", live ? "Real" : "Spoof", percent(face.liveness)))
        } else {
            lines.append("Liveness : —")
        }
        lines.append(String(format: "Quality : %d%%", percent(face.quality.isNaN ? face.score : face.quality)))
        if face.hasPose {
            lines.append(String(format: "Pose : %.0f° / %.0f°", face.yaw, face.pitch))
        } else {
            lines.append("Pose : —")
        }
        return lines
    }

    private func percent(_ value: Float) -> Int {
        value.isNaN ? 0 : Int((min(max(value, 0), 1) * 100).rounded())
    }

    private func mapX(_ frameX: CGFloat, scale: CGFloat, dx: CGFloat, viewW: CGFloat) -> CGFloat {
        let vx = frameX * scale + dx
        return mirror ? viewW - vx : vx
    }
}
