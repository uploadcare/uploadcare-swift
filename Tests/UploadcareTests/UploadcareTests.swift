import XCTest
@testable import Uploadcare

final class uploadcare_swiftTests: XCTestCase {
    func testInitWithPublicKey() {
		let letters = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
		let randomGeneratedKey = String((0..<10).map{ _ in letters.randomElement()! })
		
		
        let uploadcare = Uploadcare(withPublicKey: randomGeneratedKey)
		XCTAssertEqual(randomGeneratedKey, uploadcare.publicKey)
    }

    static var allTests = [
        ("testInitWithPublicKey", testInitWithPublicKey),
    ]
}
