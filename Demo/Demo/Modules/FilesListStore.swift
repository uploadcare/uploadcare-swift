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
	@Published var task: UploadTaskResumable?
	@Published var uploadedFile: UploadedFile?
	
	var uploadcare: Uploadcare? {
		didSet {
			self.list = uploadcare?.listOfFiles()
		}
	}
	
	// MARK: - Private properties
	private var list: FilesList?
	
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
		self.task = fileForUploading.upload(withName: filename, store: .doNotStore, onProgress, { (file, error) in
			defer {
				self.isUploading = false
				self.uploadState = .notRunning
				self.task = nil
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
