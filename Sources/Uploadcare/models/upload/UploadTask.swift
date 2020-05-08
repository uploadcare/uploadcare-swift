//
//  File.swift
//  
//
//  Created by Sergey Armodin on 28.03.2020.
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
	/// Upload request
	let request: Alamofire.UploadRequest
	
	internal init(request: UploadRequest) {
		self.request = request
	}
	
	func cancel() {
		DLog("task cancelled")
		request.cancel()
	}
}


class MultipartUploadTask: UploadTaskResumable {
	
	/// Requests array
	private var requests: [Alamofire.DataRequest] = []
	/// Is cancelled flag
	private var _isCancelled: Bool = false
	
	/// Upload API
	internal weak var queue: DispatchQueue?
	
	
	/// Is uploading cancelled
	var isCancelled: Bool { _isCancelled }
	
	
	internal func appendRequest(_ request: Alamofire.DataRequest) {
		requests.append(request)
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
