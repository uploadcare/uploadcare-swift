//
//  File.swift
//  
//
//  Created by Sergey Armodin on 28.03.2020.
//  Copyright © 2020 Uploadcare, Inc. All rights reserved.
//

import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

public protocol UploadTaskable {
	/// Cancel upload task.
	func cancel()
}

public protocol UploadTaskResumable: UploadTaskable {
	/// Pause uploading.
	func pause()
	/// Resume uploading.
	func resume()
}

/// Simple class that stores upload request and allows to cancel uploading.
class UploadTask: UploadTaskable {
	// MARK: - Internal properties
	
	/// URLSessionUploadTask task. Stored to be able to cancel uploading.
	internal let task: URLSessionUploadTask

	/// Completion handler.
	internal let completionHandler: TaskResultCompletionHandler
	
	/// Progress callback.
	internal let progressCallback: TaskProgressBlock?
	
	/// Data buffer to store response body.
	internal var dataBuffer = Data()
	
	/// URL to file where uploading data stored. Using it because background upload task supports uploading data from files only.
	internal var localDataUrl: URL?
	
	// MARK: - Init
	internal init(task: URLSessionUploadTask, completionHandler: @escaping TaskResultCompletionHandler, progressCallback: TaskProgressBlock? = nil) {
		self.task = task
		self.completionHandler = completionHandler
		self.progressCallback = progressCallback
	}
	
	internal func clear() {
		if let url = localDataUrl {
			try? FileManager.default.removeItem(at: url)
		}
	}
	
	func cancel() {
		task.cancel()
	}
}

class MultipartUploadTask: UploadTaskResumable {
	
	/// Requests array.
	private var requests: [URLSessionDataTask] = []
	/// Is cancelled flag.
	private var _isCancelled: Bool = false
	
	/// Upload API.
	internal weak var queue: DispatchQueue?
	
	/// Queue for adding requests to list.
	private var listQueue = DispatchQueue(label: "com.uploadcare.multipartTasksList")
	
	/// Is uploading cancelled.
	internal var isCancelled: Bool { _isCancelled }

	internal func appendRequest(_ request: URLSessionDataTask) {
		listQueue.sync { [weak self] in
			self?.requests.append(request)
		}
	}
	
	internal func complete() {
		requests.removeAll()
	}

	/// Cancel upload task.
	func cancel() {
		_isCancelled = true
		
		requests.forEach({ $0.cancel() })
		requests.removeAll()
		DLog("task cancelled")
	}

	/// Pause upload task.
	func pause() {
		requests.forEach{ $0.suspend() }
		queue?.suspend()
		DLog("task paused")
	}

	/// Resume upload task.
	func resume() {
		requests.forEach{ $0.resume() }
		queue?.resume()
		DLog("task resumed")
	}
}
