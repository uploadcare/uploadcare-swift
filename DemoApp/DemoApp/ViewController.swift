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
		#warning("Set your public and secret keys here")
		let publicKey = ""
		let secretKey = ""
		return Uploadcare(withPublicKey: publicKey, secretKey: secretKey)
	}()

	override func viewDidLoad() {
		super.viewDidLoad()
		
		let queue = DispatchQueue(label: "Serial queue")

		queue.async { [unowned self] in
			self.testFileInfo()
		}
		queue.async { [unowned self] in
			self.testUploadFile()
		}
		queue.async { [unowned self] in
			self.testDirectUpload()
		}
		
	}
}


private extension ViewController {
	func testFileInfo() {
		print("<------ testFileInfo ------>")
		let semaphore = DispatchSemaphore(value: 0)
		uploadcare.uploadedFileInfo(withFileId: "e5d1649d-823c-4eeb-942f-4f88a1a81f8e") { (info, error) in
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
		let url = URL(string: "https://spaceinbox.me/images/select-like-a-boss.png")
		var task = UploadFromURLTask(sourceUrl: url!)
		task.checkURLDuplicates = true
		task.saveURLDuplicates = true
		task.store = .store
		
		uploadcare.upload(task: task) { [unowned self] (result, error) in
			print(result ?? "")
			
			guard let token = result?.token else {
				semaphore.signal()
				return
			}
			
			delay(1.0) { [unowned self] in
				self.uploadcare.uploadStatus(forToken: token) { (status, error) in
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
		uploadcare.uploadStatus(forToken: "ede4e436-9ff4-4027-8ffe-3b3e4d4a7f5b") { (status, error) in
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
		uploadcare.upload(files: ["random_file_name.jpg": data], store: .store) { (resultDictionary, error) in
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
	
	func testListOfFiles() {
		print("<------ testListOfFiles ------>")
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
			
			print(list)
		}
		semaphore.wait()
	}
}
