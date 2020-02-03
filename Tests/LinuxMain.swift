import XCTest

import uploadcare_swiftTests

var tests = [XCTestCaseEntry]()
tests += uploadcare_swiftTests.allTests()
tests += UploadFromURLTaskTests.allTests()
tests += PaginationQueryTests.allTests()

XCTMain(tests)
