//
//  FilesListStore.swift
//  Demo
//
//  Created by Sergey Armodin on 28.10.2020.
//  Copyright © 2020 Uploadcare, Inc. All rights reserved.
//

import Foundation
import UIKit
import Combine
import Uploadcare

class FilesListStore: ObservableObject {
	// MARK: - Public properties
	@Published var files: [FileViewData] = []
	@Published var uploadState: UploadState = .notRunning
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
	private var backgroundTask: UIBackgroundTaskIdentifier = .invalid
	
	// MARK: - Init
	init(files: [FileViewData]) {
		self.files = files
	}
	
	// MARK: - Public methods
	func load() async throws {
		guard let list = list else { fatalError("No list object") }
		list.results.removeAll()

		let query = PaginationQuery()
			.limit(5)
			.ordering(.dateTimeUploadedDESC)

		try await list.get(withQuery: query)
		DispatchQueue.main.async {
			list.results.forEach { self.files.append(FileViewData( file: $0)) }
		}
	}

	func loadNext() async throws {
		guard let list = list else { fatalError("No list object") }
		try await list.nextPage()
		DispatchQueue.main.async {
			list.results.forEach({ self.files.append(FileViewData( file: $0)) })
		}
	}

	func deleteFiles(at offsets: IndexSet) async throws {
		let uuids = offsets.map { self.files[$0].file.uuid }
		try await uploadcare?.deleteFiles(withUUIDs: uuids)
		DispatchQueue.main.async { self.files.remove(atOffsets: offsets) }
	}

	func uploadFiles(_ urls: [URL], completionHandler: @escaping ([String])->Void) {
		self.filesQueue = urls
		var fileIds: [String] = []
		
		let semaphore = DispatchSemaphore(value: 0)
		self.uploadedFromQueue = 0
		self.uploadState = .uploading
		
		registerBackgroundTask()
		
		uploadingQueue.async { [weak self] in
			guard let self = self else { return }
			
			for fileUrl in self.filesQueue {
				_ = fileUrl.startAccessingSecurityScopedResource()
				DispatchQueue.main.async { [weak self] in
					self?.uploadedFromQueue += 1
					self?.uploadFile(fileUrl) { (fileId) in
						fileIds.append(fileId)
						semaphore.signal()
					}
				}
				semaphore.wait()
				fileUrl.stopAccessingSecurityScopedResource()
			}
			
			DispatchQueue.main.async { [weak self] in
				self?.endBackgroundTask()
				self?.uploadState = .notRunning
				completionHandler(fileIds)
				self?.filesQueue.removeAll()
			}
		}
		
	}
	
	func uploadFile(_ url: URL, completionHandler: @escaping (String) -> Void) {
		let data: Data
		do {
			data = try Data(contentsOf: url)
		} catch let error {
			DLog(error)
			return
		}
		
		self.progressValue = 0
		let filename = url.lastPathComponent

		let onProgress: (Double) -> Void = { (progress) in
			DispatchQueue.main.async { [weak self] in
				self?.progressValue = progress
			}
		}

		self.currentTask = self.uploadcare?.uploadFile(data, withName: filename, store: .auto, onProgress, { result in
			switch result {
			case .failure(let error):
				DLog(error)
			case .success(let file):
				completionHandler(file.uuid)
			}
		}) as? UploadTaskResumable
	}
}

private extension FilesListStore {
	func registerBackgroundTask() {
		backgroundTask = UIApplication.shared.beginBackgroundTask { [weak self] in
			self?.endBackgroundTask()
		}
		assert(backgroundTask != .invalid)
	}
	
	func endBackgroundTask() {
		DLog("Background task ended.")
		UIApplication.shared.endBackgroundTask(backgroundTask)
		backgroundTask = .invalid
	}
}


extension Double {
	/// Rounds the double to decimal places value
	func rounded(toPlaces places:Int) -> Double {
		let divisor = pow(10.0, Double(places))
		return (self * divisor).rounded() / divisor
	}
}
