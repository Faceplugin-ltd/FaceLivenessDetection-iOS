import Foundation

/// Parsed FaceLivenessSDK.getLicenseStatus JSON.
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
        fromJson(FaceLivenessSDK.getLicenseStatus())
    }

    public static func fromJson(_ json: String?) -> LicenseStatus {
        guard let data = json?.data(using: .utf8),
              let obj = try? JSONSerialization.jsonObject(with: data) as? [String: Any]
        else {
            return .notLicensed
        }
        return LicenseStatus(
            licensed: obj["licensed"] as? Bool ?? false,
            level: obj["level"] as? Int ?? -1,
            levelName: obj["levelName"] as? String ?? "None",
            recognition: obj["recognition"] as? Bool ?? false,
            liveness: obj["liveness"] as? Bool ?? false,
            label: {
                let raw = obj["label"] as? String ?? ""
                return raw.isEmpty ? "Not licensed" : raw
            }()
        )
    }
}
