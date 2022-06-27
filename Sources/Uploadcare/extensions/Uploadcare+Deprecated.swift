//
//  Uploadcare+Deprecated.swift
//  
//
//  Created by Sergey Armodin on 14.06.2022.
//  Copyright © 2022 Uploadcare, Inc. All rights reserved.
//

import Foundation

// MARK: - Deprecated methods
extension Uploadcare {
	/// Get list of files
	/// - Parameters:
	///   - query: query object
	///   - completionHandler: completion handler
	@available(*, deprecated, message: "Use the same method with Result type in the callback")
	public func listOfFiles(withQuery query: PaginationQuery?, _ completionHandler: @escaping (FilesList?, RESTAPIError?) -> Void) {
		listOfFiles(withQueryString: query?.stringValue) { result in
			switch result {
			case .failure(let error): completionHandler(nil, error)
			case .success(let filesList): completionHandler(filesList, nil)
			}
		}
	}

	/// File Info. Once you obtain a list of files, you might want to acquire some file-specific info.
	/// - Parameters:
	///   - uuid: FILE UUID
	///   - completionHandler: completion handler
	@available(*, deprecated, message: "Use the same method with Result type in the callback")
	public func fileInfo(
		withUUID uuid: String,
		_ completionHandler: @escaping (File?, RESTAPIError?) -> Void
	) {
		fileInfo(withUUID: uuid) { result in
			switch result {
			case .failure(let error): completionHandler(nil, error)
			case .success(let file): completionHandler(file, nil)
			}
		}
	}

	/// Delete file. Beside deleting in a multi-file mode, you can remove individual files.
	/// - Parameters:
	///   - uuid: file UUID
	///   - completionHandler: completion handler
	@available(*, deprecated, message: "Use the same method with Result type in the callback")
	public func deleteFile(
		withUUID uuid: String,
		_ completionHandler: @escaping (File?, RESTAPIError?) -> Void
	) {
		deleteFile(withUUID: uuid) { result in
			switch result {
			case .failure(let error): completionHandler(nil, error)
			case .success(let file): completionHandler(file, nil)
			}
		}
	}

	/// Batch file delete. Used to delete multiple files in one go. Up to 100 files are supported per request.
	/// - Parameters:
	///   - uuids: List of files UUIDs to store.
	///   - completionHandler: completion handler
	@available(*, deprecated, message: "Use the same method with Result type in the callback")
	public func deleteFiles(
		withUUIDs uuids: [String],
		_ completionHandler: @escaping (BatchFilesOperationResponse?, RESTAPIError?) -> Void
	) {
		deleteFiles(withUUIDs: uuids) { result in
			switch result {
			case .failure(let error): completionHandler(nil, error)
			case .success(let response): completionHandler(response, nil)
			}
		}
	}

	/// Store a single file by UUID.
	/// - Parameters:
	///   - uuid: file UUID
	///   - completionHandler: completion handler
	@available(*, deprecated, message: "Use the same method with Result type in the callback")
	public func storeFile(
		withUUID uuid: String,
		_ completionHandler: @escaping (File?, RESTAPIError?) -> Void
	) {
		storeFile(withUUID: uuid) { result in
			switch result {
			case .failure(let error): completionHandler(nil, error)
			case .success(let file): completionHandler(file, nil)
			}
		}
	}

	/// Batch file storing. Used to store multiple files in one go. Up to 100 files are supported per request.
	/// - Parameters:
	///   - uuids: List of files UUIDs to store.
	///   - completionHandler: completion handler
	@available(*, deprecated, message: "Use the same method with Result type in the callback")
	public func storeFiles(
		withUUIDs uuids: [String],
		_ completionHandler: @escaping (BatchFilesOperationResponse?, RESTAPIError?) -> Void
	) {
		storeFiles(withUUIDs: uuids) { result in
			switch result {
			case .failure(let error): completionHandler(nil, error)
			case .success(let response): completionHandler(response, nil)
			}
		}
	}

	/// Get list of groups
	/// - Parameters:
	///   - query: query object
	///   - completionHandler: completion handler
	@available(*, deprecated, message: "Use the same method with Result type in the callback")
	public func listOfGroups(
		withQuery query: GroupsListQuery?,
		_ completionHandler: @escaping (GroupsList?, RESTAPIError?) -> Void
	) {
		listOfGroups(withQuery: query) { result in
			switch result {
			case .failure(let error): completionHandler(nil, error)
			case .success(let groupsList): completionHandler(groupsList, nil)
			}
		}
	}

	/// Get a file group by UUID.
	/// - Parameters:
	///   - uuid: Group UUID.
	///   - completionHandler: completion handler
	@available(*, deprecated, message: "Use the same method with Result type in the callback")
	public func groupInfo(
		withUUID uuid: String,
		_ completionHandler: @escaping (Group?, RESTAPIError?) -> Void
	) {
		groupInfo(withUUID: uuid) { result in
			switch result {
			case .failure(let error): completionHandler(nil, error)
			case .success(let group): completionHandler(group, nil)
			}
		}
	}

	/// Copy file to local storage. Used to copy original files or their modified versions to default storage. Source files MAY either be stored or just uploaded and MUST NOT be deleted.
	/// - Parameters:
	///   - source: A CDN URL or just UUID of a file subjected to copy.
	///   - store: The parameter only applies to the Uploadcare storage. Default: "false"
	///   - makePublic: Applicable to custom storage only. True to make copied files available via public links, false to reverse the behavior. Default: "true"
	///   - completionHandler: completion handler
	@available(*, deprecated, message: "Use the same method with Result type in the callback")
	public func copyFileToLocalStorage(
		source: String,
		store: Bool? = nil,
		makePublic: Bool? = nil,
		_ completionHandler: @escaping (CopyFileToLocalStorageResponse?, RESTAPIError?) -> Void
	) {
		copyFileToLocalStorage(source: source, store: store, makePublic: makePublic) { result in
			switch result {
			case .failure(let error): completionHandler(nil, error)
			case .success(let response): completionHandler(response, nil)
			}
		}
	}

	/// POST requests are used to copy original files or their modified versions to a custom storage. Source files MAY either be stored or just uploaded and MUST NOT be deleted.
	/// - Parameters:
	///   - source: A CDN URL or just UUID of a file subjected to copy.
	///   - target: Identifies a custom storage name related to your project. Implies you are copying a file to a specified custom storage. Keep in mind you can have multiple storages associated with a single S3 bucket.
	///   - makePublic: MUST be either true or false. true to make copied files available via public links, false to reverse the behavior.
	///   - pattern: The parameter is used to specify file names Uploadcare passes to a custom storage. In case the parameter is omitted, we use pattern of your custom storage. Use any combination of allowed values.
	///   - completionHandler: completion handler
	@available(*, deprecated, message: "Use the same method with Result type in the callback")
	public func copyFileToRemoteStorage(
		source: String,
		target: String,
		makePublic: Bool? = nil,
		pattern: NamesPattern?,
		_ completionHandler: @escaping (CopyFileToRemoteStorageResponse?, RESTAPIError?) -> Void
	) {
		copyFileToRemoteStorage(source: source, target: target, makePublic: makePublic, pattern: pattern) { result in
			switch result {
			case .failure(let error): completionHandler(nil, error)
			case .success(let response): completionHandler(response, nil)
			}
		}
	}

	/// Getting info about account project.
	/// - Parameter completionHandler: completion handler
	@available(*, deprecated, message: "Use the same method with Result type in the callback")
	public func getProjectInfo(_ completionHandler: @escaping (Project?, RESTAPIError?) -> Void) {
		getProjectInfo { result in
			switch result {
			case .failure(let error): completionHandler(nil, error)
			case .success(let project): completionHandler(project, nil)
			}
		}
	}

	/// This method allows you to get authonticated url from your backend using redirect.
	/// By request to that url your backend should generate authenticated url to your file and perform REDIRECT to generated url.
	/// Redirect url will be caught and returned in completion handler of that method
	///
	/// Example of URL: https://yourdomain.com/{UUID}/
	/// Redirect to: https://cdn.yourdomain.com/{uuid}/?token={token}&expire={timestamp}
	///
	/// URL for redirect will be returned in completion handler
	///
	/// More details in documentation: https://uploadcare.com/docs/delivery/file_api/#authenticated-urls
	///
	/// - Parameters:
	///   - url: url for request to your backend
	///   - completionHandler: completion handler
	@available(*, deprecated, message: "Use the same method with Result type in the callback")
	public func getAuthenticatedUrlFromUrl(_ url: URL, _ completionHandler: @escaping (String?, RESTAPIError?) -> Void) {
		getAuthenticatedUrlFromUrl(url) { result in
			switch result {
			case .failure(let error): completionHandler(nil, error)
			case .success(let urlString): completionHandler(urlString, nil)
			}
		}
	}

	/// List of project webhooks.
	/// - Parameter completionHandler: completion handler
	@available(*, deprecated, message: "Use the same method with Result type in the callback")
	public func getListOfWebhooks(_ completionHandler: @escaping ([Webhook]?, RESTAPIError?) -> Void) {
		getListOfWebhooks { result in
			switch result {
			case .failure(let error): completionHandler(nil, error)
			case .success(let webhooks): completionHandler(webhooks, nil)
			}
		}
	}

	/// Create webhook
	/// - Parameters:
	///   - targetUrl: A URL that is triggered by an event, for example, a file upload. A target URL MUST be unique for each project — event type combination.
	///   - isActive: Marks a subscription as either active or not, defaults to true, otherwise false.
	///   - signingSecret: Optional secret that, if set, will be used to calculate signatures for the webhook payloads
	///   - completionHandler: completion handler
	@available(*, deprecated, message: "Use the same method with Result type in the callback")
	public func createWebhook(targetUrl: URL, isActive: Bool, signingSecret: String? = nil, _ completionHandler: @escaping (Webhook?, RESTAPIError?) -> Void) {
		createWebhook(targetUrl: targetUrl, isActive: isActive, signingSecret: signingSecret) { result in
			switch result {
			case .failure(let error): completionHandler(nil, error)
			case .success(let webhook): completionHandler(webhook, nil)
			}
		}
	}

	/// Update webhook attributes
	/// - Parameters:
	///   - id: Webhook ID
	///   - targetUrl: Where webhook data will be posted.
	///   - isActive: Marks a subscription as either active or not
	///   - signingSecret: Optional secret that, if set, will be used to calculate signatures for the webhook payloads
	///   - completionHandler: completion handler
	@available(*, deprecated, message: "Use the same method with Result type in the callback")
	public func updateWebhook(id: Int, targetUrl: URL, isActive: Bool, signingSecret: String? = nil, _ completionHandler: @escaping (Webhook?, RESTAPIError?) -> Void) {
		updateWebhook(id: id, targetUrl: targetUrl, isActive: isActive, signingSecret: signingSecret) { result in
			switch result {
			case .failure(let error): completionHandler(nil, error)
			case .success(let webhook): completionHandler(webhook, nil)
			}
		}
	}

	/// Uploadcare allows converting documents to the following target formats: DOC, DOCX, XLS, XLSX, ODT, ODS, RTF, TXT, PDF, JPG, PNG.
	/// - Parameters:
	///   - paths: An array of UUIDs of your source documents to convert together with the specified target format.
	///   See documentation: https://uploadcare.com/docs/transformations/document_conversion/#convert-url-formatting
	///   - store: A flag indicating if we should store your outputs.
	///   - completionHandler: completion handler
	@available(*, deprecated, message: "Use the same method with Result type in the callback")
	public func convertDocuments(
		_ paths: [String],
		store: StoringBehavior? = nil,
		_ completionHandler: @escaping (ConvertDocumentsResponse?, RESTAPIError?) -> Void
	) {
		convertDocuments(paths, store: store) { result in
			switch result {
			case .failure(let error): completionHandler(nil, error)
			case .success(let response): completionHandler(response, nil)
			}
		}
	}

	/// Convert documents
	/// - Parameters:
	///   - files: files array
	///   - format: target format (DOC, DOCX, XLS, XLSX, ODT, ODS, RTF, TXT, PDF, JPG, PNG)
	///   - store: A flag indicating if we should store your outputs.
	///   - completionHandler: completion handler
	@available(*, deprecated, message: "Use the same method with Result type in the callback")
	public func convertDocumentsWithSettings(
		_ tasks: [DocumentConversionJobSettings],
		store: StoringBehavior? = nil,
		_ completionHandler: @escaping (ConvertDocumentsResponse?, RESTAPIError?) -> Void
	) {
		convertDocumentsWithSettings(tasks, store: store) { result in
			switch result {
			case .failure(let error): completionHandler(nil, error)
			case .success(let response): completionHandler(response, nil)
			}
		}
	}

	/// Document conversion job status
	/// - Parameters:
	///   - token: Job token
	///   - completionHandler: completion handler
	@available(*, deprecated, message: "Use the same method with Result type in the callback")
	public func documentConversionJobStatus(token: Int, _ completionHandler: @escaping (ConvertDocumentJobStatus?, RESTAPIError?) -> Void) {
		documentConversionJobStatus(token: token) { result in
			switch result {
			case .failure(let error): completionHandler(nil, error)
			case .success(let status): completionHandler(status, nil)
			}
		}
	}

	/// Convert videos with settings
	/// - Parameters:
	///   - tasks: array of VideoConversionJobSettings objects which settings for conversion for every file
	///   - store: A flag indicating if we should store your outputs.
	///   - completionHandler: completion handler
	@available(*, deprecated, message: "Use the same method with Result type in the callback")
	public func convertVideosWithSettings(
		_ tasks: [VideoConversionJobSettings],
		store: StoringBehavior? = nil,
		_ completionHandler: @escaping (ConvertDocumentsResponse?, RESTAPIError?) -> Void
	) {
		convertVideosWithSettings(tasks, store: store) { result in
			switch result {
			case .failure(let error): completionHandler(nil, error)
			case .success(let response): completionHandler(response, nil)
			}
		}
	}

	/// Convert videos
	/// - Parameters:
	///   - paths: An array of UUIDs of your video files to process together with a set of needed operations.
	///   See documentation: https://uploadcare.com/docs/transformations/video_encoding/#process-operations
	///   - store: A flag indicating if we should store your outputs.
	///   - completionHandler: completion handler
	@available(*, deprecated, message: "Use the same method with Result type in the callback")
	public func convertVideos(
		_ paths: [String],
		store: StoringBehavior? = nil,
		_ completionHandler: @escaping (ConvertDocumentsResponse?, RESTAPIError?) -> Void
	) {
		convertVideos(paths, store: store) { result in
			switch result {
			case .failure(let error): completionHandler(nil, error)
			case .success(let response): completionHandler(response, nil)
			}
		}
	}

	/// Video conversion job status
	/// - Parameters:
	///   - token: Job token
	///   - completionHandler: completion handler
	@available(*, deprecated, message: "Use the same method with Result type in the callback")
	public func videoConversionJobStatus(token: Int, _ completionHandler: @escaping (ConvertVideoJobStatus?, RESTAPIError?) -> Void) {
		videoConversionJobStatus(token: token) { result in
			switch result {
			case .failure(let error): completionHandler(nil, error)
			case .success(let status): completionHandler(status, nil)
			}
		}
	}

	/// Upload file. This method will decide internally which upload will be used (direct or multipart)
	/// - Parameters:
	///   - data: File data
	///   - name: File name
	///   - store: Sets the file storing behavior
	///   - onProgress: A callback that will be used to report upload progress
	///   - completionHandler: Completion handler
	/// - Returns: Upload task. Confirms to UploadTaskable protocol in anycase. Might confirm to UploadTaskResumable protocol (which inherits UploadTaskable)  if multipart upload was used so you can pause and resume upload
	@available(*, deprecated, message: "Use the same method with Result type in the callback")
	@discardableResult
	public func uploadFile(
		_ data: Data,
		withName name: String,
		store: StoringBehavior? = nil,
		_ onProgress: ((Double) -> Void)? = nil,
		_ completionHandler: @escaping (UploadedFile?, UploadError?) -> Void
	) -> UploadTaskable {
		return uploadFile(data, withName: name, store: store, onProgress) { result in
			switch result {
			case .failure(let error): completionHandler(nil, error)
			case .success(let file): completionHandler(file, nil)
			}
		}
	}
}
