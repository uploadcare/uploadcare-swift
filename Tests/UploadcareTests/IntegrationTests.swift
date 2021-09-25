//
//  File.swift
//  
//
//  Created by Sergei Armodin on 25.09.2021.
//

#if !os(watchOS)
import XCTest
@testable import Uploadcare

final class IntegrationTests: XCTestCase {
	let uploadcare = Uploadcare(withPublicKey: "demopublickey", secretKey: "demopublickey")

	func delay(_ delay: Double, closure: @escaping ()->()) {
		DispatchQueue.main.asyncAfter(
			deadline: DispatchTime.now() + Double(Int64(delay * Double(NSEC_PER_SEC))) / Double(NSEC_PER_SEC), execute: closure)
	}

	func DLog(
		_ messages: Any...,
		fullPath: String = #file,
		line: Int = #line,
		functionName: String = #function
	) {
		let file = URL(fileURLWithPath: fullPath)
		for message in messages {
			#if DEBUG
			let string = "\(file.pathComponents.last!):\(line) -> \(functionName): \(message)"
			print(string)
			#endif
		}
	}

	func testUploadFileFromURL() {
		let expectation = XCTestExpectation(description: "testUploadFileFromURL")

		// upload from url
		let url = URL(string: "https://source.unsplash.com/random")!
		let task = UploadFromURLTask(sourceUrl: url)
			.checkURLDuplicates(true)
			.saveURLDuplicates(true)
			.filename("file_from_url")
			.store(.store)

		uploadcare.uploadAPI.upload(task: task) { [unowned self] (result, error) in
			if let error = error {
				XCTFail(error.detail)
			}

			XCTAssertNotNil(result)

			DLog(result!)

			guard let token = result?.token else {
				expectation.fulfill()
				return
			}

			delay(1.0) { [unowned self] in
				self.uploadcare.uploadAPI.uploadStatus(forToken: token) { (status, error) in
					if let error = error {
						XCTFail(error.detail)
					}
					XCTAssertNotNil(status)
					DLog(status!)
					expectation.fulfill()
				}
			}

		}

		wait(for: [expectation], timeout: 10.0)
	}

}

#endif
