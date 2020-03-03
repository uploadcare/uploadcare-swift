//
//  ViewController.swift
//  DemoApp
//
//  Created by Sergey Armodin on 12.01.2020.
//  Copyright © 2020 Sergei Armodin. All rights reserved.
//

import UIKit
import Uploadcare


class ViewController: UIViewController {
	private lazy var uploadcare: Uploadcare = {
		// Define your Public Key here
		#warning("Set your public key")
		let publicKey = ""
		return Uploadcare(withPublicKey: publicKey)
	}()

	override func viewDidLoad() {
		super.viewDidLoad()
		
		let queue = DispatchQueue(label: "uploadcare.test.queue")

//		queue.async { [unowned self] in
//			self.testUploadFileInfo()
//		}
//		queue.async { [unowned self] in
//			self.testUploadFile()
//		}
//		queue.async { [unowned self] in
//			self.testDirectUpload()
//		}
//		queue.async { [unowned self] in
//			self.testRESTListOfFiles()
//		}
//		queue.async { [unowned self] in
//			self.testRESTFileInfo()
//		}
//		queue.async { [unowned self] in
//			self.testRESTDeleteFile()
//		}
//		queue.async { [unowned self] in
//			self.testRESTBatchDeleteFiles()
//		}
//		queue.async { [unowned self] in
//			self.testRESTStoreFile()
//		}
//		queue.async { [unowned self] in
//			self.testRESTBatchStoreFiles()
//		}
//		queue.async { [unowned self] in
//			self.testListOfGroups()
//		}
//		queue.async { [unowned self] in
//			self.testGroupInfo()
//		}
//		queue.async { [unowned self] in
//			self.testStoreGroup()
//		}
//		queue.async { [unowned self] in
//			self.testCopyFileToLocalStorage()
//		}
//		queue.async { [unowned self] in
//			self.testCopyFileToRemoteStorate()
//		}
//		queue.async { [unowned self] in
//			self.testCreateFileGroups()
//		}
//		queue.async { [unowned self] in
//			self.testFileGroupInfo()
//		}
//		queue.async { [unowned self] in
//			self.testMultipartUpload()
//		}
	}
}


private extension ViewController {
	func testUploadFileInfo() {
		print("<------ testFileInfo ------>")
		let semaphore = DispatchSemaphore(value: 0)
		uploadcare.uploadAPI.fileInfo(withFileId: "e5d1649d-823c-4eeb-942f-4f88a1a81f8e") { (info, error) in
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
	
	func testUploadFile() {
		print("<------ testUploadFile ------>")
		let semaphore = DispatchSemaphore(value: 0)
		
		// upload from url
		let url = URL(string: "https://ucarecdn.com/assets/images/cloud.6b86b4f1d77e.jpg")
		let task = UploadFromURLTask(sourceUrl: url!)
			.checkURLDuplicates(true)
			.saveURLDuplicates(true)
			.store(.store)
		
		uploadcare.uploadAPI.upload(task: task) { [unowned self] (result, error) in
			print(result ?? "")
			
			guard let token = result?.token else {
				semaphore.signal()
				return
			}
			
			delay(1.0) { [unowned self] in
				self.uploadcare.uploadAPI.uploadStatus(forToken: token) { (status, error) in
					print(status ?? "no data")
					print(error ?? "no error")
					semaphore.signal()
				}
			}
			
		}
		semaphore.wait()
	}
	
	func testUploadStatus() {
		print("<------ testUploadFile ------>")
		let semaphore = DispatchSemaphore(value: 0)
		uploadcare.uploadAPI.uploadStatus(forToken: "ede4e436-9ff4-4027-8ffe-3b3e4d4a7f5b") { (status, error) in
			print(status ?? "no data")
			print(status?.error ?? "no error")
			semaphore.signal()
		}
		semaphore.wait()
	}
	
	func testDirectUpload() {
		print("<------ testDirectUpload ------>")
		guard let image = UIImage(named: "MonaLisa.jpg"), let data = image.jpegData(compressionQuality: 1) else { return }
		
		print("size of file: \(sizeString(ofData: data))")
		
		let semaphore = DispatchSemaphore(value: 0)
		uploadcare.uploadAPI.upload(files: ["random_file_name.jpg": data], store: .store) { (resultDictionary, error) in
			defer {
				semaphore.signal()
			}
			
			if let error = error {
				print(error)
				return
			}
			
			guard let files = resultDictionary else { return }
			
			for file in files {
				print("uploaded file name: \(file.key) | file id: \(file.value)")
			}
			print(resultDictionary ?? "nil")
		}
		semaphore.wait()
	}
	
	func testRESTListOfFiles() {
		print("<------ testRESTListOfFiles ------>")
		let semaphore = DispatchSemaphore(value: 0)
		
		let query = PaginationQuery()
			.stored(true)
			.ordering(.sizeDESC)
		uploadcare.listOfFiles(withQuery: query) { (list, error) in
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

			let newGroup = self.uploadcare.uploadAPI.group(ofFiles: [])
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
		
		uploadcare.uploadAPI.filesGroupInfo(groupId: "060d3492-0471-4d97-a68a-05aeacbc3ada~1") { (group, error) in
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
		guard let url = Bundle.main.url(forResource: "Mona_Lisa_23mb", withExtension: "jpg") else {
			assertionFailure("no file")
			return
		}
		
		guard let fileForUploading = uploadcare.uploadAPI.file(withContentsOf: url, withName: "Mona_Lisa_big.jpg") else {
			assertionFailure("cant' read data")
			return
		}
		
		fileForUploading.upload(withName: "Mona_Lisa_big.jpg")
		
		// or
		
		let semaphore = DispatchSemaphore(value: 0)
		fileForUploading.upload(withName: "Mona_Lisa_big.jpg") { (file, error) in
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
	
	
}
