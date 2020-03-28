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


/// Simple class that stores upload request and allows to cancel uploading
class UploadTask: UploadTaskable {
	/// Upload request
	let request: Alamofire.UploadRequest
	
	func cancel() {
		DLog("task cancelled")
		request.cancel()
	}
	
	internal init(request: UploadRequest) {
		self.request = request
	}
}


class MultipartUploadTask: UploadTaskable {
	
	/// Requests array
	private var requests: [Alamofire.DataRequest] = []
	/// Is cancelled flag
	private var _isCancelled: Bool = false
	
	
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
	
	
}
