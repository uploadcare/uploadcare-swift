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

	func testWebhookJSONParsing() {
		let data = """
		{
				"id": 1736573,
				"created": "2023-07-31T23:01:11.438421Z",
				"updated": "2023-07-31T23:01:11.438438Z",
				"event": "file.uploaded",
				"target_url": "https://google.com/519",
				"project": 87170,
				"is_active": false,
				"signing_secret": "sss1",
				"version": ""
			}
		""".data(using: .utf8)!
		let decoder = JSONDecoder()

		do {
			_ = try decoder.decode(Webhook.self, from: data)
		} catch {
			XCTFail(String(describing: error))
		}
	}

	func testWebhookJSONParsingModerationStateChanged() {
		let data = """
		{
				"id": 1736574,
				"created": "2023-07-31T23:01:11.438421Z",
				"updated": "2023-07-31T23:01:11.438438Z",
				"event": "moderation.state_changed",
				"target_url": "https://google.com/520",
				"project": 87170,
				"is_active": true,
				"signing_secret": "sss2",
				"version": "0.7"
			}
		""".data(using: .utf8)!
		let decoder = JSONDecoder()

		do {
			let webhook = try decoder.decode(Webhook.self, from: data)
			XCTAssertEqual(webhook.event, .moderationStateChanged)
			XCTAssertEqual(webhook.version, .v0_7)
		} catch {
			XCTFail(String(describing: error))
		}
	}
}
