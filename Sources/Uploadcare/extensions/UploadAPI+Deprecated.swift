//
//  UploadAPI+Deprecated.swift
//  
//
//  Created by Sergey Armodin on 15.06.2022.
//  Copyright © 2022 Uploadcare, Inc. All rights reserved.
//

import Foundation

extension UploadAPI {
	/// File info
	/// - Parameters:
	///   - fileId: File ID
	///   - completionHandler: completion handler
	@available(*, deprecated, message: "Use the same method with Result type in the callback")
	public func fileInfo(
		withFileId fileId: String,
		_ completionHandler: @escaping (UploadedFile?, UploadError?) -> Void
	) {
		fileInfo(withFileId: fileId) { result in
			switch result {
			case .failure(let error): completionHandler(nil, error)
			case .success(let file): completionHandler(file, nil)
			}
		}
	}

	/// Upload file from url
	/// - Parameters:
	///   - task: upload settings
	///   - completionHandler: callback
	@available(*, deprecated, message: "Use the same method with Result type in the callback")
	public func upload(
		task: UploadFromURLTask,
		_ completionHandler: @escaping (UploadFromURLResponse?, UploadError?) -> Void
	) {
		upload(task: task) { result in
			switch result {
			case .failure(let error): completionHandler(nil, error)
			case .success(let responseData): completionHandler(responseData, nil)
			}
		}
	}

	/// Get status for file upload from URL
	/// - Parameters:
	///   - token: token recieved from upload method
	///   - completionHandler: callback
	@available(*, deprecated, message: "Use the same method with Result type in the callback")
	public func uploadStatus(
		forToken token: String,
		_ completionHandler: @escaping (UploadFromURLStatus?, UploadError?) -> Void
	) {
		uploadStatus(forToken: token) { result in
			switch result {
			case .failure(let error): completionHandler(nil, error)
			case .success(let status): completionHandler(status, nil)
			}
		}
	}

	/// Direct upload comply with the RFC 7578 standard and work by making POST requests via HTTPS.
	/// This method uploads data using background URLSession. Uploading will continue even if your app will be closed
	/// - Parameters:
	///   - files: Files dictionary where key is filename, value file in Data format
	///   - store: Sets the file storing behavior
	///   - completionHandler: callback
	@available(*, deprecated, message: "Use the same method with TaskResultCompletionHandler callback")
	@discardableResult
	public func directUpload(
		files: [String: Data],
		store: StoringBehavior? = nil,
		_ onProgress: TaskProgressBlock? = nil,
		_ completionHandler: @escaping TaskCompletionHandler
	) -> UploadTaskable {
		return directUpload(files: files, uploadType: .background, onProgress) { result in
			switch result {
			case .failure(let error): completionHandler(nil, error)
			case .success(let response): completionHandler(response, nil)
			}
		}
	}

	@available(*, deprecated, renamed: "directUpload")
	@discardableResult
	public func upload(
		files: [String: Data],
		store: StoringBehavior? = nil,
		_ onProgress: TaskProgressBlock? = nil,
		_ completionHandler: @escaping TaskCompletionHandler
	) -> UploadTaskable {
		return directUpload(files: files, store: store, onProgress, completionHandler)
	}

	/// Multipart file uploading
	/// - Parameters:
	///   - data: File data
	///   - name: File name
	///   - store: Sets the file storing behavior
	///   - onProgress: A callback that will be used to report upload progress
	///   - completionHandler: Completion handler
	/// - Returns: Upload task. You can use that task to pause, resume or cancel uploading.
	@available(*, deprecated, message: "Use the same method with Result type in the callback")
	@discardableResult
	public func multipartUpload(
		_ data: Data,
		withName name: String,
		store: StoringBehavior? = nil,
		_ onProgress: TaskProgressBlock? = nil,
		_ completionHandler: @escaping (UploadedFile?, UploadError?) -> Void
	) -> UploadTaskResumable {
		return multipartUpload(data, withName: name, store: store, onProgress) { result in
			switch result {
			case .failure(let error): completionHandler(nil, error)
			case .success(let file): completionHandler(file, nil)
			}
		}
	}

	// deprecated on Sep 2021
	@available(*, deprecated, renamed: "directUpload")
	public func upload(
		_ data: Data,
		withName name: String,
		store: StoringBehavior? = nil,
		_ onProgress: TaskProgressBlock? = nil,
		_ completionHandler: @escaping (UploadedFile?, UploadError?) -> Void
	) -> UploadTaskResumable {
		return multipartUpload(data, withName: name, store: store, onProgress, completionHandler)
	}

	/// Create files group from a set of files UUIDs.
	/// - Parameters:
	///   - fileIds: That parameter defines a set of files you want to join in a group. Each parameter can be a file UUID or a CDN URL, with or without applied Media Processing operations.
	///   - completionHandler: callback
	@available(*, deprecated, message: "Use the same method with Result type in the callback")
	public func createFilesGroup(
		fileIds: [String],
		_ completionHandler: @escaping (UploadedFilesGroup?, UploadError?) -> Void
	) {
		createFilesGroup(fileIds: fileIds) { result in
			switch result {
			case .failure(let error): completionHandler(nil, error)
			case .success(let filesGroup): completionHandler(filesGroup, nil)
			}
		}
	}
}
