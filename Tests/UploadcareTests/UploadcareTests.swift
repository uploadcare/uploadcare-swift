#if !os(watchOS)
import XCTest
@testable import Uploadcare

final class uploadcare_swiftTests: XCTestCase {
	func testInitWithKeys() {
		let letters = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
		let randomGeneratedPublicKey = String((0..<10).map{ _ in letters.randomElement()! })
		let randomGeneratedSecretKey = String((0..<10).map{ _ in letters.randomElement()! })
		
		
		let uploadcare = Uploadcare(withPublicKey: randomGeneratedPublicKey, secretKey: randomGeneratedSecretKey)
		XCTAssertEqual(randomGeneratedPublicKey, uploadcare.publicKey)
		XCTAssertEqual(randomGeneratedSecretKey, uploadcare.secretKey)
	}
	
	func testRequestMethod() {
		let uploadcare = Uploadcare(withPublicKey: "123", secretKey: "123")
		
		let urlString = "https://uploadcare.com"
		let url = URL(string: urlString)!
		let request = uploadcare.makeUrlRequest(fromURL: url, method: RequestManager.HTTPMethod.put)
		
		XCTAssertEqual(request.httpMethod, "PUT")
	}
}
#endif
