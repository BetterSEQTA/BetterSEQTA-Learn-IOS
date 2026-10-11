import Data
import XCTest

final class FixturePresenceTests: XCTestCase {
    func testDataModuleDocumentsFixtureLocation() {
        XCTAssertFalse(DataModule.fixtureBundleDescription.isEmpty)
    }
}
