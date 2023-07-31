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

	func test02_DirectUploadInForeground_and_FileInfo() async throws {
		let url = URL(string: "https://source.unsplash.com/featured")!
		let data = try! Data(contentsOf: url)

		DLog("size of file: \(sizeString(ofData: data))")

		let resultDictionary = try await uploadcare.uploadAPI.directUploadInForeground(files: ["random_file_name.jpg": data], store: .doNotStore)
		XCTAssertFalse(resultDictionary.isEmpty)

		for file in resultDictionary {
			DLog("uploaded file name: \(file.key) | file id: \(file.value)")
		}

		let fileId = resultDictionary.first!.value
		let file = try await uploadcare.uploadAPI.fileInfo(withFileId: fileId)

		XCTAssertNotNil(file.contentInfo)
		XCTAssertNotNil(file.total)
		XCTAssertEqual(file.total, file.size)
		XCTAssertTrue(file.metadata?.isEmpty ?? true)
	}

	func test03_MainUpload() async throws {
		let url = URL(string: "https://source.unsplash.com/featured")!
		let data = try! Data(contentsOf: url)

		// small file with direct uploading
		let file = try await uploadcare.uploadFile(data, withName: "random_file_name.jpg", store: .doNotStore) { progress in
			DLog("upload progress: \(progress * 100)%")
		}
		XCTAssertFalse(file.fileId.isEmpty)

		// big file for multipart uploading
		let url2 = URL(string: "https://ucarecdn.com/26ba15c5-431b-4ecc-8be1-7a094ba3ba72/")!
		let data2 = try Data(contentsOf: url2)

		let file2 = try await uploadcare.uploadFile(data2, withName: "random_file_name.jpg", store: .doNotStore) { progress in
			DLog("upload progress: \(progress * 100)%")
		}
		XCTAssertFalse(file2.fileId.isEmpty)
	}

	func test04_multipartUpload() async throws {
		let url = URL(string: "https://ucarecdn.com/26ba15c5-431b-4ecc-8be1-7a094ba3ba72/")!
		let data = try Data(contentsOf: url)

		let onProgress: (Double)->Void = { (progress) in
			DLog("progress: \(progress)")
		}

		let metadata = ["multipart": "upload"]

		let file = try await uploadcare.uploadAPI.multipartUpload(data, withName: "Mona_Lisa_23mb.jpg", store: .doNotStore, metadata: metadata, onProgress)
		XCTAssertFalse(file.fileId.isEmpty)
	}

	func test05_createFilesGroup_and_filesGroupInfo_and_delegeGroup() async throws {
		let url = URL(string: "https://source.unsplash.com/featured?\(UUID().uuidString)")!
		let data = try! Data(contentsOf: url)

		DLog("size of file: \(sizeString(ofData: data))")

		// upload a file
		let resultDictionary = try await uploadcare.uploadAPI.directUploadInForeground(files: ["random_file_name.jpg": data], store: .doNotStore)
		XCTAssertFalse(resultDictionary.isEmpty)

		// file info
		let fileId = resultDictionary.first!.value
		let info = try await uploadcare.uploadAPI.fileInfo(withFileId: fileId)

		// create new group
		newGroup = try await uploadcare.group(ofFiles:[info]).create()
		XCTAssertNotNil(newGroup?.files)
		XCTAssertFalse(newGroup!.files!.isEmpty)
		XCTAssertEqual(newGroup?.filesCount, 1)

		// group info
		let group = try await uploadcare.uploadAPI.filesGroupInfo(groupId: newGroup!.id)
		XCTAssertNotNil(group.files)
		XCTAssertFalse(group.files!.isEmpty)

		// delete group
		try await uploadcare.deleteGroup(withUUID: group.id)
	}

	func test06_direct_upload_public_key_only() async throws {
		// a small file that should be uploaded with multipart upload method
		let url = URL(string: "https://source.unsplash.com/featured")!
		let data = try! Data(contentsOf: url)
		let fileForUploading = uploadcarePublicKeyOnly.file(fromData: data)

		let file = try await fileForUploading.upload(withName: "test.jpg", store: .doNotStore) { _ in }
		DLog(file)
		XCTAssertFalse(file.fileId.isEmpty)
	}

	func test07_multipartUpload_public_key_only() async throws {
		// a big file that should be uploaded with multipart upload method
		let url = URL(string: "https://ucarecdn.com/26ba15c5-431b-4ecc-8be1-7a094ba3ba72/")!
		let data = try! Data(contentsOf: url)
		let fileForUploading = uploadcarePublicKeyOnly.file(fromData: data)

		let file = try await fileForUploading.upload(withName: "test.jpg", store: .doNotStore) { _ in }
		DLog(file)
		XCTAssertFalse(file.fileId.isEmpty)
	}

	func test08_multipartUpload_videoFile() async throws {
		let url = URL(string: "https://ucarecdn.com/3e8a90e7-f5ce-422e-a3ed-5eee952f9f3b/")!
		let data = try! Data(contentsOf: url)

		let onProgress: (Double)->Void = { (progress) in
			DLog("progress: \(progress)")
		}
		let metadata = ["multipart": "upload"]
		let file = try await uploadcare.uploadAPI.multipartUpload(data, withName: "video.MP4", store: .doNotStore, metadata: metadata, onProgress)
		XCTAssertFalse(file.fileId.isEmpty)
	}
}

#endif

