//
//  UploadAPIIntegrationAsyncTests.swift
//  
//
//  Created by Sergei Armodin on 20.06.2023.
//

#if !os(watchOS)
import XCTest
@testable import Uploadcare

final class UploadAPIIntegrationAsyncTests: XCTestCase {
//	let uploadcare = Uploadcare(withPublicKey: "demopublickey", secretKey: "demopublickey")
	let uploadcare = Uploadcare(withPublicKey: String(cString: getenv("UPLOADCARE_PUBLIC_KEY")), secretKey: String(cString: getenv("UPLOADCARE_SECRET_KEY")))
//	let uploadcarePublicKeyOnly = Uploadcare(withPublicKey: "demopublickey")
	let uploadcarePublicKeyOnly = Uploadcare(withPublicKey: String(cString: getenv("UPLOADCARE_PUBLIC_KEY")))
	var newGroup: UploadedFilesGroup?

	func test01_UploadFileFromURL_and_UploadStatus() async throws {
		// upload from url
		let url = URL(string: "https://github.githubassets.com/images/modules/logos_page/GitHub-Mark.png?\(UUID().uuidString)")!
		let task = UploadFromURLTask(sourceUrl: url)
			.checkURLDuplicates(true)
			.saveURLDuplicates(true)
			.filename("file_from_url")
			.store(.doNotStore)
			.setMetadata("hi", forKey: "hello")

		let response = try await uploadcare.uploadAPI.upload(task: task)
		guard let token = response.token else {
			XCTFail("no token")
			return
		}

		try await Task.sleep(nanoseconds: 1 * NSEC_PER_SEC)
		_ = try await uploadcare.uploadAPI.uploadStatus(forToken: token)
	}

//	func test02_DirectUpload() async throws {
//		let url = URL(string: "https://source.unsplash.com/random")!
//		let data = try! Data(contentsOf: url)
//
//		DLog("size of file: \(sizeString(ofData: data))")
//
//		let metadata = ["direct": "upload"]
//
//		let resultDictionary = try await uploadcare.uploadAPI.directupload
//
//		uploadcare.uploadAPI.directUpload(files: ["random_file_name.jpg": data], store: .doNotStore, metadata: metadata, { progress in
//			DLog("upload progress: \(progress * 100)%")
//		}) { result in
//			switch result {
//			case .failure(let error):
//				XCTFail(error.detail)
//				return
//			case .success(let resultDictionary):
//				XCTAssertFalse(resultDictionary.isEmpty)
//				for file in resultDictionary {
//					DLog("uploaded file name: \(file.key) | file id: \(file.value)")
//				}
//			}
//		}
//
//	}

	func test03_DirectUploadInForeground() async throws {
		let url = URL(string: "https://source.unsplash.com/random")!
		let data = try! Data(contentsOf: url)

		DLog("size of file: \(sizeString(ofData: data))")

		let resultDictionary = try await uploadcare.uploadAPI.directUploadInForeground(files: ["random_file_name.jpg": data], store: .doNotStore)
		XCTAssertFalse(resultDictionary.isEmpty)

		for file in resultDictionary {
			DLog("uploaded file name: \(file.key) | file id: \(file.value)")
		}
	}

	func test05_UploadFileInfo() async throws {
		let url = URL(string: "https://source.unsplash.com/random?\(UUID().uuidString)")!
		let data = try! Data(contentsOf: url)

		DLog("size of file: \(sizeString(ofData: data))")

		let resultDictionary = try await uploadcare.uploadAPI.directUploadInForeground(files: ["random_file_name.jpg": data], store: .doNotStore)
		XCTAssertFalse(resultDictionary.isEmpty)

		let fileId = resultDictionary.first!.value
		_ = try await uploadcare.uploadAPI.fileInfo(withFileId: fileId)
	}

//	func test06_MainUpload_Cancel() {
//		let url = URL(string: "https://source.unsplash.com/random")!
//		let data = try! Data(contentsOf: url)
//
//		let expectation = XCTestExpectation(description: "test06_MainUpload_Cancel")
//		let task = uploadcare.uploadFile(data, withName: "random_file_name.jpg", store: .doNotStore) { progress in
//			DLog("upload progress: \(progress * 100)%")
//		} _: { result in
//			defer { expectation.fulfill() }
//
//			switch result {
//			case .failure(let error):
//				XCTAssertEqual(error.detail, "cancelled")
//			case .success(_):
//				XCTFail("should be error")
//			}
//		}
//
//		task.cancel()
//
//		wait(for: [expectation], timeout: 10.0)
//	}
//
//	func test07_MainUpload_PauseResume() {
//		let url = URL(string: "https://ucarecdn.com/26ba15c5-431b-4ecc-8be1-7a094ba3ba72/")!
//		let fileForUploading = uploadcare.file(withContentsOf: url)!
//
//		let expectation = XCTestExpectation(description: "test07_MainUpload_PauseResume")
//
//		var task: UploadTaskable?
//		var didPause = false
//		let onProgress: (Double)->Void = { (progress) in
//			DLog("progress: \(progress)")
//
//			if !didPause {
//				didPause.toggle()
//				(task as? UploadTaskResumable)?.pause()
//
//				delay(5.0) {
//					(task as? UploadTaskResumable)?.resume()
//				}
//			}
//		}
//
//		task = fileForUploading.upload(withName: "Mona_Lisa_23mb.jpg", store: .doNotStore, onProgress, { result in
//			defer { expectation.fulfill() }
//
//			switch result {
//			case .failure(let error):
//				XCTFail(error.detail)
//			case .success(_):
//				break
//			}
//		})
//
//		// pause
//		(task as? UploadTaskResumable)?.pause()
//		delay(2.0) {
//			(task as? UploadTaskResumable)?.resume()
//		}
//
//		wait(for: [expectation], timeout: 120.0)
//	}
//
//	func test08_fileInfo() {
//		let expectation = XCTestExpectation(description: "test08_fileInfo")
//
//		let url = URL(string: "https://source.unsplash.com/random")!
//		let data = try! Data(contentsOf: url)
//
//		uploadcare.uploadAPI.directUploadInForeground(files: ["random_file_name.jpg": data], store: .doNotStore, { (progress) in
//			DLog("upload progress: \(progress * 100)%")
//		}) { result in
//			switch result {
//			case .failure(let error):
//				XCTFail(error.detail)
//				expectation.fulfill()
//			case .success(let resultDictionary):
//				let fileID = resultDictionary.first!.value
//
//				self.uploadcare.uploadAPI.fileInfo(withFileId: fileID) { result in
//					defer { expectation.fulfill() }
//
//					switch result {
//					case .failure(let error):
//						XCTFail(error.detail)
//					case .success(let file):
//						XCTAssertNotNil(file.contentInfo)
//						XCTAssertNotNil(file.total)
//						XCTAssertEqual(file.total, file.size)
//						XCTAssertTrue(file.metadata?.isEmpty ?? true)
//					}
//				}
//			}
//		}
//
//		wait(for: [expectation], timeout: 10.0)
//	}
//
//	func test09_multipartUpload() {
//		let url = URL(string: "https://ucarecdn.com/26ba15c5-431b-4ecc-8be1-7a094ba3ba72/")!
//		let data = try! Data(contentsOf: url)
//
//		let expectation = XCTestExpectation(description: "test09_multipartUpload")
//
//		let onProgress: (Double)->Void = { (progress) in
//			DLog("progress: \(progress)")
//		}
//
//		let metadata = ["multipart": "upload"]
//
//		uploadcare.uploadAPI.multipartUpload(data, withName: "Mona_Lisa_23mb.jpg", store: .doNotStore, metadata: metadata, onProgress) { result in
//			defer { expectation.fulfill() }
//
//			switch result {
//			case .failure(let error):
//				XCTFail(error.detail)
//			case .success(_):
//				break
//			}
//		}
//		wait(for: [expectation], timeout: 120.0)
//	}
//
//	func test10_createFilesGroup_and_filesGroupInfo_and_delegeGroup() {
//		let expectation = XCTestExpectation(description: "test10_createFilesGroup_and_filesGroupInfo")
//
//		let url = URL(string: "https://source.unsplash.com/random?\(UUID().uuidString)")!
//		let data = try! Data(contentsOf: url)
//
//		DLog("size of file: \(sizeString(ofData: data))")
//
//		// upload a file
//		uploadcare.uploadAPI.directUploadInForeground(files: ["random_file_name.jpg": data], store: .doNotStore, { progress in
//			DLog("upload progress: \(progress * 100)%")
//		}) { result in
//			switch result {
//			case .failure(let error):
//				XCTFail(error.detail)
//				expectation.fulfill()
//			case .success(let resultDictionary):
//				XCTAssertFalse(resultDictionary.isEmpty)
//
//				// file info
//				let fileId = resultDictionary.first!.value
//				self.uploadcare.uploadAPI.fileInfo(withFileId: fileId) { result in
//					switch result {
//					case .failure(let error):
//						XCTFail(error.detail)
//						expectation.fulfill()
//					case .success(let info):
//						// create new group
//						self.newGroup = self.uploadcare.group(ofFiles:[info])
//						self.newGroup!.create { result in
//							switch result {
//							case .failure(let error):
//								XCTFail(error.detail)
//								expectation.fulfill()
//							case .success(let response):
//								XCTAssertNotNil(response.files)
//								XCTAssertFalse(response.files!.isEmpty)
//
//								XCTAssertEqual(response.filesCount, 1)
//
//								// group info
//								self.uploadcare.uploadAPI.filesGroupInfo(groupId: response.id) { result in
//									switch result {
//									case .failure(let error):
//										XCTFail(error.detail)
//										expectation.fulfill()
//									case .success(let group):
//										XCTAssertNotNil(group.files)
//										XCTAssertFalse(group.files!.isEmpty)
//
//										// delete group
//										self.uploadcare.deleteGroup(withUUID: group.id) { error in
//											defer { expectation.fulfill() }
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
//		wait(for: [expectation], timeout: 120.0)
//	}
//
//	func test11_direct_upload_public_key_only() {
//		let expectation = XCTestExpectation(description: "test11_public_key_only")
//
//		let url = URL(string: "https://source.unsplash.com/random")!
//		let data = try! Data(contentsOf: url)
//		let fileForUploading = uploadcarePublicKeyOnly.file(fromData: data)
//
//		fileForUploading.upload(withName: "test.jpg", store: .doNotStore) { _ in
//
//		} _: { result in
//			switch result {
//			case .success(let file):
//				DLog(file)
//			case .failure(let error):
//				XCTFail(String(describing: error))
//			}
//
//			expectation.fulfill()
//		}
//
//		wait(for: [expectation], timeout: 120.0)
//	}
//
//	func test12_multipartUpload_public_key_only() {
//		let expectation = XCTestExpectation(description: "test11_public_key_only")
//		let url = URL(string: "https://ucarecdn.com/26ba15c5-431b-4ecc-8be1-7a094ba3ba72/")!
//		let data = try! Data(contentsOf: url)
//		let fileForUploading = uploadcarePublicKeyOnly.file(fromData: data)
//
//		fileForUploading.upload(withName: "test.jpg", store: .doNotStore) { _ in
//
//		} _: { result in
//			switch result {
//			case .success(let file):
//				DLog(file)
//			case .failure(let error):
//				XCTFail(String(describing: error))
//			}
//
//			expectation.fulfill()
//		}
//
//
//		wait(for: [expectation], timeout: 120.0)
//	}
//
//	func test13_multipartUpload_videoFile() {
//		let url = URL(string: "https://ucarecdn.com/3e8a90e7-f5ce-422e-a3ed-5eee952f9f3b/")!
//		let data = try! Data(contentsOf: url)
//
//		let expectation = XCTestExpectation(description: "test13_multipartUpload_videoFile")
//
//		let onProgress: (Double)->Void = { (progress) in
//			DLog("progress: \(progress)")
//		}
//
//		let metadata = ["multipart": "upload"]
//
//		uploadcare.uploadAPI.multipartUpload(data, withName: "video.MP4", store: .doNotStore, metadata: metadata, onProgress) { result in
//			defer { expectation.fulfill() }
//
//			switch result {
//			case .failure(let error):
//				XCTFail(error.detail)
//			case .success(_):
//				break
//			}
//		}
//		wait(for: [expectation], timeout: 180.0)
//	}
}

#endif

