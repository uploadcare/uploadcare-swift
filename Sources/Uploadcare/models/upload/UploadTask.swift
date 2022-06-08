//
//  File.swift
//  
//
//  Created by Sergey Armodin on 28.03.2020.
//  Copyright © 2020 Uploadcare, Inc. All rights reserved.
//

import Foundation
import Alamofire


public protocol UploadTaskable {
	/// Cancel upload task
	func cancel()
}

public protocol UploadTaskResumable: UploadTaskable {
	/// Pause uploading
	func pause()
	/// Resume uploading
	func resume()
}

/// Simple class that stores upload request and allows to cancel uploading
class UploadTask: UploadTaskable {
	// MARK: - Internal properties
	
	/// URLSessionUploadTask task. Stored to be able to cancel uploading
	internal let task: URLSessionUploadTask

	/// Completion handler
	internal let completionHandler: TaskCompletionHandler
	
	/// Progress callback
	internal let progressCallback: TaskProgressBlock?
	
	/// Data buffer to store response body
	internal var dataBuffer = Data()
	
	/// URL to file where uploading data stored. Using it because background upload task supports uploading data from files only
	internal var localDataUrl: URL?
	
	// MARK: - Init
	internal init(task: URLSessionUploadTask, completionHandler: @escaping TaskCompletionHandler, progressCallback: TaskProgressBlock? = nil) {
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
	
	/// Requests array
	private var requests: [Alamofire.DataRequest] = []
	/// Is cancelled flag
	private var _isCancelled: Bool = false
	
	/// Upload API
	internal weak var queue: DispatchQueue?
	
	/// Queue for adding requests to list
	private var listQueue = DispatchQueue(label: "com.uploadcare.multipartTasksList")
	
	/// Is uploading cancelled
	internal var isCancelled: Bool { _isCancelled }
	
	
	internal func appendRequest(_ request: Alamofire.DataRequest) {
		listQueue.sync { [weak self] in
			self?.requests.append(request)
		}
	}
	
	internal func complete() {
		requests.removeAll()
	}
	
	func cancel() {
		_isCancelled = true
		
		requests.forEach({ $0.cancel() })
		requests.removeAll()
		DLog("task cancelled")
	}
	
	func pause() {
		requests.forEach{ $0.task?.suspend() }
		queue?.suspend()
		DLog("task paused")
	}
	
	func resume() {
		requests.forEach{ $0.task?.resume() }
		queue?.resume()
		DLog("task resumed")
	}
}
