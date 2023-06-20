//
//  RESTAPIIntegrationAsyncTests.swift
//  
//
//  Created by Sergei Armodin on 02.06.2023.
//

import Foundation

#if !os(watchOS)
import XCTest
@testable import Uploadcare

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

		let list = try await filesList.get(withQuery: query)
		XCTAssertFalse(list.results.isEmpty)

		// get next page
		let next = try await filesList.nextPage()
		XCTAssertFalse(next.results.isEmpty)

		// get previous page
		let prev = try await filesList.previousPage()
		XCTAssertFalse(prev.results.isEmpty)
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
		let url = URL(string: "https://source.unsplash.com/random")!
		let data = try! Data(contentsOf: url)

		DLog("size of file: \(sizeString(ofData: data))")

		let resultDictionary = try await uploadcare.uploadAPI.directUploadInForeground(files: ["random_file_name.jpg": data], store: .doNotStore)
		let uuid = resultDictionary.values.first!
		let file = try await uploadcare.deleteFile(withUUID: uuid)
		XCTAssertEqual(uuid, file.uuid)
	}

	func test06_batch_delete_files() async throws {
		let url = URL(string: "https://source.unsplash.com/random")!
		let data = try! Data(contentsOf: url)

		DLog("size of file: \(sizeString(ofData: data))")

		let resultDictionary = try await uploadcare.uploadAPI.directUploadInForeground(files: ["random_file_name.jpg": data], store: .doNotStore)
		let uuid = resultDictionary.values.first!

		let response = try await uploadcare.deleteFiles(withUUIDs: [uuid, "shouldBeInProblems"])
		XCTAssertEqual(uuid, response.result.first?.uuid)
		XCTAssertNotNil(response.problems["shouldBeInProblems"])
	}

//	func test07_store_file() {
//		let expectation = XCTestExpectation(description: "test7_store_file")
//
//		let url = URL(string: "https://source.unsplash.com/random")!
//		let data = try! Data(contentsOf: url)
//
//		DLog("size of file: \(sizeString(ofData: data))")
//
//
//		uploadcare.uploadAPI.directUploadInForeground(files: ["random_file_name.jpg": data], store: .doNotStore, { (progress) in
//			DLog("upload progress: \(progress * 100)%")
//		}) { result in
//			switch result {
//			case .failure(let error):
//				XCTFail(error.detail)
//				expectation.fulfill()
//			case .success(let resultDictionary):
//				let uuid = resultDictionary.values.first!
//				self.uploadcare.storeFile(withUUID: uuid) { result in
//					switch result {
//					case .failure(let error):
//						XCTFail(error.detail)
//						expectation.fulfill()
//					case .success(let file):
//						XCTAssertEqual(uuid, file.uuid)
//
//						// cleanup
//						self.uploadcare.deleteFile(withUUID: uuid) { _ in
//							expectation.fulfill()
//						}
//					}
//				}
//			}
//		}
//
//		wait(for: [expectation], timeout: 20.0)
//	}
//
//	func test08_batch_store_files() {
//		let expectation = XCTestExpectation(description: "test8_batch_store_files")
//
//		let url = URL(string: "https://source.unsplash.com/random")!
//		let data = try! Data(contentsOf: url)
//
//		DLog("size of file: \(sizeString(ofData: data))")
//
//
//		uploadcare.uploadAPI.directUploadInForeground(files: ["random_file_name.jpg": data], store: .doNotStore, { (progress) in
//			DLog("upload progress: \(progress * 100)%")
//		}) { result in
//			switch result {
//			case .failure(let error):
//				XCTFail(error.detail)
//				expectation.fulfill()
//			case .success(let resultDictionary):
//				let uuid = resultDictionary.values.first!
//				self.uploadcare.storeFiles(withUUIDs: [uuid]) { result in
//					switch result {
//					case .failure(let error):
//						XCTFail(error.detail)
//						expectation.fulfill()
//					case .success(let response):
//						XCTAssertEqual(uuid, response.result.first?.uuid)
//
//						// cleanup
//						self.uploadcare.deleteFile(withUUID: uuid) { _ in
//							expectation.fulfill()
//						}
//					}
//				}
//			}
//		}
//
//		wait(for: [expectation], timeout: 20.0)
//	}
//
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
//
//	func test13_copy_file_to_local_storage() {
//		let expectation = XCTestExpectation(description: "test13_copy_file_to_local_storage")
//
//		let url = URL(string: "https://source.unsplash.com/random")!
//		let data = try! Data(contentsOf: url)
//
//		DLog("size of file: \(sizeString(ofData: data))")
//
//		uploadcare.uploadAPI.directUploadInForeground(files: ["random_file_name.jpg": data], store: .doNotStore, { (progress) in
//			DLog("upload progress: \(progress * 100)%")
//		}) { result in
//			switch result {
//			case .failure(let error):
//				XCTFail(error.detail)
//				expectation.fulfill()
//			case .success(let resultDictionary):
//				let uuid = resultDictionary.values.first!
//				delay(5) {
//					self.uploadcare.copyFileToLocalStorage(source: uuid) { result in
//						switch result {
//						case .failure(let error):
//							XCTFail(error.detail)
//							expectation.fulfill()
//						case .success(let response):
//							XCTAssertEqual("file", response.type)
//
//							// cleanup
//							self.uploadcare.deleteFile(withUUID: uuid) { _ in
//								expectation.fulfill()
//							}
//						}
//					}
//				}
//			}
//		}
//
//		wait(for: [expectation], timeout: 25.0)
//	}
//
//	func test14_copy_file_to_remote_storage() {
//		let expectation = XCTestExpectation(description: "test14_copy_file_to_remote_storage")
//
//		let url = URL(string: "https://source.unsplash.com/random")!
//		let data = try! Data(contentsOf: url)
//
//		DLog("size of file: \(sizeString(ofData: data))")
//
//		uploadcare.uploadAPI.directUploadInForeground(files: ["random_file_name.jpg": data], store: .doNotStore, { (progress) in
//			DLog("upload progress: \(progress * 100)%")
//		}) { result in
//			switch result {
//			case .failure(let error):
//				XCTFail(error.detail)
//				expectation.fulfill()
//			case .success(let resultDictionary):
//				let uuid = resultDictionary.values.first!
//				self.uploadcare.copyFileToRemoteStorage(source: uuid, target: "one_more_project", pattern: .uuid) { result in
//					switch result {
//					case .failure(let error):
//						XCTAssertFalse(error.detail == RESTAPIError.defaultError().detail)
//					case .success(_):
//						XCTFail("should fail")
//					}
//
//					// cleanup
//					self.uploadcare.deleteFile(withUUID: uuid) { _ in
//						expectation.fulfill()
//					}
//				}
//			}
//		}
//
//		wait(for: [expectation], timeout: 20.0)
//	}

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
		let random = (0...1000).randomElement()!
		let url = URL(string: "https://google.com/\(random)")!

		var webhook = try await uploadcare.createWebhook(targetUrl: url, isActive: true, signingSecret: "sss1")
		XCTAssertEqual(url.absoluteString, webhook.targetUrl)
		XCTAssertTrue(webhook.isActive)

		let random2 = (0...1000).randomElement()!
		let url2 = URL(string: "https://google.com/\(random2)")!

		webhook = try await uploadcare.updateWebhook(id: webhook.id, targetUrl: url2, isActive: false, signingSecret: "sss2")
		XCTAssertEqual(url2.absoluteString, webhook.targetUrl)
		XCTAssertFalse(webhook.isActive)

		let targetUrl = URL(string: webhook.targetUrl)!
		try await uploadcare.deleteWebhook(forTargetUrl: targetUrl)
	}
//
//	func test19_document_conversion_and_status() {
//		let expectation = XCTestExpectation(description: "test19_document_conversion_and_status")
//
//		let url = URL(string: "https://source.unsplash.com/random")!
//		let data = try! Data(contentsOf: url)
//
//		DLog("size of file: \(sizeString(ofData: data))")
//
//		// upload random image
//		uploadcare.uploadAPI.directUploadInForeground(files: ["file_for_conversion.jpg": data], store: .doNotStore, { (progress) in
//			DLog("upload progress: \(progress * 100)%")
//		}) { result in
//			switch result {
//			case .failure(let error):
//				XCTFail(error.detail)
//				expectation.fulfill()
//			case .success(let resultDictionary):
//				// fileinfo
//				let uuid = resultDictionary.values.first!
//				self.uploadcare.fileInfo(withUUID: uuid) { result in
//					switch result {
//					case .failure(let error):
//						XCTFail(error.detail)
//						expectation.fulfill()
//					case .success(let file):
//						delay(4) {
//							let convertSettings = DocumentConversionJobSettings(forFile: file)
//								.format(.png)
//
//							self.uploadcare.convertDocumentsWithSettings([convertSettings]) { result in
//								switch result {
//								case .failure(let error):
//									XCTFail(error.detail)
//									expectation.fulfill()
//								case .success(let response):
//									XCTAssertTrue(response.problems.isEmpty)
//
//									let job = response.result.first!
//
//									// check status
//									self.uploadcare.documentConversionJobStatus(token: job.token) { result in
//										switch result {
//										case .failure(let error):
//											XCTFail(error.detail)
//											expectation.fulfill()
//										case .success(let status):
//											XCTAssertFalse(status.statusString.isEmpty)
//
//											// cleanup
//
//											delay(4) {
//												self.uploadcare.deleteFile(withUUID: job.uuid) { _ in
//													expectation.fulfill()
//												}
//											}
//										}
//									}
//								}
//							}
//						}
//					}
//				}
//			}
//
//
//		}
//
//		wait(for: [expectation], timeout: 180.0)
//	}
//
//	func test20_video_conversion_and_status() {
//		let expectation = XCTestExpectation(description: "test19_document_conversion_and_status")
//
//		let query = PaginationQuery()
//			.stored(true)
//			.ordering(.dateTimeUploadedDESC)
//			.limit(100)
//
//		uploadcare.listOfFiles(withQuery: query) { result in
//			switch result {
//			case .failure(let error):
//				XCTFail(error.detail)
//				expectation.fulfill()
//			case .success(let list):
//				let videoFile = list.results.first(where: { $0.mimeType == "video/mp4" || $0.mimeType == "video/quicktime" })!
//
//				let convertSettings = VideoConversionJobSettings(forFile: videoFile)
//					.format(.webm)
//					.size(VideoSize(width: 640, height: 480))
//					.resizeMode(.addPadding)
//					.quality(.lightest)
//					.cut( VideoCut(startTime: "0:0:5.000", length: "15") )
//
//				self.uploadcare.convertVideosWithSettings([convertSettings]) { result in
//					switch result {
//					case .failure(let error):
//						XCTFail(error.detail)
//						expectation.fulfill()
//					case .success(let response):
//						XCTAssertTrue(response.problems.isEmpty)
//
//						let job = response.result.first!
//
//						func check() {
//							self.uploadcare.videoConversionJobStatus(token: job.token) { result in
//								switch result {
//								case .failure(let error):
//									XCTFail(error.detail)
//									expectation.fulfill()
//								case .success(let statusResponse):
//									XCTAssertFalse(statusResponse.statusString.isEmpty)
//
//									DLog(statusResponse.statusString)
//
//									switch statusResponse.status {
//									case .finished, .failed(_):
//										// cleanup
//										self.uploadcare.groupInfo(withUUID: statusResponse.result!.thumbnailsGroupUUID) { result in
//											switch result {
//											case .failure(let error):
//												XCTFail(error.detail)
//												expectation.fulfill()
//											case .success(let group):
//												var ids = group.files!.map { $0.uuid }
//												ids.append(job.uuid)
//
//												self.uploadcare.deleteFiles(withUUIDs: ids) { result in
//													switch result {
//													case .failure(let error):
//														XCTFail(error.detail)
//													case .success(_):
//														break
//													}
//													expectation.fulfill()
//												}
//											}
//										}
//									default:
//										delay(2.0) {
//											check()
//										}
//									}
//								}
//							}
//						}
//
//						check()
//					}
//					}
//			}
//		}
//
//		wait(for: [expectation], timeout: 60.0)
//	}
//
//	var storingTestTask: UploadTaskable?
//	func test21_storing_shoudBeStored() {
//		let expectation = XCTestExpectation(description: "test21_storing_shoudBeStored")
//
//		let url = URL(string: "https://source.unsplash.com/random")!
//		let data = try! Data(contentsOf: url)
//		let file = uploadcare.file(fromData: data)
//		let name = UUID().uuidString
//
//		storingTestTask = file.upload(withName: name, store: .store, uploadSignature: nil) { _ in
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
//
//	func test22_fileMetadata() {
//		let expectation = XCTestExpectation(description: "expectation")
//
//		uploadcare.authScheme = .simple
//
//		// get any file from list of files
//		let query = PaginationQuery().limit(1)
//		let filesList = uploadcare.listOfFiles()
//		filesList.get(withQuery: query) { result in
//			switch result {
//			case .failure(let error):
//				XCTFail(error.detail)
//				expectation.fulfill()
//			case .success(let list):
//				let uuid = list.results.first!.uuid
//				let expectedValue = NSUUID().uuidString
//
//				// update
//				self.uploadcare.updateFileMetadata(withUUID: uuid, key: "myMeta", value:expectedValue) { result in
//					switch result {
//					case .failure(let error):
//						XCTFail(error.detail)
//					case .success(let val):
//						XCTAssertEqual(val, expectedValue)
//
//						// value by key
//						self.uploadcare.fileMetadataValue(forKey: "myMeta", withUUID: uuid) { result in
//							switch result {
//							case .failure(let error):
//								XCTFail(error.detail)
//							case .success(let value):
//								XCTAssertEqual(value, expectedValue)
//
//								// get metadata for file
//								self.uploadcare.fileMetadata(withUUID: uuid) { result in
//									defer { expectation.fulfill() }
//
//									switch result {
//									case .failure(let error):
//										XCTFail(error.detail)
//									case .success(let metadata):
//										XCTAssertFalse(metadata.isEmpty)
//										XCTAssertEqual(metadata["myMeta"], expectedValue)
//
//										// delete metadata
//										self.uploadcare.deleteFileMetadata(forKey: "myMeta", withUUID: uuid) { error in
//											XCTAssertNil(error)
//										}
//									}
//								}
//							}
//						}
//					}
//				}
//			}
//		}
//
//		wait(for: [expectation], timeout: 15.0)
//	}
//
//	func test23_aws_recognition_execute_and_status() {
//		let expectation = XCTestExpectation(description: "test23_aws_recognition_execute_and_status")
//
//		// get any file from list of files
//		let query = PaginationQuery().limit(1)
//		let filesList = uploadcare.listOfFiles()
//		filesList.get(withQuery: query) { result in
//			switch result {
//			case .failure(let error):
//				XCTFail(error.detail)
//				expectation.fulfill()
//			case .success(let list):
//				let uuid = list.results.first!.uuid
//
//				self.uploadcare.executeAWSRecognition(fileUUID: uuid) { result in
//					switch result {
//					case .failure(let error):
//						XCTFail(error.detail)
//					case .success(let response):
//						DLog(response)
//
//						// check status
//						self.uploadcare.checkAWSRecognitionStatus(requestID: response.requestID) { result in
//							defer { expectation.fulfill() }
//
//							switch result {
//							case .failure(let error):
//								XCTFail(error.detail)
//							case .success(let status):
//								XCTAssertTrue(status != .unknown)
//							}
//						}
//					}
//				}
//			}
//		}
//
//		wait(for: [expectation], timeout: 20.0)
//	}
//
//	func test24_clamav_execute_and_status() {
//		let expectation = XCTestExpectation(description: "test24_clamav_execute_and_status")
//
//		// get any file from list of files
//		let query = PaginationQuery().limit(1)
//		let filesList = uploadcare.listOfFiles()
//		filesList.get(withQuery: query) { result in
//			switch result {
//			case .failure(let error):
//				XCTFail(error.detail)
//				expectation.fulfill()
//			case .success(let list):
//				let uuid = list.results.first!.uuid
//
//				let parameters = ClamAVAddonExecutionParams(purgeInfected: true)
//				self.uploadcare.executeClamav(fileUUID: uuid, parameters: parameters) { result in
//					switch result {
//					case .failure(let error):
//						XCTFail(error.detail)
//					case .success(let response):
//						DLog(response)
//
//						// check status
//						self.uploadcare.checkClamAVStatus(requestID: response.requestID) { result in
//							defer { expectation.fulfill() }
//
//							switch result {
//							case .failure(let error):
//								XCTFail(error.detail)
//							case .success(let status):
//								XCTAssertTrue(status != .unknown)
//							}
//						}
//					}
//				}
//			}
//		}
//
//		wait(for: [expectation], timeout: 20.0)
//	}
//
//	func test25_removeBG_execute_and_status() {
//		let expectation = XCTestExpectation(description: "test25_removeBG_execute_and_status")
//
//		// get any file from list of files
//		let query = PaginationQuery().limit(1)
//		let filesList = uploadcare.listOfFiles()
//		filesList.get(withQuery: query) { result in
//			switch result {
//			case .failure(let error):
//				XCTFail(error.detail)
//				expectation.fulfill()
//			case .success(let list):
//				let uuid = list.results.first!.uuid
//
//				let parameters = RemoveBGAddonExecutionParams(crop: true, typeLevel: .two)
//				self.uploadcare.executeRemoveBG(fileUUID: uuid, parameters: parameters) { result in
//					switch result {
//					case .failure(let error):
//						XCTFail(error.detail)
//					case .success(let response):
//						// check status
//						self.uploadcare.checkRemoveBGStatus(requestID: response.requestID) { result in
//							defer { expectation.fulfill() }
//
//							switch result {
//							case .failure(let error):
//								XCTFail(error.detail)
//							case .success(let response):
//								DLog(response)
//								XCTAssertTrue(response.status != .unknown)
//							}
//						}
//					}
//				}
//			}
//		}
//
//		wait(for: [expectation], timeout: 20.0)
//	}
}

#endif

