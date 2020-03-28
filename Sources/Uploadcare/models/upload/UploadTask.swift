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
