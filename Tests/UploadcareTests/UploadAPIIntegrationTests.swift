//
//  File.swift
//  
//
//  Created by Sergei Armodin on 25.09.2021.
//

#if !os(watchOS)
import XCTest
@testable import Uploadcare

final class UploadAPIIntegrationTests: XCTestCase {
//	let uploadcare = Uploadcare(withPublicKey: "demopublickey", secretKey: "demopublickey")
	let uploadcare = Uploadcare(withPublicKey: String(cString: getenv("UPLOADCARE_PUBLIC_KEY")), secretKey: String(cString: getenv("UPLOADCARE_SECRET_KEY")))
//	let uploadcarePublicKeyOnly = Uploadcare(withPublicKey: "demopublickey")
	let uploadcarePublicKeyOnly = Uploadcare(withPublicKey: String(cString: getenv("UPLOADCARE_PUBLIC_KEY")))
	var newGroup: UploadedFilesGroup?

	func test01_UploadFileFromURL_and_UploadStatus() {
		let expectation = XCTestExpectation(description: "test01_UploadFileFromURL_and_UploadStatus")

		// upload from url
		let url = URL(string: "https://github.githubassets.com/images/modules/logos_page/GitHub-Mark.png?\(UUID().uuidString)")!
		let task = UploadFromURLTask(sourceUrl: url)
			.checkURLDuplicates(true)
			.saveURLDuplicates(true)
			.filename("file_from_url")
			.store(.doNotStore)
			.setMetadata("hi", forKey: "hello")

		uploadcare.uploadAPI.upload(task: task) { [unowned self] result in
			switch result {
			case .failure(let error):
				XCTFail(error.detail)
				expectation.fulfill()
				return
			case .success(let response):
				guard let token = response.token else {
					XCTFail("no token")
					expectation.fulfill()
					return
				}

				delay(1.0) { [unowned self] in
					self.uploadcare.uploadAPI.uploadStatus(forToken: token) { result in
						defer { expectation.fulfill() }

						switch result {
						case .failure(let error):
							XCTFail(error.detail)
						case .success(_):
							break
						}
					}
				}
			}
		}

		wait(for: [expectation], timeout: 20.0)
	}

	func test02_DirectUpload() {
		let expectation = XCTestExpectation(description: "test02_DirectUpload")

		let url = URL(string: "https://source.unsplash.com/featured")!
		let data = try! Data(contentsOf: url)

		DLog("size of file: \(sizeString(ofData: data))")

		let metadata = ["direct": "upload"]

		uploadcare.uploadAPI.directUpload(files: ["random_file_name.jpg": data], store: .doNotStore, metadata: metadata, { progress in
			DLog("upload progress: \(progress * 100)%")
		}) { result in
			defer { expectation.fulfill() }

			switch result {
			case .failure(let error):
				XCTFail(error.detail)
				return
			case .success(let resultDictionary):
				XCTAssertFalse(resultDictionary.isEmpty)
//				for file in resultDictionary {
//					DLog("uploaded file name: \(file.key) | file id: \(file.value)")
//				}
			}
		}

		wait(for: [expectation], timeout: 20.0)
	}

	func test03_DirectUploadInForeground() {
		let expectation = XCTestExpectation(description: "test03_DirectUploadInForeground")

		let url = URL(string: "https://source.unsplash.com/featured")!
		let data = try! Data(contentsOf: url)

		DLog("size of file: \(sizeString(ofData: data))")


		uploadcare.uploadAPI.directUploadInForeground(files: ["random_file_name.jpg": data], store: .doNotStore, { (progress) in
			DLog("upload progress: \(progress * 100)%")
		}) { result in
			defer { expectation.fulfill() }

			switch result {
			case .failure(let error):
				XCTFail(error.detail)
			case .success(let resultDictionary):
				XCTAssertFalse(resultDictionary.isEmpty)
			}

//			for file in resultDictionary! {
//				DLog("uploaded file name: \(file.key) | file id: \(file.value)")
//			}
		}

		wait(for: [expectation], timeout: 10.0)
	}

	func test04_DirectUploadInForegroundCancel() {
		let expectation = XCTestExpectation(description: "test04_DirectUploadInForegroundCancel")

		let url = URL(string: "https://source.unsplash.com/featured")!
		let data = try! Data(contentsOf: url)

		DLog("size of file: \(sizeString(ofData: data))")

		let task = uploadcare.uploadAPI.directUploadInForeground(files: ["random_file_name.jpg": data], store: .doNotStore, { (progress) in
			DLog("upload progress: \(progress * 100)%")
		}) { result in
			defer { expectation.fulfill() }

			switch result {
			case .failure(_):
				break
			case .success(_):
				XCTFail("should fail because of cancellation")
			}
		}

		task.cancel()

		wait(for: [expectation], timeout: 10.0)
	}

	func test05_UploadFileInfo() {
		let expectation = XCTestExpectation(description: "test05_UploadFileInfo")

		let url = URL(string: "https://source.unsplash.com/featured?\(UUID().uuidString)")!
		let data = try! Data(contentsOf: url)

		DLog("size of file: \(sizeString(ofData: data))")

		uploadcare.uploadAPI.directUploadInForeground(files: ["random_file_name.jpg": data], store: .doNotStore, { (progress) in
			DLog("upload progress: \(progress * 100)%")
		}) { result in
			switch result {
			case .failure(let error):
				XCTFail(error.detail)
				expectation.fulfill()
			case .success(let resultDictionary):
				XCTAssertFalse(resultDictionary.isEmpty)

				let fileId = resultDictionary.first!.value
				self.uploadcare.uploadAPI.fileInfo(withFileId: fileId) { result in
					defer { expectation.fulfill() }

					switch result {
					case .failure(let error):
						XCTFail(error.detail)
					case .success(_):
						break
					}
				}
			}
		}

		wait(for: [expectation], timeout: 10.0)
	}

	func test06_MainUpload_Cancel() {
		let url = URL(string: "https://source.unsplash.com/featured")!
		let data = try! Data(contentsOf: url)

		let expectation = XCTestExpectation(description: "test06_MainUpload_Cancel")
		let task = uploadcare.uploadFile(data, withName: "random_file_name.jpg", store: .doNotStore) { progress in
			DLog("upload progress: \(progress * 100)%")
		} _: { result in
			defer { expectation.fulfill() }

			switch result {
			case .failure(let error):
				XCTAssertEqual(error.detail, "cancelled")
			case .success(_):
				XCTFail("should be error")
			}
		}

		task.cancel()

		wait(for: [expectation], timeout: 10.0)
	}

	func test07_MainUpload_PauseResume() {
		let url = URL(string: "https://ucarecdn.com/26ba15c5-431b-4ecc-8be1-7a094ba3ba72/")!
		let fileForUploading = uploadcare.file(withContentsOf: url)!

		let expectation = XCTestExpectation(description: "test07_MainUpload_PauseResume")

		var task: UploadTaskable?
		var didPause = false
		let onProgress: (Double)->Void = { (progress) in
			DLog("progress: \(progress)")

			if !didPause {
				didPause.toggle()
				(task as? UploadTaskResumable)?.pause()

				delay(5.0) {
					(task as? UploadTaskResumable)?.resume()
				}
			}
		}

		task = fileForUploading.upload(withName: "Mona_Lisa_23mb.jpg", store: .doNotStore, onProgress, { result in
			defer { expectation.fulfill() }

			switch result {
			case .failure(let error):
				XCTFail(error.detail)
			case .success(_):
				break
			}
		})

		// pause
		(task as? UploadTaskResumable)?.pause()
		delay(2.0) {
			(task as? UploadTaskResumable)?.resume()
		}

		wait(for: [expectation], timeout: 120.0)
	}

	func test08_fileInfo() {
		let expectation = XCTestExpectation(description: "test08_fileInfo")

		let url = URL(string: "https://source.unsplash.com/featured")!
		let data = try! Data(contentsOf: url)

		uploadcare.uploadAPI.directUploadInForeground(files: ["random_file_name.jpg": data], store: .doNotStore, { (progress) in
			DLog("upload progress: \(progress * 100)%")
		}) { result in
			switch result {
			case .failure(let error):
				XCTFail(error.detail)
				expectation.fulfill()
			case .success(let resultDictionary):
				let fileID = resultDictionary.first!.value

				self.uploadcare.uploadAPI.fileInfo(withFileId: fileID) { result in
					defer { expectation.fulfill() }

					switch result {
					case .failure(let error):
						XCTFail(error.detail)
					case .success(let file):
						XCTAssertNotNil(file.contentInfo)
						XCTAssertNotNil(file.total)
						XCTAssertEqual(file.total, file.size)
						XCTAssertTrue(file.metadata?.isEmpty ?? true)
					}
				}
			}
		}

		wait(for: [expectation], timeout: 10.0)
	}

	func test09_multipartUpload() {
		let url = URL(string: "https://ucarecdn.com/26ba15c5-431b-4ecc-8be1-7a094ba3ba72/")!
		let data = try! Data(contentsOf: url)

		let expectation = XCTestExpectation(description: "test09_multipartUpload")

		let onProgress: (Double)->Void = { (progress) in
			DLog("progress: \(progress)")
		}

		let metadata = ["multipart": "upload"]

		uploadcare.uploadAPI.multipartUpload(data, withName: "Mona_Lisa_23mb.jpg", store: .doNotStore, metadata: metadata, onProgress) { result in
			defer { expectation.fulfill() }

			switch result {
			case .failure(let error):
				XCTFail(error.detail)
			case .success(_):
				break
			}
		}
		wait(for: [expectation], timeout: 120.0)
	}

	func test10_createFilesGroup_and_filesGroupInfo_and_delegeGroup() {
		let expectation = XCTestExpectation(description: "test10_createFilesGroup_and_filesGroupInfo")

		let url = URL(string: "https://source.unsplash.com/featured?\(UUID().uuidString)")!
		let data = try! Data(contentsOf: url)

		DLog("size of file: \(sizeString(ofData: data))")

		// upload a file
		uploadcare.uploadAPI.directUploadInForeground(files: ["random_file_name.jpg": data], store: .doNotStore, { progress in
			DLog("upload progress: \(progress * 100)%")
		}) { result in
			switch result {
			case .failure(let error):
				XCTFail(error.detail)
				expectation.fulfill()
			case .success(let resultDictionary):
				XCTAssertFalse(resultDictionary.isEmpty)

				// file info
				let fileId = resultDictionary.first!.value
				self.uploadcare.uploadAPI.fileInfo(withFileId: fileId) { result in
					switch result {
					case .failure(let error):
						XCTFail(error.detail)
						expectation.fulfill()
					case .success(let info):
						// create new group
						self.newGroup = self.uploadcare.group(ofFiles:[info])
						self.newGroup!.create { result in
							switch result {
							case .failure(let error):
								XCTFail(error.detail)
								expectation.fulfill()
							case .success(let response):
								XCTAssertNotNil(response.files)
								XCTAssertFalse(response.files!.isEmpty)

								XCTAssertEqual(response.filesCount, 1)

								// group info
								self.uploadcare.uploadAPI.filesGroupInfo(groupId: response.id) { result in
									switch result {
									case .failure(let error):
										XCTFail(error.detail)
										expectation.fulfill()
									case .success(let group):
										XCTAssertNotNil(group.files)
										XCTAssertFalse(group.files!.isEmpty)

										// delete group
										self.uploadcare.deleteGroup(withUUID: group.id) { error in
											defer { expectation.fulfill() }
											XCTAssertNil(error)
										}
									}
								}
							}
						}
					}
				}
			}
		}

		wait(for: [expectation], timeout: 120.0)
	}

	func test11_direct_upload_public_key_only() {
		let expectation = XCTestExpectation(description: "test11_public_key_only")

		let url = URL(string: "https://source.unsplash.com/featured")!
		let data = try! Data(contentsOf: url)
		let fileForUploading = uploadcarePublicKeyOnly.file(fromData: data)

		fileForUploading.upload(withName: "test.jpg", store: .doNotStore) { _ in

		} _: { result in
			switch result {
			case .success(let file):
				DLog(file)
			case .failure(let error):
				XCTFail(String(describing: error))
			}

			expectation.fulfill()
		}

		wait(for: [expectation], timeout: 120.0)
	}

	func test12_multipartUpload_public_key_only() {
		let expectation = XCTestExpectation(description: "test11_public_key_only")
		let url = URL(string: "https://ucarecdn.com/26ba15c5-431b-4ecc-8be1-7a094ba3ba72/")!
		let data = try! Data(contentsOf: url)
		let fileForUploading = uploadcarePublicKeyOnly.file(fromData: data)

		fileForUploading.upload(withName: "test.jpg", store: .doNotStore) { _ in

		} _: { result in
			switch result {
			case .success(let file):
				DLog(file)
			case .failure(let error):
				XCTFail(String(describing: error))
			}

			expectation.fulfill()
		}


		wait(for: [expectation], timeout: 120.0)
	}

    func test13_multipartUpload_videoFile() {
        let url = URL(string: "https://ucarecdn.com/3e8a90e7-f5ce-422e-a3ed-5eee952f9f3b/")!
        let data = try! Data(contentsOf: url)

        let expectation = XCTestExpectation(description: "test13_multipartUpload_videoFile")

        let onProgress: (Double)->Void = { (progress) in
            DLog("progress: \(progress)")
        }

        let metadata = ["multipart": "upload"]

        uploadcare.uploadAPI.multipartUpload(data, withName: "video.MP4", store: .doNotStore, metadata: metadata, onProgress) { result in
            defer { expectation.fulfill() }

            switch result {
            case .failure(let error):
                XCTFail(error.detail)
            case .success(_):
                break
            }
        }
        wait(for: [expectation], timeout: 180.0)
    }
}

#endif
