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
        let expectation = XCTestExpectation(description: "test1_listOfFiles_simple_authScheme")
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
        let expectation = XCTestExpectation(description: "test2_listOfFiles_signed_authScheme")
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

    func test3_listOfFiles_pagination() {
        let expectation = XCTestExpectation(description: "test2_listOfFiles_signed_authScheme")
        uploadcare.authScheme = .signed

        let query = PaginationQuery()
            .stored(true)
            .ordering(.dateTimeUploadedDESC)
            .limit(5)

        let filesList = uploadcare.listOfFiles()

        DispatchQueue.global(qos: .utility).async {
            let semaphore = DispatchSemaphore(value: 0)
            filesList.get(withQuery: query) { (list, error) in
                if let error = error {
                    XCTFail(error.detail)
                    return
                }

                XCTAssertNotNil(list)
                XCTAssertFalse(list!.results.isEmpty)
                semaphore.signal()
            }
            semaphore.wait()

            // get next page
            filesList.nextPage { (list, error) in
                if let error = error {
                    XCTFail(error.detail)
                    return
                }

                XCTAssertNotNil(list)
                XCTAssertFalse(list!.results.isEmpty)
                semaphore.signal()
            }
            semaphore.wait()

            // get previous page
            filesList.previousPage { (list, error) in
                if let error = error {
                    XCTFail(error.detail)
                    return
                }

                XCTAssertNotNil(list)
                XCTAssertFalse(list!.results.isEmpty)
                semaphore.signal()
            }
            semaphore.wait()
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: 150.0)
    }

    func test4_fileInfo_with_UUID() {
        let expectation = XCTestExpectation(description: "test3_fileInfo_with_UUID")

        // get any file from list of files
        let query = PaginationQuery().limit(1)
        let filesList = uploadcare.listOfFiles()
        filesList.get(withQuery: query) { (list, error) in
            if let error = error {
                XCTFail(error.detail)
                return
            }

            XCTAssertNotNil(list)
            XCTAssertNotNil(list!.results.first)

            // get file info by file UUID
            let uuid = list!.results.first!.uuid
            self.uploadcare.fileInfo(withUUID: uuid) { (file, error) in
                defer { expectation.fulfill() }

                if let error = error {
                    XCTFail(error.detail)
                    return
                }

                XCTAssertNotNil(file)
                XCTAssertEqual(uuid, file?.uuid)
            }
        }

        wait(for: [expectation], timeout: 15.0)
    }
}

#endif

