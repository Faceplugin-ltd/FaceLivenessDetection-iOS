import CoreGraphics
import Foundation
import UIKit

/// Liveness detect params + merge of PB scores onto VideoWorker track boxes.
public enum LiveDetect {
    public static func livenessOnlyFlags(level: Int) -> FaceRecognitionDetectFlags {
        var flags: FaceRecognitionDetectFlags = [.liveness]
        if level == 0 {
            flags.insert(.livenessAccurate)
        }
        return flags
    }

    public static func mergePbDetect(_ track: [DetectedFace], pb: [DetectedFace]?) -> [DetectedFace] {
        guard let pb, !pb.isEmpty else { return track }
        return track.map { dst in
            guard let src = bestMatch(dst, pb) else { return dst }
            var extra: [String: FaceAttribute] = [:]
            if let attr = src.attributes["Liveness2D"] ?? src.attributes["liveness"] {
                extra["Liveness2D"] = attr
            }
            if let lum = src.attributes["Luminance"] ?? src.attributes["face_luminance"] {
                extra["Luminance"] = lum
            }
            let merged = extra.isEmpty ? dst : dst.mergingAttributes(extra)
            if src.luminance > 0, merged.luminance <= 0 {
                return DetectedFace(
                    faceId: merged.faceId,
                    region: merged.region,
                    attributes: merged.attributes,
                    yaw: merged.yaw,
                    pitch: merged.pitch,
                    roll: merged.roll,
                    landmarkCount: merged.landmarkCount,
                    landmarks: merged.landmarks,
                    luminance: src.luminance
                )
            }
            return merged
        }
    }

    /// Backward-compatible alias used by older call sites.
    public static func mergeLiveness(_ track: [DetectedFace], pb: [DetectedFace]?) -> [DetectedFace] {
        mergePbDetect(track, pb: pb)
    }

    private static func bestMatch(_ dst: DetectedFace, _ pb: [DetectedFace]) -> DetectedFace? {
        if pb.count == 1 { return pb[0] }
        var best: DetectedFace?
        var bestIou: CGFloat = 0.1
        for src in pb {
            let value = iou(dst.region, src.region)
            if value > bestIou {
                bestIou = value
                best = src
            }
        }
        return best ?? pb[0]
    }

    private static func iou(_ a: CGRect, _ b: CGRect) -> CGFloat {
        let inter = a.intersection(b)
        if inter.isNull || inter.isEmpty { return 0 }
        let union = a.width * a.height + b.width * b.height - inter.width * inter.height
        if union <= 0 { return 0 }
        return (inter.width * inter.height) / union
    }
}
