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
        let expectation = XCTestExpectation(description: "test3_listOfFiles_pagination")
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

        wait(for: [expectation], timeout: 20.0)
    }

    func test4_fileInfo_with_UUID() {
        let expectation = XCTestExpectation(description: "test4_fileInfo_with_UUID")

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

    func test5_delete_file() {
        let expectation = XCTestExpectation(description: "test5_delete_file")

        let url = URL(string: "https://source.unsplash.com/random")!
        let data = try! Data(contentsOf: url)

        DLog("size of file: \(sizeString(ofData: data))")


        uploadcare.uploadAPI.directUploadInForeground(files: ["random_file_name.jpg": data], store: .doNotStore, { (progress) in
            DLog("upload progress: \(progress * 100)%")
        }) { (resultDictionary, error) in

            if let error = error {
                XCTFail(error.detail)
                return
            }

            XCTAssertNotNil(resultDictionary)

            for file in resultDictionary! {
                let uuid = file.value

                self.uploadcare.deleteFile(withUUID: uuid) { file, error in
                    if let error = error {
                        XCTFail(error.detail)
                        return
                    }

                    XCTAssertEqual(uuid, file?.uuid)
                    expectation.fulfill()
                }
            }
        }

        wait(for: [expectation], timeout: 15.0)
    }

    func test6_batch_delete_files() {
        let expectation = XCTestExpectation(description: "test6_batch_delete_files")

        let url = URL(string: "https://source.unsplash.com/random")!
        let data = try! Data(contentsOf: url)

        DLog("size of file: \(sizeString(ofData: data))")


        uploadcare.uploadAPI.directUploadInForeground(files: ["random_file_name.jpg": data], store: .doNotStore, { (progress) in
            DLog("upload progress: \(progress * 100)%")
        }) { (resultDictionary, error) in

            if let error = error {
                XCTFail(error.detail)
                return
            }

            XCTAssertNotNil(resultDictionary)

            for file in resultDictionary! {
                let uuid = file.value
                self.uploadcare.deleteFiles(withUUIDs: [uuid, "shouldBeInProblems"]) { (response, error) in
                    if let error = error {
                        XCTFail(error.detail)
                        return
                    }

                    XCTAssertEqual(uuid, response?.result.first?.uuid)
                    XCTAssertNotNil(response?.problems["shouldBeInProblems"])
                    expectation.fulfill()
                }
            }
        }

        wait(for: [expectation], timeout: 20.0)
    }

    func test7_store_file() {
        let expectation = XCTestExpectation(description: "test7_store_file")

        let url = URL(string: "https://source.unsplash.com/random")!
        let data = try! Data(contentsOf: url)

        DLog("size of file: \(sizeString(ofData: data))")


        uploadcare.uploadAPI.directUploadInForeground(files: ["random_file_name.jpg": data], store: .doNotStore, { (progress) in
            DLog("upload progress: \(progress * 100)%")
        }) { (resultDictionary, error) in

            if let error = error {
                XCTFail(error.detail)
                return
            }

            XCTAssertNotNil(resultDictionary)

            for file in resultDictionary! {
                let uuid = file.value
                self.uploadcare.storeFile(withUUID: uuid) { file, error in
                    if let error = error {
                        XCTFail(error.detail)
                        return
                    }

                    XCTAssertNotNil(file)
                    XCTAssertEqual(uuid, file!.uuid)

                    // cleanup
                    self.uploadcare.deleteFile(withUUID: uuid) { _, _ in
                        expectation.fulfill()
                    }
                }
            }
        }

        wait(for: [expectation], timeout: 20.0)
    }

    func test8_batch_store_files() {
        let expectation = XCTestExpectation(description: "test8_batch_store_files")

        let url = URL(string: "https://source.unsplash.com/random")!
        let data = try! Data(contentsOf: url)

        DLog("size of file: \(sizeString(ofData: data))")


        uploadcare.uploadAPI.directUploadInForeground(files: ["random_file_name.jpg": data], store: .doNotStore, { (progress) in
            DLog("upload progress: \(progress * 100)%")
        }) { (resultDictionary, error) in

            if let error = error {
                XCTFail(error.detail)
                return
            }

            XCTAssertNotNil(resultDictionary)

            for file in resultDictionary! {
                let uuid = file.value
                self.uploadcare.storeFiles(withUUIDs: [uuid]) { response, error in
                    if let error = error {
                        XCTFail(error.detail)
                        return
                    }

                    XCTAssertEqual(uuid, response?.result.first?.uuid)

                    // cleanup
                    self.uploadcare.deleteFile(withUUID: uuid) { _, _ in
                        expectation.fulfill()
                    }
                }
            }
        }

        wait(for: [expectation], timeout: 20.0)
    }

    func test9_list_of_groups() {
        let expectation = XCTestExpectation(description: "test9_list_of_groups")

        let query = GroupsListQuery()
            .limit(100)
            .ordering(.datetimeCreatedDESC)

        uploadcare.listOfGroups(withQuery: query) { (list, error) in

            if let error = error {
                XCTFail(error.detail)
                return
            }

            XCTAssertNotNil(list)
            XCTAssertFalse(list!.results.isEmpty)

            expectation.fulfill()
        }

        wait(for: [expectation], timeout: 20.0)
    }

    func test10_list_of_groups_pagination() {
        let expectation = XCTestExpectation(description: "test10_list_of_groups_pagination")

        let query = GroupsListQuery()
            .limit(5)
            .ordering(.datetimeCreatedDESC)

        let groupsList = uploadcare.listOfGroups()

        DispatchQueue.global(qos: .utility).async {
            let semaphore = DispatchSemaphore(value: 0)
            groupsList.get(withQuery: query) { (list, error) in

                if let error = error {
                    XCTFail(error.detail)
                    return
                }

                XCTAssertNotNil(list)
                XCTAssertFalse(list!.results.isEmpty)
                XCTAssertNotNil(list!.next)
                XCTAssertFalse(list!.next!.isEmpty)

                semaphore.signal()
            }
            semaphore.wait()

            // get next page
            groupsList.nextPage { (list, error) in
                if let error = error {
                    print(error)
                    return
                }

                XCTAssertNotNil(list)
                XCTAssertFalse(list!.results.isEmpty)

                XCTAssertNotNil(list!.next)
                XCTAssertFalse(list!.next!.isEmpty)

                XCTAssertNotNil(list!.previous)
                XCTAssertFalse(list!.previous!.isEmpty)

                semaphore.signal()
            }
            semaphore.wait()

            // get previous page
            groupsList.previousPage { (list, error) in
                if let error = error {
                    print(error)
                    return
                }

                XCTAssertNotNil(list)
                XCTAssertFalse(list!.results.isEmpty)

                XCTAssertNotNil(list!.next)
                XCTAssertFalse(list!.next!.isEmpty)

                XCTAssertNil(list!.previous)

                semaphore.signal()
            }
            semaphore.wait()

            expectation.fulfill()
        }

        wait(for: [expectation], timeout: 20.0)
    }

    func test11_group_info() {
        let expectation = XCTestExpectation(description: "test11_group_info")

        let query = GroupsListQuery()
            .limit(100)
            .ordering(.datetimeCreatedDESC)

        uploadcare.listOfGroups(withQuery: query) { (list, error) in
            if let error = error {
                XCTFail(error.detail)
                return
            }

            XCTAssertFalse(list!.results.isEmpty)

            let uuid = list!.results.first!.id
            self.uploadcare.groupInfo(withUUID: uuid) { group, error in
                if let error = error {
                    XCTFail(error.detail)
                    return
                }

                XCTAssertEqual(uuid, group!.id)

                expectation.fulfill()
            }
        }

        wait(for: [expectation], timeout: 20.0)
    }

    func test12_store_group() {
        let expectation = XCTestExpectation(description: "test12_store_group")

        let query = GroupsListQuery()
            .limit(100)
            .ordering(.datetimeCreatedDESC)

        uploadcare.listOfGroups(withQuery: query) { (list, error) in
            if let error = error {
                XCTFail(error.detail)
                return
            }

            XCTAssertFalse(list!.results.isEmpty)

            let uuid = list!.results.first!.id
            self.uploadcare.storeGroup(withUUID: uuid) { (error) in
                if let error = error {
                    XCTFail(error.detail)
                    return
                }
                expectation.fulfill()
            }
        }

        wait(for: [expectation], timeout: 20.0)
    }

    func test13_copy_file_to_local_storage() {
        let expectation = XCTestExpectation(description: "test13_copy_file_to_local_storage")

        let url = URL(string: "https://source.unsplash.com/random")!
        let data = try! Data(contentsOf: url)

        DLog("size of file: \(sizeString(ofData: data))")

        uploadcare.uploadAPI.directUploadInForeground(files: ["random_file_name.jpg": data], store: .doNotStore, { (progress) in
            DLog("upload progress: \(progress * 100)%")
        }) { (resultDictionary, error) in

            if let error = error {
                XCTFail(error.detail)
                return
            }

            XCTAssertNotNil(resultDictionary)

            for file in resultDictionary! {
                let uuid = file.value
                self.uploadcare.copyFileToLocalStorage(source: uuid) { response, error in
                    if let error = error {
                        XCTFail(error.detail)
                        return
                    }

                    XCTAssertEqual("file", response!.type)

                    // cleanup
                    self.uploadcare.deleteFile(withUUID: uuid) { _, _ in
                        expectation.fulfill()
                    }
                }
            }
        }

        wait(for: [expectation], timeout: 20.0)
    }

    func test14_copy_file_to_remote_storage() {
        let expectation = XCTestExpectation(description: "test14_copy_file_to_remote_storage")

        let url = URL(string: "https://source.unsplash.com/random")!
        let data = try! Data(contentsOf: url)

        DLog("size of file: \(sizeString(ofData: data))")

        uploadcare.uploadAPI.directUploadInForeground(files: ["random_file_name.jpg": data], store: .doNotStore, { (progress) in
            DLog("upload progress: \(progress * 100)%")
        }) { (resultDictionary, error) in

            if let error = error {
                XCTFail(error.detail)
                return
            }

            XCTAssertNotNil(resultDictionary)

            for file in resultDictionary! {
                let uuid = file.value
                self.uploadcare.copyFileToLocalStorage(source: uuid) { response, error in
                    if let error = error {
                        XCTFail(error.detail)
                        return
                    }

                    XCTAssertEqual("file", response!.type)

                    // cleanup
                    self.uploadcare.deleteFile(withUUID: uuid) { _, _ in
                        expectation.fulfill()
                    }
                }

                self.uploadcare.copyFileToRemoteStorage(source: uuid, target: "one_more_project", pattern: .uuid) { (response, error) in
                    XCTAssertNotNil(error)
                    XCTAssertFalse(error!.detail == RESTAPIError.defaultError().detail)

                    // cleanup
                    self.uploadcare.deleteFile(withUUID: uuid) { _, _ in
                        expectation.fulfill()
                    }
                }
            }
        }

        wait(for: [expectation], timeout: 20.0)
    }

    func test15_get_project_info() {
        let expectation = XCTestExpectation(description: "test15_get_project_info")

        uploadcare.getProjectInfo { project, error in
            if let error = error {
                XCTFail(error.detail)
                return
            }

            XCTAssertFalse(project!.pubKey.isEmpty)
            XCTAssertFalse(project!.name.isEmpty)

            expectation.fulfill()
        }

        wait(for: [expectation], timeout: 20.0)
    }

    func test16_redirect_for_Authenticated_urls() {
        let expectation = XCTestExpectation(description: "test16_redirect_for_Authenticated_urls")

        let url = URL(string: "https://goo.gl/")!
        uploadcare.getAuthenticatedUrlFromUrl(url) { value, error in
            if let error = error {
                XCTFail(error.detail)
                return
            }

            XCTAssertFalse(value!.isEmpty)

            expectation.fulfill()
        }

        wait(for: [expectation], timeout: 20.0)
    }

    func test17_get_list_of_webhooks() {
        let expectation = XCTestExpectation(description: "test17_get_list_of_webhooks")

        uploadcare.getListOfWebhooks { webhooks, error in
            if let error = error {
                XCTFail(error.detail)
                return
            }

            XCTAssertFalse(webhooks!.isEmpty)

            expectation.fulfill()
        }

        wait(for: [expectation], timeout: 20.0)
    }

    func test18_create_webhook() {
        let expectation = XCTestExpectation(description: "test18_create_webhook")

        let random = (0...1000).randomElement()!
        let url = URL(string: "https://google.com/\(random)")!
        uploadcare.createWebhook(targetUrl: url, isActive: true, signingSecret: "sss1") { webhook, error in
            if let error = error {
                XCTFail(error.detail)
                return
            }

            XCTAssertEqual(url.absoluteString, webhook!.targetUrl)

            expectation.fulfill()
        }

        wait(for: [expectation], timeout: 20.0)
    }

    func test19_update_webhook() {
        let expectation = XCTestExpectation(description: "test19_update_webhook")

        let random = (0...1000).randomElement()!
        let url = URL(string: "https://apple.com/\(random)")!

        uploadcare.getListOfWebhooks { webhooks, error in
            if let error = error {
                XCTFail(error.detail)
                return
            }

            let webhook = webhooks!.first!

            self.uploadcare.updateWebhook(id: webhook.id, targetUrl: url, isActive: true, signingSecret: "sss2") { webhook, error in
                if let error = error {
                    XCTFail(error.detail)
                    return
                }

                XCTAssertEqual(url.absoluteString, webhook!.targetUrl)
                expectation.fulfill()
            }
        }

        wait(for: [expectation], timeout: 20.0)
    }
}

#endif

