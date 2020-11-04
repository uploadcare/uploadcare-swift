//
//  FilesListStore.swift
//  Demo
//
//  Created by Sergey Armodin on 28.10.2020.
//  Copyright © 2020 Sergei Armodin. All rights reserved.
//

import Foundation
import Combine
import Uploadcare

class FilesListStore: ObservableObject {
	// MARK: - Public properties
	@Published var files: [FileViewData] = []
	@Published var uploadState: UploadState = .notRunning
	@Published var isUploading: Bool = false
	@Published var progressValue: Double = 0.0
	@Published var currentTask: UploadTaskResumable?
	@Published var uploadedFile: UploadedFile?
	@Published var filesQueue: [URL] = []
	@Published var uploadedFromQueue: Int = 0
	
	
	var uploadcare: Uploadcare? {
		didSet {
			self.list = uploadcare?.listOfFiles()
		}
	}
	
	// MARK: - Private properties
	private var list: FilesList?
	private let uploadingQueue: DispatchQueue = DispatchQueue(label: "com.uploadcare.uploadQueue")
	
	// MARK: - Init
	init(files: [FileViewData]) {
		self.files = files
	}
	
	// MARK: - Public methods
	func load(_ completionHandler: @escaping (FilesList?, RESTAPIError?) -> Void) {
		let query = PaginationQuery()
			.limit(5)
			.ordering(.dateTimeUploadedDESC)
		
		self.list?.get(withQuery: query, completionHandler)
	}
	
	func loadNext(_ completionHandler: @escaping (FilesList?, RESTAPIError?) -> Void) {
		self.list?.nextPage(completionHandler)
	}
	
	func uploadFiles(_ urls: [URL], completionHandler: @escaping ([String])->Void) {
		self.filesQueue = urls
		var fileIds: [String] = []
		
		let semaphore = DispatchSemaphore(value: 0)
		self.uploadedFromQueue = 0
		uploadingQueue.async { [weak self] in
			guard let self = self else { return }
			
			for fileUrl in self.filesQueue {
				DispatchQueue.main.async { [weak self] in
					self?.uploadedFromQueue += 1
					self?.uploadFile(fileUrl) { (fileId) in
						fileIds.append(fileId)
						semaphore.signal()
					}
				}
				semaphore.wait()
			}
			
			DispatchQueue.main.async {
				completionHandler(fileIds)
				self.filesQueue.removeAll()
			}
		}
	}
	
	func uploadFile(_ url: URL, completionHandler: @escaping (String)->Void) {
		let data: Data
		do {
			data = try Data(contentsOf: url)
		} catch let error {
			DLog(error)
			return
		}
		
		self.progressValue = 0
		let filename = url.lastPathComponent

		if data.count < UploadAPI.multipartMinFileSize {
			self.performDirectUpload(filename: filename, data: data, completionHandler: completionHandler)
		} else {
			self.performMultipartUpload(filename: filename, fileUrl: url, completionHandler: completionHandler)
		}
	}
	
	func performDirectUpload(filename: String, data: Data, completionHandler: @escaping (String)->Void) {
		let onProgress: (Double)->Void = { (progress) in
			DispatchQueue.main.async { [weak self] in
				self?.progressValue = progress
			}
		}
		self.uploadcare?.uploadAPI.upload(files: [filename: data], store: .doNotStore, onProgress, { (uploadData, error) in
			if let error = error {
				return DLog(error)
			}

			guard let uploadData = uploadData, let fileId = uploadData.first?.value else { return }
			completionHandler(fileId)
			DLog(uploadData)
		})
	}
	
	func performMultipartUpload(filename: String, fileUrl: URL, completionHandler: @escaping (String)->Void) {
		let onProgress: (Double)->Void = { (progress) in
			DispatchQueue.main.async { [weak self] in
				self?.progressValue = progress
			}
		}

		guard let fileForUploading = self.uploadcare?.uploadAPI.file(withContentsOf: fileUrl) else {
			assertionFailure("file not found")
			return
		}

		self.uploadState = .uploading
		
		self.currentTask = fileForUploading.upload(withName: filename, store: .doNotStore, onProgress, { (file, error) in
			defer {
				self.isUploading = false
				self.uploadState = .notRunning
				self.currentTask = nil
			}
			
			if let error = error {
				DLog(error)
				return
			}
			
			guard let file = file else { return }
			completionHandler(file.fileId)
			DLog(file)
		})
	}
}
