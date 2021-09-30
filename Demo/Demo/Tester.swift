//
//  Tester.swift
//  Demo
//
//  Created by Sergey Armodin on 20.05.2020.
//  Copyright © 2020 Uploadcare, Inc. All rights reserved.
//

import Foundation
import Uploadcare


/// Delay function using GCD.
///
/// - Parameters:
///   - delay: delay in seconds
///   - closure: block to execute after delay
func delay(_ delay: Double, closure: @escaping ()->()) {
	DispatchQueue.main.asyncAfter(
		deadline: DispatchTime.now() + Double(Int64(delay * Double(NSEC_PER_SEC))) / Double(NSEC_PER_SEC), execute: closure)
}

func DLog(
	_ messages: Any...,
	fullPath: String = #file,
	line: Int = #line,
	functionName: String = #function
) {
	let file = URL(fileURLWithPath: fullPath)
	for message in messages {
		#if DEBUG
		let string = "\(file.pathComponents.last!):\(line) -> \(functionName): \(message)"
		print(string)
		#endif
	}
}

/// Count size of Data (in mb)
/// - Parameter data: data
func sizeString(ofData data: Data) -> String {
	let bcf = ByteCountFormatter()
	bcf.allowedUnits = [.useMB] // optional: restricts the units to MB only
	bcf.countStyle = .file
	return bcf.string(fromByteCount: Int64(data.count))
}


class Tester {
	private lazy var uploadcare: Uploadcare = {
		// Define your Public Key here
		let uploadcare = Uploadcare(withPublicKey: publicKey, secretKey: secretKey)
		// uploadcare.authScheme = .simple
		// or
		// uploadcare.authScheme = .signed
		return uploadcare
	}()
	
	func start() {
		let queue = DispatchQueue(label: "uploadcare.test.queue")
		
		//        queue.async { [unowned self] in
		//            self.testUploadFileInfo()
		//        }

//				queue.async { [unowned self] in
//					self.testMainUpload()
//				}

		//        queue.async { [unowned self] in
		//            self.testRESTListOfFiles()
		//        }
		//        queue.async { [unowned self] in
		//            self.testRESTFileInfo()
		//        }
		//        queue.async { [unowned self] in
		//            self.testRESTDeleteFile()
		//        }
		//        queue.async { [unowned self] in
		//            self.testRESTBatchDeleteFiles()
		//        }
		//        queue.async { [unowned self] in
		//            self.testRESTStoreFile()
		//        }
		//        queue.async { [unowned self] in
		//            self.testRESTBatchStoreFiles()
		//        }
		//        queue.async { [unowned self] in
		//            self.testListOfGroups()
		//        }
		//        queue.async { [unowned self] in
		//            self.testGroupInfo()
		//        }
		//        queue.async { [unowned self] in
		//            self.testStoreGroup()
		//        }
		//        queue.async { [unowned self] in
		//            self.testCopyFileToLocalStorage()
		//        }
		//        queue.async { [unowned self] in
		//            self.testCopyFileToRemoteStorate()
		//        }
		//        queue.async { [unowned self] in
		//            self.testCreateFileGroups()
		//        }
		//        queue.async { [unowned self] in
		//            self.testFileGroupInfo()
		//        }
		//        queue.async { [unowned self] in
		//            self.testMultipartUpload()
		//        }
		//        queue.async { [unowned self] in
		//            self.testRedirectForAuthenticatedUrls()
		//        }
		//        queue.async {
		//            self.testCreateWebhook()
		//        }
		//        queue.async {
		//            self.testListOfWebhooks()
		//        }
		//		queue.async {
		//            self.testUpdateWebhook()
		//        }
		//		queue.async {
		//            self.testDeleteWebhook()
		//        }
		//		queue.async {
		//            self.testDocumentConversion()
		//        }
//		queue.async {
//			self.testDocumentConversionStatus()
//		}
		//		queue.async {
		//            self.testVideoConversionStatus()
		//        }
		
	}
	
	func testUploadFileInfo() {
		print("<------ testUploadFileInfo ------>")
		let semaphore = DispatchSemaphore(value: 0)
		uploadcare.uploadAPI.fileInfo(withFileId: "530384dd-f43a-46de-b3c2-9448a24170cf") { (info, error) in
			defer {
				semaphore.signal()
			}
			if let error = error {
				print(error)
				return
			}
			
			print(info ?? "nil")
		}
		semaphore.wait()
	}
	
	func testUploadStatus() {
		print("<------ testUploadStatus ------>")
		let semaphore = DispatchSemaphore(value: 0)
		uploadcare.uploadAPI.uploadStatus(forToken: "ede4e436-9ff4-4027-8ffe-3b3e4d4a7f5b") { (status, error) in
			print(status ?? "no data")
			print(status?.error ?? "no error")
			semaphore.signal()
		}
		semaphore.wait()
	}

	func testMainUpload() {
		print("<------ testMainUpload ------>")
		guard let url = URL(string: "https://source.unsplash.com/random"), let data = try? Data(contentsOf: url) else { return }

		let semaphore = DispatchSemaphore(value: 0)
		let task = uploadcare.uploadFile(data, withName: "random_file_name.jpg", store: .doNotStore) { progress in
			print("upload progress: \(progress * 100)%")
		} _: { file, error in
			defer {
				semaphore.signal()
			}

			if let error = error {
				print(error)
				return
			}

			print(file ?? "nil")
		}

		// cancel if need
//		task.cancel()

		// pause or resume
		(task as? UploadTaskResumable)?.pause()
		(task as? UploadTaskResumable)?.resume()

		semaphore.wait()
	}
	
	func testRESTListOfFiles() {
		print("<------ testRESTListOfFiles ------>")
		let semaphore = DispatchSemaphore(value: 0)
		
		let query = PaginationQuery()
			.stored(true)
			.ordering(.sizeDESC)
			.limit(5)
		
		let filesList = uploadcare.listOfFiles()
		filesList.get(withQuery: query) { (list, error) in
			defer {
				semaphore.signal()
			}
			
			if let error = error {
				print(error)
				return
			}
			
			print(list ?? "")
		}
		semaphore.wait()
		
		// get next page
		print("-------------- next page")
		filesList.nextPage { (list, error) in
			defer {
				semaphore.signal()
			}
			
			if let error = error {
				print(error)
				return
			}
			
			print(list ?? "")
		}
		semaphore.wait()
		
		// get previous page
		print("-------------- previous page")
		filesList.previousPage { (list, error) in
			defer {
				semaphore.signal()
			}
			
			if let error = error {
				print(error)
				return
			}
			
			print(list ?? "")
		}
		semaphore.wait()
	}
	
	func testRESTFileInfo() {
		print("<------ testListOfFiles ------>")
		let semaphore = DispatchSemaphore(value: 0)
		
		uploadcare.fileInfo(withUUID: "1bac376c-aa7e-4356-861b-dd2657b5bfd2") { (file, error) in
			defer {
				semaphore.signal()
			}
			
			if let error = error {
				print(error)
				return
			}
			
			//            let urlString = file.keyCDNUrl(
			//                withToken: "fa3f69df3f4bcc9d4631bc7144838259bb26b34e26b4cc11c52e69f264b6c9fd",
			//                expire: 1589136407
			//            )
			// https://railsmuffin.ucarecdn.com/{UUID}/?token=fa3f69df3f4bcc9d4631bc7144838259bb26b34e26b4cc11c52e69f264b6c9fd&expire=1589136407
			
			print(file ?? "")
		}
		semaphore.wait()
	}
	
	func testRESTDeleteFile() {
		print("<------ testRESTDeleteFile ------>")
		let semaphore = DispatchSemaphore(value: 0)
		
		uploadcare.deleteFile(withUUID: "1bac376c-aa7e-4356-861b-dd2657b5bfd2") { (file, error) in
			defer {
				semaphore.signal()
			}
			
			if let error = error {
				print(error)
				return
			}
			
			print(file ?? "")
		}
		semaphore.wait()
	}
	
	func testRESTBatchDeleteFiles() {
		print("<------ testRESTBatchDeleteFiles ------>")
		let semaphore = DispatchSemaphore(value: 0)
		
		uploadcare.deleteFiles(withUUIDs: ["b7a301d1-1bd0-473d-8d32-708dd55addc0", "shouldBeInProblems"]) { (response, error) in
			defer {
				semaphore.signal()
			}
			
			if let error = error {
				print(error)
				return
			}
			
			print(response ?? "")
		}
		semaphore.wait()
	}
	
	func testRESTStoreFile() {
		print("<------ testRESTStoreFile ------>")
		let semaphore = DispatchSemaphore(value: 0)
		
		uploadcare.storeFile(withUUID: "1bac376c-aa7e-4356-861b-dd2657b5bfd2") { (file, error) in
			defer {
				semaphore.signal()
			}
			
			if let error = error {
				print(error)
				return
			}
			
			print(file ?? "")
		}
		semaphore.wait()
	}
	
	func testRESTBatchStoreFiles() {
		print("<------ testRESTBatchStoreFiles ------>")
		let semaphore = DispatchSemaphore(value: 0)
		
		uploadcare.storeFiles(withUUIDs: ["1bac376c-aa7e-4356-861b-dd2657b5bfd2", "shouldBeInProblems"]) { (response, error) in
			defer {
				semaphore.signal()
			}
			
			if let error = error {
				print(error)
				return
			}
			
			print(response ?? "")
		}
		semaphore.wait()
	}
	
	func testListOfGroups() {
		print("<------ testListOfGroups ------>")
		let semaphore = DispatchSemaphore(value: 0)
		
		let query = GroupsListQuery()
			.limit(100)
			.ordering(.datetimeCreatedDESC)
		
		uploadcare.listOfGroups(withQuery: query) { (list, error) in
			defer {
				semaphore.signal()
			}
			
			if let error = error {
				print(error)
				return
			}
			
			print(list ?? "")
		}
		semaphore.wait()
		
		// using GroupsList object:
		let groupsList = uploadcare.listOfGroups()
		groupsList.get(withQuery: query) { (list, error) in
			defer {
				semaphore.signal()
			}
			
			if let error = error {
				print(error)
				return
			}
			
			print(list ?? "")
		}
		semaphore.wait()
		
		// get next page
		print("-------------- next page")
		groupsList.nextPage { (list, error) in
			defer {
				semaphore.signal()
			}
			
			if let error = error {
				print(error)
				return
			}
			
			print(list ?? "")
		}
		semaphore.wait()
		
		// get previous page
		print("-------------- previous page")
		groupsList.previousPage { (list, error) in
			defer {
				semaphore.signal()
			}
			
			if let error = error {
				print(error)
				return
			}
			
			print(list ?? "")
		}
		semaphore.wait()
	}
	
	func testGroupInfo() {
		print("<------ testGroupInfo ------>")
		let semaphore = DispatchSemaphore(value: 0)
		
		uploadcare.groupInfo(withUUID: "c5bec8c7-d4b6-4921-9e55-6edb027546bc~1") { (group, error) in
			defer {
				semaphore.signal()
			}
			
			if let error = error {
				print(error)
				return
			}
			
			print(group ?? "")
		}
		semaphore.wait()
	}
	
	func testStoreGroup() {
		print("<------ testStoreGroup ------>")
		let semaphore = DispatchSemaphore(value: 0)
		
		uploadcare.storeGroup(withUUID: "c5bec8c7-d4b6-4921-9e55-6edb027546bc~1") { (error) in
			defer {
				semaphore.signal()
			}
			
			if let error = error {
				print(error)
				return
			}
			print("store group success")
		}
		semaphore.wait()
	}
	
	func testCopyFileToLocalStorage() {
		print("<------ testCopyFileToLocalStorage ------>")
		let semaphore = DispatchSemaphore(value: 0)
		
		uploadcare.copyFileToLocalStorage(source: "6ca619a8-70a7-4777-8de1-7d07739ebbd9") { (response, error) in
			defer {
				semaphore.signal()
			}
			
			if let error = error {
				print(error)
				return
			}
			print(response ?? "")
		}
		semaphore.wait()
	}
	
	func testCopyFileToRemoteStorate() {
		print("<------ testCopyFileToLocalStorage ------>")
		let semaphore = DispatchSemaphore(value: 0)
		
		uploadcare.copyFileToRemoteStorage(source: "99c48392-46ab-4877-a6e1-e2557b011176", target: "one_more_project", pattern: .uuid) { (response, error) in
			defer {
				semaphore.signal()
			}
			
			if let error = error {
				print(error)
				return
			}
			print(response ?? "")
		}
		semaphore.wait()
	}
	
	func testCreateFileGroups() {
		print("<------ testCreateFileGroups ------>")
		let semaphore = DispatchSemaphore(value: 0)
		uploadcare.uploadAPI.filesGroupInfo(groupId: "69b8e46f-91c9-494f-ba3b-e5fdf9c36db2~2") { (group, error) in
			guard group != nil else {
				print(error ?? "")
				return
			}
			
			let newGroup = self.uploadcare.group(ofFiles: [])
			newGroup.files = group?.files ?? []
			newGroup.create { (_, error) in
				print(error ?? "")
				print(newGroup)
			}
		}
		semaphore.wait()
	}
	
	func testFileGroupInfo() {
		print("<------ testFileGroupInfo ------>")
		let semaphore = DispatchSemaphore(value: 0)
		
		uploadcare.uploadAPI.filesGroupInfo(groupId: "69b8e46f-91c9-494f-ba3b-e5fdf9c36db2~2") { (group, error) in
			defer {
				semaphore.signal()
			}
			if let error = error {
				print(error)
				return
			}
			print(group ?? "")
		}
		semaphore.wait()
	}
	
	func testMultipartUpload() {
		print("<------ testMultipartUpload ------>")
		
		guard let url = Bundle.main.url(forResource: "Mona_Lisa_23mb", withExtension: "jpg") else {
			assertionFailure("no file")
			return
		}
		
		guard let fileForUploading = uploadcare.file(withContentsOf: url) else {
			assertionFailure("file not found")
			return
		}
		
		// upload without any callbacks
		//        fileForUploading.upload(withName: "Mona_Lisa_big111.jpg")
		
		// or
		
		let semaphore = DispatchSemaphore(value: 0)
		
		var task: UploadTaskable?
		var didPause = false
		let onProgress: (Double)->Void = { (progress) in
			print("progress: \(progress)")
			
			if !didPause {
				didPause.toggle()
				(task as? UploadTaskResumable)?.pause()
				
				delay(10.0) {
					(task as? UploadTaskResumable)?.resume()
				}
			}
		}
		
		task = fileForUploading.upload(withName: "Mona_Lisa_big.jpg", store: .store, onProgress, { (file, error) in
			defer {
				semaphore.signal()
			}
			if let error = error {
				print(error)
				return
			}
			print(file ?? "")
		})
		
		// pause
		(task as? UploadTaskResumable)?.pause()
		delay(2.0) {
			(task as? UploadTaskResumable)?.resume()
		}
		
		// cancel if need
		//        task?.cancel()
		
		semaphore.wait()
	}
	
	func testRedirectForAuthenticatedUrls() {
		print("<------ testRedirectForAuthenticatedUrls ------>")
		let semaphore = DispatchSemaphore(value: 0)
		
		let url = URL(string: "http://goo.gl/")!
		uploadcare.getAuthenticatedUrlFromUrl(url, { (value, error) in
			defer { semaphore.signal() }
			
			if let error = error {
				print(error)
				return
			}
			
			print(value ?? "")
		})
		
		semaphore.wait()
	}
	
	func testListOfWebhooks() {
		print("<------ testListOfWebhooks ------>")
		let semaphore = DispatchSemaphore(value: 0)
		
		uploadcare.getListOfWebhooks { (value, error) in
			defer { semaphore.signal() }
			
			if let error = error {
				print(error)
				return
			}
			
			print(value ?? "")
		}
		
		semaphore.wait()
	}
	
	func testCreateWebhook() {
		print("<------ testCreateWebhook ------>")
		let semaphore = DispatchSemaphore(value: 0)
		
		let random = (0...1000).randomElement()!
		let url = URL(string: "https://google.com/\(random)")!
		uploadcare.createWebhook(targetUrl: url, isActive: true) { (value, error) in
			defer { semaphore.signal() }
			
			if let error = error {
				print(error)
				return
			}
			
			print(value ?? "")
		}
		
		semaphore.wait()
	}
	
	func testUpdateWebhook() {
		print("<------ testUpdateWebhook ------>")
		let semaphore = DispatchSemaphore(value: 0)
		
		let random = (0...1000).randomElement()!
		let url = URL(string: "https://apple.com/\(random)")!
		
		uploadcare.getListOfWebhooks { (value, error) in
			if let error = error {
				print(error)
				semaphore.signal()
				return
			}
			
			guard let webhook = value?.first else {
				semaphore.signal()
				return
			}
			
			print(webhook)
			self.uploadcare.updateWebhook(id: webhook.id, targetUrl: url, isActive: true) { (value, error) in
				defer { semaphore.signal() }
				
				if let error = error {
					print(error)
					return
				}
				
				print(value ?? "")
			}
		}
		
		semaphore.wait()
	}
	
	func testDeleteWebhook() {
		print("<------ testDeleteWebhook ------>")
		let semaphore = DispatchSemaphore(value: 0)
		
		uploadcare.getListOfWebhooks { (value, error) in
			if let error = error {
				print(error)
				semaphore.signal()
				return
			}
			
			guard let webhook = value?.first else {
				semaphore.signal()
				return
			}
			
			print("will delete:")
			print(webhook)
			let url = URL(string: webhook.targetUrl)!
			self.uploadcare.deleteWebhook(forTargetUrl: url) { (error) in
				if let error = error {
					print(error)
				}
				
				semaphore.signal()
			}
		}
		
		semaphore.wait()
	}
	
	func testDocumentConversion() {
		print("<------ testDocumentConversion ------>")
		let semaphore = DispatchSemaphore(value: 0)
		
		uploadcare.fileInfo(withUUID: "b40e1f1a-46e1-471e-8a57-cb863719e8b0") { (file, error) in
			guard let file = file else {
				print(error ?? "fileInfo error")
				semaphore.signal()
				return
			}
			
			let convertSettings = DocumentConversionJobSettings(forFile: file)
				.format(.odt)
			
			self.uploadcare.convertDocumentsWithSettings([convertSettings]) { (response, error) in
				defer { semaphore.signal() }
				
				guard let response = response else {
					print(error ?? "error")
					return
				}
				
				print(response)
			}
		}
		semaphore.wait()
	}
	
	func testDocumentConversionStatus() {
		print("<------ testDocumentConversionStatus ------>")
		let semaphore = DispatchSemaphore(value: 0)
		
		uploadcare.fileInfo(withUUID: "b40e1f1a-46e1-471e-8a57-cb863719e8b0") { (file, error) in
			guard let file = file else {
				print(error ?? "fileInfo error")
				semaphore.signal()
				return
			}
			
			let convertSettings = DocumentConversionJobSettings(forFile: file)
				.format(.odt)
			
			self.uploadcare.convertDocumentsWithSettings([convertSettings]) { (response, error) in
				guard let response = response else {
					print(error ?? "error")
					semaphore.signal()
					return
				}
				
				guard response.problems.isEmpty, let job = response.result.first else {
					print(response)
					semaphore.signal()
					return
				}
				
				let timer = Timer.scheduledTimer(withTimeInterval: 2, repeats: true) { (timer) in
					self.uploadcare.documentConversionJobStatus(token: job.token) { (status, error) in
						guard let status = status else {
							print(error ?? "error")
							return
						}
						
						print(status)
						switch status.status {
						case .finished, .failed(_):
							timer.invalidate()
							semaphore.signal()
						default: break
						}
					}
				}
				timer.fire()
			}
		}
		semaphore.wait()
	}
	
	func testVideoConversionStatus() {
		print("<------ testVideoConversionStatus ------>")
		let semaphore = DispatchSemaphore(value: 0)
		
		uploadcare.fileInfo(withUUID: "8968032a-6d52-4d68-8af7-154552412f93") { (file, error) in
			guard let file = file else {
				print(error ?? "fileInfo error")
				semaphore.signal()
				return
			}
			
			print(file)
			
			let convertSettings = VideoConversionJobSettings(forFile: file)
				.format(.webm)
				.size(VideoSize(width: 640, height: 480))
				.resizeMode(.addPadding)
				.quality(.lightest)
				.cut( VideoCut(startTime: "0:0:5.000", length: "15") )
				.thumbs(15)
			
			self.uploadcare.convertVideosWithSettings([convertSettings]) { (response, error) in
				guard let response = response else {
					print(error ?? "error")
					semaphore.signal()
					return
				}
				
				guard response.problems.isEmpty, let job = response.result.first else {
					print(response)
					semaphore.signal()
					return
				}
				
				let timer = Timer.scheduledTimer(withTimeInterval: 2, repeats: true) { (timer) in
					self.uploadcare.videoConversionJobStatus(token: job.token) { (status, error) in
						guard let status = status else {
							print(error ?? "error")
							return
						}
						
						print(status)
						switch status.status {
						case .finished, .failed(_):
							timer.invalidate()
							semaphore.signal()
						default: break
						}
					}
				}
				timer.fire()
			}
		}
		semaphore.wait()
	}
}
