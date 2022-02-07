//
//  RESTAPIIntegrationTests.swift
//  
//
//  Created by Sergei Armodin on 01.02.2022.
//

#if !os(watchOS)
import XCTest
@testable import Uploadcare

final class RESTAPIIntegrationTests: XCTestCase {
    let uploadcare = Uploadcare(withPublicKey: "34067d5ea21379bebb1f", secretKey: "a7171736eb2800733bc0")

    func test1_listOfFiles_simple_authScheme() {
        let expectation = XCTestExpectation(description: "test1UploadFileFromURL")
        uploadcare.authScheme = .simple

        let query = PaginationQuery()
            .stored(true)
            .ordering(.sizeDESC)
            .limit(5)
        
        let filesList = uploadcare.listOfFiles()
        filesList.get(withQuery: query) { (list, error) in
            defer { expectation.fulfill() }
            if let error = error {
                XCTFail(error.detail)
                return
            }
            
            XCTAssertNotNil(list)
            XCTAssertFalse(list!.results.isEmpty)
        }

        wait(for: [expectation], timeout: 15.0)
    }
    
    func test2_listOfFiles_signed_authScheme() {
        let expectation = XCTestExpectation(description: "test1UploadFileFromURL")
        uploadcare.authScheme = .signed

        let query = PaginationQuery()
            .stored(true)
            .ordering(.sizeDESC)
            .limit(5)
        
        let filesList = uploadcare.listOfFiles()
        filesList.get(withQuery: query) { (list, error) in
            defer { expectation.fulfill() }
            if let error = error {
                XCTFail(error.detail)
                return
            }
            
            XCTAssertNotNil(list)
            XCTAssertFalse(list!.results.isEmpty)
        }

        wait(for: [expectation], timeout: 15.0)
    }
}

#endif

