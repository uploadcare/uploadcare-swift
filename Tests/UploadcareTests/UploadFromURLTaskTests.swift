//
//  UploadFromURLTaskTests.swift
//  
//
//  Created by Sergey Armodin on 25.01.2020.
//

import XCTest
@testable import Uploadcare

final class UploadFromURLTaskTests: XCTestCase {
    func testInit_shouldHaveDefaultValues() {
		let task = UploadFromURLTask(sourceUrl: URL(string: "https://example.com/file.png")!)
		
		XCTAssertEqual(task.store, UploadFromURLTask.StoringBehavior.auto)
    }

    static var allTests = [
        ("testInit_shouldHaveDefaultValues", testInit_shouldHaveDefaultValues),
    ]
}


