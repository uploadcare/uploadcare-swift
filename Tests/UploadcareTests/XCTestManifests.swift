import XCTest

#if !canImport(ObjectiveC)
public func allTests() -> [XCTestCaseEntry] {
    return [
        testCase(uploadcare_swiftTests.allTests),
    ]
}
#endif
