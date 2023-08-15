import XCTest
@testable import Uploadcare

final class UploadFromURLTaskTests: XCTestCase {
    func testInit_shouldHaveDefaultValues() {
		let task = UploadFromURLTask(sourceUrl: URL(string: "https://example.com/file.png")!)
		
		XCTAssertEqual(task.store, StoringBehavior.auto)
    }
}
