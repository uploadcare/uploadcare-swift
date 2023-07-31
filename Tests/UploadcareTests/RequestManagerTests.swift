//
//  RequestManagerTests.swift
//  
//
//  Created by Sergei Armodin on 05.09.2022.
//  Copyright © 2022 Uploadcare, Inc. All rights reserved.
//

import XCTest
@testable import Uploadcare

final class RequestManagerTests: XCTestCase {
	func testRequestMethod() {
		let requestsManager = RequestManager(publicKey: "123", secretKey: "123")

		let urlString = "https://uploadcare.com"
		let url = URL(string: urlString)!
		let request = requestsManager.makeUrlRequest(fromURL: url, method: RequestManager.HTTPMethod.put)

		XCTAssertEqual(request.httpMethod, "PUT")
	}
}
