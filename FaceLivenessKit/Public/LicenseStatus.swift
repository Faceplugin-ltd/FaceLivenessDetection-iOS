import Foundation

/// License capabilities from `FaceRecognitionSDK.license()`.
///
/// Mirrors Android `face-liveness-kit/LicenseStatus`. The liveness tiles unlock when `liveness`
/// is granted (a "Liveness only" or "Recognition + Liveness" key).
public struct LicenseStatus: Equatable {
    public let licensed: Bool
    public let level: Int
    public let levelName: String
    public let recognition: Bool
    public let liveness: Bool
    public let label: String

    public static let notLicensed = LicenseStatus(
        licensed: false,
        level: -1,
        levelName: "None",
        recognition: false,
        liveness: false,
        label: "Not licensed"
    )

    public static func current() -> LicenseStatus {
        from(FaceRecognitionSDK.license())
    }

    public static func from(_ license: FaceRecognitionLicense) -> LicenseStatus {
        let raw = license.label
        return LicenseStatus(
            licensed: license.licensed,
            level: Int(license.level),
            levelName: license.levelName.isEmpty ? "None" : license.levelName,
            recognition: license.recognition,
            liveness: license.liveness,
            label: raw.isEmpty ? "Not licensed" : raw
        )
    }
}
