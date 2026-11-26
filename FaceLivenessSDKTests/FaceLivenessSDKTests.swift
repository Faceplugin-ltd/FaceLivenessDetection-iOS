import XCTest
@testable import FaceLivenessSDK

final class FaceLivenessSDKTests: XCTestCase {
    func testAppSettingsDefaults() {
        AppSettings.restoreDefaults()
        XCTAssertTrue(AppSettings.useFrontCamera)
        // The passive gate and the active check share the engine's 0.5 operating point.
        XCTAssertEqual(AppSettings.livenessThreshold, 0.5, accuracy: 0.001)
    }

    func testActiveLivenessOptionsFromDefaults() {
        AppSettings.restoreDefaults()
        let options = AppSettings.activeLiveness()
        XCTAssertEqual(options.count, 3)
        XCTAssertTrue(options.randomize)
        XCTAssertEqual(options.livenessThreshold, 0.5, accuracy: 0.001)
        XCTAssertEqual(options.yawThreshold, 25, accuracy: 0.001)
        XCTAssertEqual(options.pitchThreshold, 15, accuracy: 0.001)
        XCTAssertEqual(options.pool, ActiveLivenessOptions.defaultPool)
    }

    func testUseFrontCameraBackLens() {
        AppSettings.restoreDefaults()
        AppSettings.useFrontCamera = false
        XCTAssertFalse(AppSettings.useFrontCamera)
        AppSettings.useFrontCamera = true
        XCTAssertTrue(AppSettings.useFrontCamera)
    }

    func testLivenessPassed() {
        AppSettings.restoreDefaults()
        XCTAssertFalse(AppSettings.livenessPassed(score: 0.99, label: "spoof"))
        XCTAssertFalse(AppSettings.livenessPassed(score: 0.99, label: "Fake"))
        XCTAssertTrue(AppSettings.livenessPassed(score: 0.5, label: "real"))
        XCTAssertFalse(AppSettings.livenessPassed(score: 0.49, label: nil))
    }

    func testActiveLivenessPlanLength() {
        var options = ActiveLivenessOptions()
        options.count = 3
        options.randomize = false
        XCTAssertEqual(options.buildPlan().count, 3)
        XCTAssertEqual(options.buildPlan(), Array(ActiveLivenessOptions.defaultPool.prefix(3)))
    }
}
