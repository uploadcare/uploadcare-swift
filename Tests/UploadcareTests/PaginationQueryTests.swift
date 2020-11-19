//
//  PaginationQueryTests.swift
//  
//
//  Created by Sergey Armodin on 03.02.2020.
//  Copyright © 2020 Uploadcare, Inc. All rights reserved.
//

#if !os(watchOS)
import XCTest
@testable import Uploadcare

final class PaginationQueryTests: XCTestCase {
    func testOrderingInit() {
		let query1 = PaginationQuery()
			.removed(false)
			.stored(true)
			.limit(10)
		
		XCTAssertFalse(query1.removed!)
		XCTAssertTrue(query1.stored!)
		XCTAssertEqual(10, query1.limit!)
		
		let query2 = PaginationQuery().limit(30000)
		XCTAssertEqual(PaginationQuery.maxLimitValue, query2.limit!)
    }
	
	func testOrdering() {
		let date = Date(timeIntervalSince1970: 1580553107)
		let s1 = PaginationQuery.Ordering.dateTimeUploadedASC(from: date)
		let s2 = PaginationQuery.Ordering.sizeASC(from: 12909)
		
		XCTAssertEqual(s1.stringValue, "ordering=datetime_uploaded&from=2020-02-01T10:31:47")
		XCTAssertEqual(s2.stringValue, "ordering=size&from=12909")
	}

    static var allTests = [
        ("testOrderingInit", testOrderingInit),
    ]
}
#endif

