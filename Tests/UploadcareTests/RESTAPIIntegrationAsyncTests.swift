//
//  RESTAPIIntegrationAsyncTests.swift
//  
//
//  Created by Sergei Armodin on 02.06.2023.
//

import Foundation
import XCTest
@testable import Uploadcare

@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
final class RESTAPIIntegrationAsyncTests: XCTestCase {
//	let uploadcare = Uploadcare(withPublicKey: "demopublickey", secretKey: "demopublickey")
	let uploadcare = Uploadcare(withPublicKey: String(cString: getenv("UPLOADCARE_PUBLIC_KEY")), secretKey: String(cString: getenv("UPLOADCARE_SECRET_KEY")))
	var timer: Timer?

	func test01_listOfFiles_simple_authScheme() async throws {
		uploadcare.authScheme = .simple

		let query = PaginationQuery()
			.stored(true)
			.ordering(.dateTimeUploadedDESC)
			.limit(5)

		let filesList = uploadcare.listOfFiles()
		let list = try await filesList.get(withQuery: query)
		XCTAssertFalse(list.results.isEmpty)
	}

	func test02_listOfFiles_signed_authScheme() async throws {
		uploadcare.authScheme = .signed

		let query = PaginationQuery()
			.stored(true)
			.ordering(.dateTimeUploadedDESC)
			.limit(5)

		let filesList = uploadcare.listOfFiles()
		let list = try await filesList.get(withQuery: query)
		XCTAssertFalse(list.results.isEmpty)
	}

	func test03_listOfFiles_pagination() async throws {
		uploadcare.authScheme = .signed

		let query = PaginationQuery()
			.stored(true)
			.ordering(.dateTimeUploadedDESC)
			.limit(5)

		let filesList = uploadcare.listOfFiles()

		try await filesList.get(withQuery: query)
		XCTAssertFalse(filesList.results.isEmpty)
		let firstID = filesList.results.first!.uuid

		// get next page
		try await filesList.nextPage()
		XCTAssertFalse(filesList.results.isEmpty)
		XCTAssertFalse(firstID == filesList.results.first!.uuid)

		// get previous page
		try await filesList.previousPage()
		XCTAssertFalse(filesList.results.isEmpty)
		XCTAssertTrue(firstID == filesList.results.first!.uuid)
	}

	func test04_fileInfo_with_UUID() async throws {
		// get any file from list of files
		let query = PaginationQuery().limit(1)
		let filesList = uploadcare.listOfFiles()

		let list = try await filesList.get(withQuery: query)

		// get file info by file UUID
		let uuid = list.results.first!.uuid

		let fileInfoQuery = FileInfoQuery().include(.appdata)
		let file = try await uploadcare.fileInfo(withUUID: uuid, withQuery: fileInfoQuery)
		XCTAssertEqual(uuid, file.uuid)
	}

	func test05_delete_file() async throws {
		let url = URL(string: "https://source.unsplash.com/featured")!
		let data = try! Data(contentsOf: url)

		DLog("size of file: \(sizeString(ofData: data))")

		let resultDictionary = try await uploadcare.uploadAPI.directUploadInForeground(files: ["random_file_name.jpg": data], store: .doNotStore)
		guard let uuid = resultDictionary.values.first else {
			XCTFail()
			return
		}
		let file = try await uploadcare.deleteFile(withUUID: uuid)
		XCTAssertEqual(uuid, file.uuid)
	}

	func test06_batch_delete_files() async throws {
		let url = URL(string: "https://source.unsplash.com/featured")!
		let data = try! Data(contentsOf: url)

		DLog("size of file: \(sizeString(ofData: data))")

		let resultDictionary = try await uploadcare.uploadAPI.directUploadInForeground(files: ["random_file_name.jpg": data], store: .doNotStore)
		guard let uuid = resultDictionary.values.first else {
			XCTFail()
			return
		}

		let response = try await uploadcare.deleteFiles(withUUIDs: [uuid, "shouldBeInProblems"])
		XCTAssertEqual(uuid, response.result.first?.uuid)
		XCTAssertNotNil(response.problems["shouldBeInProblems"])
	}

	func test07_store_file() async throws {
		let url = URL(string: "https://source.unsplash.com/featured")!
		let data = try! Data(contentsOf: url)

		DLog("size of file: \(sizeString(ofData: data))")

		let resultDictionary = try await uploadcare.uploadAPI.directUploadInForeground(files: ["random_file_name.jpg": data], store: .doNotStore)
		guard let uuid = resultDictionary.values.first else {
			XCTFail()
			return
		}

		let file = try await uploadcare.storeFile(withUUID: uuid)
		XCTAssertEqual(uuid, file.uuid)

		// cleanup
		try await uploadcare.deleteFile(withUUID: uuid)
	}

	func test08_batch_store_files() async throws {
		let url = URL(string: "https://source.unsplash.com/featured")!
		let data = try! Data(contentsOf: url)

		DLog("size of file: \(sizeString(ofData: data))")

		let resultDictionary = try await uploadcare.uploadAPI.directUploadInForeground(files: ["random_file_name.jpg": data], store: .doNotStore)
		guard let uuid = resultDictionary.values.first else {
			XCTFail()
			return
		}

		let response = try await uploadcare.storeFiles(withUUIDs: [uuid])
		XCTAssertEqual(uuid, response.result.first?.uuid)

		// cleanup
		try await uploadcare.deleteFile(withUUID: uuid)
	}

	func test09_list_of_groups() async throws {
		let query = GroupsListQuery()
			.limit(100)
			.ordering(.datetimeCreatedDESC)

		let list = try await uploadcare.listOfGroups(withQuery: query)
		XCTAssertFalse(list.results.isEmpty)
	}

	func test10_list_of_groups_pagination() async throws {
		let query = GroupsListQuery()
			.limit(5)
			.ordering(.datetimeCreatedDESC)

		let groupsList = uploadcare.listOfGroups()

		let list = try await groupsList.get(withQuery: query)
		XCTAssertFalse(list.results.isEmpty)
		XCTAssertNotNil(list.next)
		XCTAssertFalse(list.next!.isEmpty)

		// get next page
		let next = try await groupsList.nextPage()
		XCTAssertFalse(next.results.isEmpty)

		XCTAssertNotNil(next.next)
		XCTAssertFalse(next.next!.isEmpty)

		XCTAssertNotNil(next.previous)
		XCTAssertFalse(next.previous!.isEmpty)

		// get previous page
		let prev = try await groupsList.previousPage()
		XCTAssertFalse(prev.results.isEmpty)

		XCTAssertNotNil(prev.next)
		XCTAssertFalse(prev.next!.isEmpty)

		XCTAssertNil(prev.previous)

		XCTAssertEqual(prev.results, list.results)
	}

	func test11_group_info() async throws {
		let query = GroupsListQuery()
			.limit(100)
			.ordering(.datetimeCreatedDESC)

		let list = try await uploadcare.listOfGroups(withQuery: query)
		XCTAssertFalse(list.results.isEmpty)

		let uuid = list.results.first!.id
		let group = try await uploadcare.groupInfo(withUUID: uuid)
		XCTAssertEqual(uuid, group.id)
	}

	func test13_copy_file_to_local_storage() async throws {
		let url = URL(string: "https://source.unsplash.com/featured")!
		let data = try! Data(contentsOf: url)

		DLog("size of file: \(sizeString(ofData: data))")

		let resultDictionary = try await uploadcare.uploadAPI.directUploadInForeground(files: ["random_file_name.jpg": data], store: .doNotStore)
		guard let uuid = resultDictionary.values.first else {
			XCTFail()
			return
		}

		try await Task.sleep(nanoseconds: 5 * NSEC_PER_SEC)

		let response = try await uploadcare.copyFileToLocalStorage(source: uuid)
		XCTAssertEqual("file", response.type)

		// cleanup
		try await uploadcare.deleteFile(withUUID: uuid)
	}

	func test14_copy_file_to_remote_storage() async throws {
		let url = URL(string: "https://source.unsplash.com/featured")!
		let data = try! Data(contentsOf: url)

		DLog("size of file: \(sizeString(ofData: data))")

		let resultDictionary = try await uploadcare.uploadAPI.directUploadInForeground(files: ["random_file_name.jpg": data], store: .doNotStore)
		guard let uuid = resultDictionary.values.first else {
			XCTFail()
			return
		}

		do {
			_ = try await uploadcare.copyFileToRemoteStorage(source: uuid, target: "one_more_project", pattern: .uuid)
			XCTFail("should fail")
		} catch {
			let error = error as! RESTAPIError
			XCTAssertFalse(error.detail == RESTAPIError.defaultError().detail)
		}
	}

	func test15_get_project_info() async throws {
		let project = try await uploadcare.getProjectInfo()
		XCTAssertFalse(project.pubKey.isEmpty)
		XCTAssertFalse(project.name.isEmpty)
	}

	func test16_redirect_for_Authenticated_urls() async throws {
		let url = URL(string: "https://goo.gl/")!
		let value = try await uploadcare.getAuthenticatedUrlFromUrl(url)
		XCTAssertFalse(value.isEmpty)
	}

	func test17_get_list_of_webhooks() async throws {
		let webhooks = try await uploadcare.getListOfWebhooks()
		XCTAssertFalse(webhooks.isEmpty)
	}

	func test18_create_update_delete_webhook() async throws {
		let url = URL(string: "https://uploadcare.com/\(NSUUID().uuidString)")!

		var webhook = try await uploadcare.createWebhook(targetUrl: url, event: .fileUploaded, isActive: true, signingSecret: "sss1")
		XCTAssertEqual(url.absoluteString, webhook.targetUrl)
		XCTAssertTrue(webhook.isActive)
		XCTAssertEqual(Webhook.Event.fileUploaded, webhook.event)

		let url2 = URL(string: "https://uploadcare.com/\(UUID().uuidString)")!
		webhook = try await uploadcare.updateWebhook(id: webhook.id, targetUrl: url2, event: .fileInfoUpdated, isActive: false, signingSecret: "sss2")
		XCTAssertEqual(url2.absoluteString, webhook.targetUrl)
		XCTAssertEqual(Webhook.Event.fileInfoUpdated, webhook.event)
		XCTAssertFalse(webhook.isActive)

		let targetUrl = URL(string: webhook.targetUrl)!
		try await uploadcare.deleteWebhook(forTargetUrl: targetUrl)
	}

	func test19_document_conversion_and_status() async throws {
		let url = URL(string: "https://source.unsplash.com/featured")!
		let data = try! Data(contentsOf: url)
		DLog("size of file: \(sizeString(ofData: data))")

		// upload random image
		let resultDictionary = try await uploadcare.uploadAPI.directUploadInForeground(files: ["random_file_name.jpg": data], store: .doNotStore)
		guard let uuid = resultDictionary.values.first else {
			XCTFail()
			return
		}

		let file = try await uploadcare.fileInfo(withUUID: uuid)

		try await Task.sleep(nanoseconds: 4 * NSEC_PER_SEC)

		let convertSettings = DocumentConversionJobSettings(forFile: file)
			.format(.png)

		let response = try await uploadcare.convertDocumentsWithSettings([convertSettings], saveInGroup: true)
		XCTAssertTrue(response.problems.isEmpty)

		let job = response.result.first!

		// check status
		let status = try await uploadcare.documentConversionJobStatus(token: job.token)
		XCTAssertFalse(status.statusString.isEmpty)

		// cleanup
		try await Task.sleep(nanoseconds: 5 * NSEC_PER_SEC)
		try await uploadcare.deleteFile(withUUID: job.uuid)
	}

	func test20_video_conversion_and_status() async throws {
		let query = PaginationQuery()
			.stored(true)
			.ordering(.dateTimeUploadedDESC)
			.limit(100)

		let list = try await uploadcare.listOfFiles(withQuery: query)

		let videoFile = list.results.first(where: { $0.mimeType == "video/mp4" || $0.mimeType == "video/quicktime" })!

		let convertSettings = VideoConversionJobSettings(forFile: videoFile)
			.format(.webm)
			.size(VideoSize(width: 640, height: 480))
			.resizeMode(.addPadding)
			.quality(.lightest)
			.cut( VideoCut(startTime: "0:0:5.000", length: "15") )

		let response = try await uploadcare.convertVideosWithSettings([convertSettings])

		XCTAssertTrue(response.problems.isEmpty)

		guard let job = response.result.first else {
			XCTFail()
			return
		}

		func check() async throws {
			let statusResponse = try await uploadcare.videoConversionJobStatus(token: job.token)

			XCTAssertFalse(statusResponse.statusString.isEmpty)

			DLog(statusResponse.statusString)

			switch statusResponse.status {
			case .finished, .failed(_):
				// cleanup
				let group = try await uploadcare.groupInfo(withUUID: statusResponse.result!.thumbnailsGroupUUID)
				var ids = group.files!.map { $0.uuid }
				ids.append(job.uuid)

				try await uploadcare.deleteFiles(withUUIDs: ids)
			default:
				try await Task.sleep(nanoseconds: 2 * NSEC_PER_SEC)
				try await check()
			}
		}

		try await check()
	}

//	var storingTestTask: UploadTaskable?
//	func test21_storing_shoudBeStored() {
//		let expectation = XCTestExpectation(description: "test21_storing_shoudBeStored")
//
//		let url = URL(string: "https://source.unsplash.com/featured")!
//		let data = try! Data(contentsOf: url)
//		let file = uploadcare.file(fromData: data)
//		let name = UUID().uuidString
//
//		storingTestTask = file.upload(withName: name, store: .doNotStore, uploadSignature: nil) { _ in
//
//		} _: { result in
//			switch result {
//			case .failure(let error):
//				XCTFail(error.debugDescription)
//			case .success(let file):
//				XCTAssertEqual(file.isStored, true)
//
//				self.uploadcare.deleteFile(withUUID: file.uuid) { _ in
//					expectation.fulfill()
//				}
//			}
//		}
//
//		wait(for: [expectation], timeout: 20.0)
//	}

	func test22_fileMetadata() async throws {
		uploadcare.authScheme = .simple

		// get any file from list of files
		let query = PaginationQuery().limit(1)
		let filesList = uploadcare.listOfFiles()

		let list = try await filesList.get(withQuery: query)
		let uuid = list.results.first!.uuid
		let expectedValue = NSUUID().uuidString

		// update
		let val = try await uploadcare.updateFileMetadata(withUUID: uuid, key: "myMeta", value: expectedValue)
		XCTAssertEqual(val, expectedValue)

		// value by key
		let value = try await uploadcare.fileMetadataValue(forKey: "myMeta", withUUID: uuid)
		XCTAssertEqual(value, expectedValue)

		// get metadata for file
		let metadata = try await uploadcare.fileMetadata(withUUID: uuid)
		XCTAssertFalse(metadata.isEmpty)
		XCTAssertEqual(metadata["myMeta"], expectedValue)

		// delete metadata
		try await uploadcare.deleteFileMetadata(forKey: "myMeta", withUUID: uuid)
	}

	func test23_aws_recognition_execute_and_status() async throws {
		// get any file from list of files
		let query = PaginationQuery().limit(100)
		let filesList = uploadcare.listOfFiles()

		let list = try await filesList.get(withQuery: query)
		guard let uuid = list.results.filter({ $0.isImage }).first?.uuid else {
			XCTFail()
			return
		}

		let response = try await uploadcare.executeAWSRecognition(fileUUID: uuid)

		// check status
		let status = try await uploadcare.checkAWSRecognitionStatus(requestID: response.requestID)
		XCTAssertTrue(status != .unknown)
	}

	func test24_clamav_execute_and_status() async throws {
		// get any file from list of files
		let query = PaginationQuery().limit(1)
		let filesList = uploadcare.listOfFiles()

		let list = try await filesList.get(withQuery: query)
		guard let uuid = list.results.first?.uuid else {
			XCTFail("Could not finish test: empty files list")
			return
		}

		let parameters = ClamAVAddonExecutionParams(purgeInfected: true)
		let response = try await uploadcare.executeClamav(fileUUID: uuid, parameters: parameters)

		// check status
		let status = try await uploadcare.checkClamAVStatus(requestID: response.requestID)
		XCTAssertTrue(status != .unknown)
	}

	func test25_removeBG_execute_and_status() async throws {
		// get any file from list of files
		let query = PaginationQuery().limit(100)
		let filesList = uploadcare.listOfFiles()

		let list = try await filesList.get(withQuery: query)
		guard let uuid = list.results.filter({ $0.isImage }).first?.uuid else {
			XCTFail()
			return
		}

		let parameters = RemoveBGAddonExecutionParams(crop: true, typeLevel: .two)
		let response = try await uploadcare.executeRemoveBG(fileUUID: uuid, parameters: parameters)

		// check status
		let status = try await uploadcare.checkRemoveBGStatus(requestID: response.requestID)
		XCTAssertTrue(status.status != .unknown)
	}

	func test26_aws_recognition_moderation_execute_and_status() async throws {
		// get any file from list of files
		let query = PaginationQuery().limit(100)
		let filesList = uploadcare.listOfFiles()

		let list = try await filesList.get(withQuery: query)
		guard let uuid = list.results.filter({ $0.isImage }).first?.uuid else {
			XCTFail()
			return
		}

		let response = try await uploadcare.executeAWSRekognitionModeration(fileUUID: uuid)
		DLog(response)

		// check status
		let status = try await uploadcare.checkAWSRekognitionModerationStatus(requestID: response.requestID)
		XCTAssertTrue(status != .unknown)
	}

}
