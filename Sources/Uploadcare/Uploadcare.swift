//
//  Uploadcare.swift
//
//
//  Created by Sergey Armodin on 03.02.2020.
//  Copyright © 2020 Uploadcare, Inc. All rights reserved.
//

import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif


public class Uploadcare: NSObject {

	/// Authentication scheme for REST API requests
	/// More information about authentication: https://uploadcare.com/docs/api_reference/rest/requests_auth/#rest-api-requests-and-authentication
	public enum AuthScheme: String {
		case simple = "Uploadcare.Simple"
		case signed = "Uploadcare"
	}
	
	/// Uploadcare authentication method
	public var authScheme: AuthScheme = .signed {
		didSet {
			requestManager.authScheme = authScheme
		}
	}
	

	// MARK: - Public properties
	public var uploadAPI: UploadAPI

	
	// MARK: - Private properties
	/// Public Key.  It is required when using Upload API.
	internal var publicKey: String

	/// Secret Key. Optional. Is used for authorization
	internal var secretKey: String?

	/// Performs network requests
	internal let requestManager: RequestManager

	private var redirectValues = [String: String]()
	
	
	/// Initialization
	/// - Parameter publicKey: Public Key.  It is required when using Upload API.
	public init(withPublicKey publicKey: String, secretKey: String? = nil) {
		self.publicKey = publicKey
		self.secretKey = secretKey
		self.requestManager = RequestManager(publicKey: publicKey, secretKey: secretKey)

		self.uploadAPI = UploadAPI(withPublicKey: publicKey, secretKey: secretKey, requestManager: self.requestManager)
	}
	
	
	/// Method for integration testing
	public static func sayHi() {
		print("Uploadcare says Hi!")
	}
}


// MARK: - Private methods
internal extension Uploadcare {
	func urlWithPath(_ path: String) -> URL {
		var urlComponents = URLComponents()
		urlComponents.scheme = "https"
		urlComponents.host = RESTAPIHost
		urlComponents.path = path

		guard let url = urlComponents.url else {
			fatalError("incorrect url")
		}
		return url
	}
}


// MARK: - REST API
extension Uploadcare {
	#if !os(Linux)
	/// Get list of files.
	///
	/// Example:
	/// ```swift
	/// let query = PaginationQuery()
	///     .stored(true)
	///     .ordering(.dateTimeUploadedDESC)
	///     .limit(5)
	///
	/// uploadcare.listOfFiles(withQuery: query) { result in
	///     switch result {
	///     case .failure(let error):
	///         print(error)
	///     case .success(let list):
	///         print(list)
	///     }
	/// }
	/// ```
	///
	/// - Parameters:
	///   - query: Query object.
	///   - completionHandler: Completion handler.
	public func listOfFiles(withQuery query: PaginationQuery?, _ completionHandler: @escaping (Result<FilesList, RESTAPIError>) -> Void) {
		listOfFiles(withQueryString: query?.stringValue, completionHandler)
	}
	#endif

	/// Get list of files.
	///
	/// Example:
	/// ```swift
	/// let query = PaginationQuery()
	///     .stored(true)
	///     .ordering(.dateTimeUploadedDESC)
	///     .limit(5)
	///
	/// let list = try await uploadcare.listOfFiles(withQuery: query)
	/// print(list)
	/// ```
	///
	/// - Parameter query: Query object.
	/// - Returns: List of files.
	@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
	public func listOfFiles(withQuery query: PaginationQuery?) async throws -> FilesList {
		return try await listOfFiles(withQueryString: query?.stringValue)
	}

	#if !os(Linux)
    internal func listOfFiles(
        withQueryString query: String?,
        _ completionHandler: @escaping (Result<FilesList, RESTAPIError>) -> Void
    ) {
        var urlString = RESTAPIBaseUrl + "/files/"
        if let queryValue = query {
            urlString += "?\(queryValue)"
        }

        guard let url = URL(string: urlString) else {
            assertionFailure("Incorrect url")
            return
        }

        var urlRequest = requestManager.makeUrlRequest(fromURL: url, method: .get)
        requestManager.signRequest(&urlRequest)
        requestManager.performRequest(urlRequest) { (result: Result<FilesList, Error>) in
            switch result {
            case .failure(let error): completionHandler(.failure(RESTAPIError.fromError(error)))
            case .success(let filesList): completionHandler(.success(filesList))
            }
        }
    }
	#endif

	@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
	internal func listOfFiles(withQueryString query: String?) async throws -> FilesList {
		var urlString = RESTAPIBaseUrl + "/files/"
		if let queryValue = query {
			urlString += "?\(queryValue)"
		}

		guard let url = URL(string: urlString) else {
			assertionFailure("Incorrect url")
			throw RESTAPIError.defaultError()
		}

		var urlRequest = requestManager.makeUrlRequest(fromURL: url, method: .get)
		requestManager.signRequest(&urlRequest)

		do {
			let filesList: FilesList = try await requestManager.performRequest(urlRequest)
			return filesList
		} catch {
			throw RESTAPIError.fromError(error)
		}
	}

	#if !os(Linux)
	/// Store a single file by UUID.
	///
	/// Example:
	/// ```swift
	/// uploadcare.storeFile(withUUID: "fileUUID") { result in
	///     switch result {
	///     case .failure(let error):
	///         print(error)
	///     case .success(let file):
	///         print(file)
	///     }
	/// }
	/// ```
	///
	/// - Parameters:
	///   - uuid: File UUID.
	///   - completionHandler: Completion handler.
	public func storeFile(
		withUUID uuid: String,
		_ completionHandler: @escaping (Result<File, RESTAPIError>) -> Void
	) {
		let url = urlWithPath("/files/\(uuid)/storage/")
		var urlRequest = requestManager.makeUrlRequest(fromURL: url, method: .put)
		requestManager.signRequest(&urlRequest)

		requestManager.performRequest(urlRequest) { (result: Result<File, Error>) in
			switch result {
			case .failure(let error): completionHandler(.failure(RESTAPIError.fromError(error)))
			case .success(let file): completionHandler(.success(file))
			}
		}
	}
	#endif
	
	/// Store a single file by UUID.
	///
	/// Example:
	/// ```swift
	/// let file = try await uploadcare.storeFile(withUUID: "someUUID")
	/// ```
	///
	/// - Parameter uuid: File UUID.
	/// - Returns: File data.
	@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
	public func storeFile(withUUID uuid: String) async throws -> File {
		let url = urlWithPath("/files/\(uuid)/storage/")
		var urlRequest = requestManager.makeUrlRequest(fromURL: url, method: .put)
		requestManager.signRequest(&urlRequest)

		do {
			let file: File = try await requestManager.performRequest(urlRequest)
			return file
		} catch {
			throw RESTAPIError.fromError(error)
		}
	}

	#if !os(Linux)
	/// Batch file storing. Used to store multiple files in one go. Up to 100 files are supported per request.
	///
	/// Example:
	/// ```swift
	/// uploadcare.storeFiles(withUUIDs: ["fileUUID"]) { result in
	///     switch result {
	///     case .failure(let error):
	///         print(error)
	///     case .success(let response):
	///         print(response)
	///     }
	/// }
	/// ```
	///
	/// - Parameters:
	///   - uuids: List of files UUIDs to store.
	///   - completionHandler: Completion handler.
	public func storeFiles(
		withUUIDs uuids: [String],
		_ completionHandler: @escaping (Result<BatchFilesOperationResponse, RESTAPIError>) -> Void
	) {
		let url = urlWithPath("/files/storage/")
		var urlRequest = requestManager.makeUrlRequest(fromURL: url, method: .put)

		if let body = try? JSONEncoder().encode(uuids) {
			urlRequest.httpBody = body
		}
		requestManager.signRequest(&urlRequest)

		requestManager.performRequest(urlRequest) { (result: Result<BatchFilesOperationResponse, Error>) in
			switch result {
			case .failure(let error): completionHandler(.failure(RESTAPIError.fromError(error)))
			case .success(let response): completionHandler(.success(response))
			}
		}
	}
	#endif
	
	/// Batch file storing. Used to store multiple files in one go. Up to 100 files are supported per request.
	///
	/// Example:
	/// ```swift
	/// let response = try await uploadcare.storeFiles(withUUIDs: ["uuid1", "uuid2"])
	/// print(response)
	/// ```
	///
	/// - Parameter uuids: List of files UUIDs to store.
	/// - Returns: Operation response.
	@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
	public func storeFiles(withUUIDs uuids: [String]) async throws -> BatchFilesOperationResponse {
		let url = urlWithPath("/files/storage/")
		var urlRequest = requestManager.makeUrlRequest(fromURL: url, method: .put)

		if let body = try? JSONEncoder().encode(uuids) {
			urlRequest.httpBody = body
		}
		requestManager.signRequest(&urlRequest)

		do {
			let response: BatchFilesOperationResponse = try await requestManager.performRequest(urlRequest)
			return response
		} catch {
			throw RESTAPIError.fromError(error)
		}
	}

	#if !os(Linux)
	/// File Info. Once you obtain a list of files, you might want to acquire some file-specific info.
	///
	/// Example:
	/// ```swift
	/// uploadcare.fileInfo(withUUID: "fileUUID", withQueryString: "include=appdata") { result in
	///     switch result {
	///     case .failure(let error):
	///         print(error)
	///     case .success(let file):
	///         print(file)
	///     }
	/// }
	/// ```
	///
	/// - Parameters:
	///   - uuid: File UUID.
	///   - query: Query parameters string.
	///   - completionHandler: Completion handler.
	public func fileInfo(
		withUUID uuid: String,
		withQueryString query: String? = nil,
		_ completionHandler: @escaping (Result<File, RESTAPIError>) -> Void
	) {
		var urlString = RESTAPIBaseUrl + "/files/\(uuid)/"
		if let queryValue = query {
			urlString += "?\(queryValue)"
		}

		guard let url = URL(string: urlString) else {
			assertionFailure("Incorrect url")
			completionHandler(.failure(RESTAPIError.init(detail: "Incorrect url")))
			return
		}

		var urlRequest = requestManager.makeUrlRequest(fromURL: url, method: .get)
		requestManager.signRequest(&urlRequest)

		requestManager.performRequest(urlRequest) { (result: Result<File, Error>) in
			switch result {
			case .failure(let error): completionHandler(.failure(RESTAPIError.fromError(error)))
			case .success(let file): completionHandler(.success(file))
			}
		}
	}
	#endif

	/// File Info. Once you obtain a list of files, you might want to acquire some file-specific info.
	///
	/// Example:
	/// ```swift
	/// let fileInfoQuery = FileInfoQuery().include(.appdata)
	/// let file = try await uploadcare.fileInfo(
	///     withUUID: "fileUUID",
	///     withQueryString: "include=appdata"
	/// )
	/// print(file)
	/// ```
	///
	/// - Parameters:
	///   - uuid: File UUID.
	///   - query: Query parameters string.
	/// - Returns: File info.
	@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
	public func fileInfo(withUUID uuid: String, withQueryString query: String? = nil) async throws -> File {
		var urlString = RESTAPIBaseUrl + "/files/\(uuid)/"
		if let queryValue = query {
			urlString += "?\(queryValue)"
		}

		guard let url = URL(string: urlString) else {
			throw RESTAPIError.init(detail: "Incorrect url")
		}

		var urlRequest = requestManager.makeUrlRequest(fromURL: url, method: .get)
		requestManager.signRequest(&urlRequest)

		do {
			let file: File = try await requestManager.performRequest(urlRequest)
			return file
		} catch let error {
			throw RESTAPIError.fromError(error)
		}
	}

	#if !os(Linux)
	/// File Info. Once you obtain a list of files, you might want to acquire some file-specific info.
	///
	/// Example:
	/// ```swift
	/// let fileInfoQuery = FileInfoQuery().include(.appdata)
	/// uploadcare.fileInfo(withUUID: "fileUUID", withQuery: fileInfoQuery) { result in
	///     switch result {
	///     case .failure(let error):
	///         print(error)
	///     case .success(let file):
	///         print(file)
	///     }
	/// }
	/// ```
	///
	/// - Parameters:
	///   - uuid: File UUID.
	///   - query: Query parameters.
	///   - completionHandler: Completion handler.
	public func fileInfo(
		withUUID uuid: String,
		withQuery query: FileInfoQuery,
		_ completionHandler: @escaping (Result<File, RESTAPIError>) -> Void
	) {
		fileInfo(withUUID: uuid, withQueryString: query.stringValue, completionHandler)
	}
	#endif

	/// File Info. Once you obtain a list of files, you might want to acquire some file-specific info.
	///
	/// Example:
	/// ```swift
	/// let fileInfoQuery = FileInfoQuery().include(.appdata)
	/// let file = try await uploadcare.fileInfo(
	///     withUUID: "fileUUID",
	///     withQuery: fileInfoQuery
	/// )
	/// print(file)
	/// ```
	///
	/// - Parameters:
	///   - uuid: File UUID.
	///   - query: Query parameters.
	/// - Returns: File info.
	@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
	public func fileInfo(withUUID uuid: String, withQuery query: FileInfoQuery) async throws -> File {
		return try await fileInfo(withUUID: uuid, withQueryString: query.stringValue)
	}

	#if !os(Linux)
	/// Delete file. Beside deleting in a multi-file mode, you can remove individual files.
	///
	/// Example:
	/// ```swift
	/// uploadcare.deleteFile(withUUID: uuid) { result in
	///     switch result {
	///     case .failure(let error):
	///         print(error)
	///     case .success(let file):
	///         print(file)
	///     }
	/// }
	/// ```
	///
	/// - Parameters:
	///   - uuid: File UUID.
	///   - completionHandler: Completion handler.
	public func deleteFile(
		withUUID uuid: String,
		_ completionHandler: @escaping (Result<File, RESTAPIError>) -> Void
	) {
		let url = urlWithPath("/files/\(uuid)/storage/")
		var urlRequest = requestManager.makeUrlRequest(fromURL: url, method: .delete)
		requestManager.signRequest(&urlRequest)

		requestManager.performRequest(urlRequest) { (result: Result<File, Error>) in
			switch result {
			case .failure(let error): completionHandler(.failure(RESTAPIError.fromError(error)))
			case .success(let file): completionHandler(.success(file))
			}
		}
	}
	#endif
	
	/// Delete file. Beside deleting in a multi-file mode, you can remove individual files.
	///
	/// Example:
	/// ```swift
	/// let file = try await uploadcare.deleteFile(withUUID: "fileUUID")
	/// // or
	/// try await uploadcare.deleteFile(withUUID: "fileUUID")
	/// ```
	///
	/// - Parameter uuid: File UUID.
	/// - Returns: Deleted file data.
	@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
	@discardableResult
	public func deleteFile(withUUID uuid: String) async throws -> File {
		let url = urlWithPath("/files/\(uuid)/storage/")
		var urlRequest = requestManager.makeUrlRequest(fromURL: url, method: .delete)
		requestManager.signRequest(&urlRequest)

		do {
			let file: File = try await requestManager.performRequest(urlRequest)
			return file
		} catch let error {
			throw RESTAPIError.fromError(error)
		}
	}

	#if !os(Linux)
	/// Batch file delete. Used to delete multiple files in one go. Up to 100 files are supported per request.
	///
	/// Example:
	/// ```swift
	/// uploadcare.deleteFiles(withUUIDs: ["uuid1", "uuid2"]) { result in
	///     switch result {
	///     case .failure(let error):
	///         print(error)
	///     case .success(let response):
	///         print(response)
	///     }
	/// }
	/// ```
	///
	/// - Parameters:
	///   - uuids: List of files UUIDs to store.
	///   - completionHandler: completion handler
	public func deleteFiles(
		withUUIDs uuids: [String],
		_ completionHandler: @escaping (Result<BatchFilesOperationResponse, RESTAPIError>) -> Void
	) {
		let url = urlWithPath("/files/storage/")
		var urlRequest = requestManager.makeUrlRequest(fromURL: url, method: .delete)

		if let body = try? JSONEncoder().encode(uuids) {
			urlRequest.httpBody = body
		}
		requestManager.signRequest(&urlRequest)

		requestManager.performRequest(urlRequest) { (result: Result<BatchFilesOperationResponse, Error>) in
			switch result {
			case .failure(let error): completionHandler(.failure(RESTAPIError.fromError(error)))
			case .success(let response): completionHandler(.success(response))
			}
		}
	}
	#endif
	
	/// Batch file delete. Used to delete multiple files in one go. Up to 100 files are supported per request.
	///
	/// Example:
	/// ```swift
	/// let response = try await uploadcare.deleteFiles(withUUIDs: ["uuid1", "uuid2"])
	/// print(response)
	/// ```
	///
	/// - Parameter uuids: List of files UUIDs to store.
	/// - Returns: Operation response.
	@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
	@discardableResult
	public func deleteFiles(withUUIDs uuids: [String]) async throws -> BatchFilesOperationResponse {
		let url = urlWithPath("/files/storage/")
		var urlRequest = requestManager.makeUrlRequest(fromURL: url, method: .delete)

		if let body = try? JSONEncoder().encode(uuids) {
			urlRequest.httpBody = body
		}
		requestManager.signRequest(&urlRequest)

		do {
			let response: BatchFilesOperationResponse = try await requestManager.performRequest(urlRequest)
			return response
		} catch let error {
			throw RESTAPIError.fromError(error)
		}
	}

	#if !os(Linux)
	/// Copy file to local storage. Used to copy original files or their modified versions to default storage. Source files MAY either be stored or just uploaded and MUST NOT be deleted.
	///
	/// Example:
	/// ```swift
	/// uploadcare.copyFileToLocalStorage(source: "fileUUID") { result in
	///     switch result {
	///     case .failure(let error):
	///         print(error)
	///     case .success(let response):
	///         print(response)
	///     }
	/// }
	/// ```
	///
	/// - Parameters:
	///   - source: A CDN URL or just UUID of a file subjected to copy.
	///   - store: The parameter only applies to the Uploadcare storage. Default: "false"
	///   - makePublic: Applicable to custom storage only. True to make copied files available via public links, false to reverse the behavior. Default: "true"
	///   - completionHandler: Completion handler.
	public func copyFileToLocalStorage(
		source: String,
		store: Bool? = nil,
		makePublic: Bool? = nil,
		_ completionHandler: @escaping (Result<CopyFileToLocalStorageResponse, RESTAPIError>) -> Void
	) {
		let url = urlWithPath("/files/local_copy/")
		var urlRequest = requestManager.makeUrlRequest(fromURL: url, method: .post)

		let bodyDictionary = [
			"source": source,
			"store": "\(store ?? false)",
			"make_public": "\(makePublic ?? true)"
		]
		if let body = try? JSONEncoder().encode(bodyDictionary) {
			urlRequest.httpBody = body
		}
		requestManager.signRequest(&urlRequest)

		requestManager.performRequest(urlRequest) { (result: Result<CopyFileToLocalStorageResponse, Error>) in
			switch result {
			case .failure(let error): completionHandler(.failure(RESTAPIError.fromError(error)))
			case .success(let response): completionHandler(.success(response))
			}
		}
	}
	#endif
	
	/// Copy file to local storage. Used to copy original files or their modified versions to default storage. Source files MAY either be stored or just uploaded and MUST NOT be deleted.
	///
	/// Example:
	/// ```swift
	/// let response = try await uploadcare.copyFileToLocalStorage(source: "fileUUID")
	/// print(response)
	/// ```
	/// - Parameters:
	///   - source: A CDN URL or just UUID of a file subjected to copy.
	///   - store: The parameter only applies to the Uploadcare storage. Default: `false`
	///   - makePublic: Applicable to custom storage only. True to make copied files available via public links, false to reverse the behavior. Default: `true`
	/// - Returns: Operation response.
	@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
	public func copyFileToLocalStorage(source: String, store: Bool? = nil, makePublic: Bool? = nil) async throws -> CopyFileToLocalStorageResponse {
		let url = urlWithPath("/files/local_copy/")
		var urlRequest = requestManager.makeUrlRequest(fromURL: url, method: .post)

		let bodyDictionary = [
			"source": source,
			"store": "\(store ?? false)",
			"make_public": "\(makePublic ?? true)"
		]
		urlRequest.httpBody = try? JSONEncoder().encode(bodyDictionary)
		requestManager.signRequest(&urlRequest)

		do {
			let response: CopyFileToLocalStorageResponse = try await requestManager.performRequest(urlRequest)
			return response
		} catch let error {
			throw RESTAPIError.fromError(error)
		}
	}

	#if !os(Linux)
	/// POST requests are used to copy original files or their modified versions to a custom storage. Source files MAY either be stored or just uploaded and MUST NOT be deleted.
	///
	/// Example:
	/// ```swift
	/// uploadcare.copyFileToRemoteStorage(source: "fileUUID", target: "one_more_project", pattern: .uuid) { result in
	///     switch result {
	///     case .failure(let error):
	///         print(error)
	///     case .success(let response):
	///         print(response)
	///     }
	/// }
	/// ```
	///
	/// - Parameters:
	///   - source: A CDN URL or just UUID of a file subjected to copy.
	///   - target: Identifies a custom storage name related to your project. Implies you are copying a file to a specified custom storage. Keep in mind you can have multiple storages associated with a single S3 bucket.
	///   - makePublic: MUST be either true or false. true to make copied files available via public links, false to reverse the behavior.
	///   - pattern: The parameter is used to specify file names Uploadcare passes to a custom storage. In case the parameter is omitted, we use pattern of your custom storage. Use any combination of allowed values.
	///   - completionHandler: Completion handler.
	public func copyFileToRemoteStorage(
		source: String,
		target: String,
		makePublic: Bool? = nil,
		pattern: NamesPattern?,
		_ completionHandler: @escaping (Result<CopyFileToRemoteStorageResponse, RESTAPIError>) -> Void
	) {
		let url = urlWithPath("/files/remote_copy/")
		var urlRequest = requestManager.makeUrlRequest(fromURL: url, method: .post)

		var bodyDictionary = [
			"source": source,
			"target": target
		]

		if let makePublicVal = makePublic {
			bodyDictionary["make_public"] = "\(makePublicVal)"
		}
		if let patternVal = pattern {
			bodyDictionary["pattern"] = patternVal.rawValue
		}

		if let body = try? JSONEncoder().encode(bodyDictionary) {
			urlRequest.httpBody = body
		}
		requestManager.signRequest(&urlRequest)

		requestManager.performRequest(urlRequest) { (result: Result<CopyFileToRemoteStorageResponse, Error>) in
			switch result {
			case .failure(let error): completionHandler(.failure(RESTAPIError.fromError(error)))
			case .success(let response): completionHandler(.success(response))
			}
		}
	}
	#endif
	
	/// POST requests are used to copy original files or their modified versions to a custom storage. Source files MAY either be stored or just uploaded and MUST NOT be deleted.
	///
	/// Example:
	/// ```swift
	/// let source = "fileUUID"
	/// let response = try await uploadcare.copyFileToRemoteStorage(
	///     source: source,
	///     target: "one_more_project",
	///     pattern: .uuid
	/// )
	/// print(response)
	/// ```
	/// - Parameters:
	///   - source: A CDN URL or just UUID of a file subjected to copy.
	///   - target: Identifies a custom storage name related to your project. Implies you are copying a file to a specified custom storage. Keep in mind you can have multiple storages associated with a single S3 bucket.
	///   - makePublic: MUST be either `true` or `false`. `true` to make copied files available via public links, `false` to reverse the behavior.
	///   - pattern: The parameter is used to specify file names Uploadcare passes to a custom storage. In case the parameter is omitted, we use pattern of your custom storage. Use any combination of allowed values.
	/// - Returns: Operation response.
	@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
	public func copyFileToRemoteStorage(
		source: String,
		target: String,
		makePublic: Bool? = nil,
		pattern: NamesPattern?
	) async throws -> CopyFileToRemoteStorageResponse {
		let url = urlWithPath("/files/remote_copy/")
		var urlRequest = requestManager.makeUrlRequest(fromURL: url, method: .post)

		var bodyDictionary = [
			"source": source,
			"target": target
		]

		if let makePublicVal = makePublic {
			bodyDictionary["make_public"] = "\(makePublicVal)"
		}
		if let patternVal = pattern {
			bodyDictionary["pattern"] = patternVal.rawValue
		}

		if let body = try? JSONEncoder().encode(bodyDictionary) {
			urlRequest.httpBody = body
		}
		requestManager.signRequest(&urlRequest)

		do {
			let response: CopyFileToRemoteStorageResponse = try await requestManager.performRequest(urlRequest)
			return response
		} catch let error {
			throw RESTAPIError.fromError(error)
		}
	}

	#if !os(Linux)
	/// Get file's metadata.
	///
	/// Example:
	/// ```swift
	/// uploadcare.fileMetadata(withUUID: "fileUUID") { result in
	///     switch result {
	///     case .failure(let error):
	///         print(error)
	///     case .success(let metadata):
	///         print(metadata)
	///     }
	/// }
	/// ```
	///
	/// - Parameters:
	///   - uuid: File UUID.
	///   - completionHandler: Completion handler.
	public func fileMetadata(
		withUUID uuid: String,
		_ completionHandler: @escaping (Result<[String: String], RESTAPIError>) -> Void
	) {
		let url = urlWithPath("/files/\(uuid)/metadata/")
		var urlRequest = requestManager.makeUrlRequest(fromURL: url, method: .get)
		requestManager.signRequest(&urlRequest)

		requestManager.performRequest(urlRequest) { (result: Result<[String: String], Error>) in
			switch result {
			case .failure(let error):
				if case .emptyResponse = error as? RequestManagerError {
					completionHandler(.success([:]))
					return
				}
				completionHandler(.failure(RESTAPIError.fromError(error)))
			case .success(let data):
				completionHandler(.success(data))
			}
		}
	}
	#endif
	
	/// Get file's metadata.
	///
	/// Example:
	/// ```swift
	/// let metadata = try await uploadcare.fileMetadata(withUUID: "fileUUID")
	/// print(metadata)
	/// ```
	///
	/// - Parameter uuid: File UUID.
	/// - Returns: Metadata dictionary.
	@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
	public func fileMetadata(withUUID uuid: String) async throws -> [String: String] {
		let url = urlWithPath("/files/\(uuid)/metadata/")
		var urlRequest = requestManager.makeUrlRequest(fromURL: url, method: .get)
		requestManager.signRequest(&urlRequest)

		do {
			let data: [String: String] = try await requestManager.performRequest(urlRequest)
			return data
		} catch let error {
			if case .emptyResponse = error as? RequestManagerError {
				return [:]
			}
			throw RESTAPIError.fromError(error)
		}
	}

	#if !os(Linux)
	/// Get metadata key's value.
	///
	/// List of allowed characters for the key:
	/// - Latin letters in lower or upper case (a-z,A-Z)
	/// - digits (0-9)
	/// - underscore `_`
	/// - a hyphen `-`
	/// - dot `.`
	/// - colon `:`
	///
	/// Example:
	/// ```swift
	/// uploadcare.fileMetadataValue(forKey: "myMeta", withUUID: "fileUUID") { result in
	///     switch result {
	///     case .failure(let error):
	///         print(error)
	///     case .success(let value):
	///         print(value)
	///     }
	/// }
	/// ```
	///
	/// - Parameters:
	///   - key: Key of file metadata.
	///   - uuid: File UUID.
	///   - completionHandler: Completion handler.
	public func fileMetadataValue(
		forKey key: String,
		withUUID uuid: String,
		_ completionHandler: @escaping (Result<String, RESTAPIError>) -> Void
	) {
		let url = urlWithPath("/files/\(uuid)/metadata/\(key)/")
		var urlRequest = requestManager.makeUrlRequest(fromURL: url, method: .get)
		requestManager.signRequest(&urlRequest)

		requestManager.performRequest(urlRequest) { (result: Result<String, Error>) in
			switch result {
			case .failure(let error):
				completionHandler(.failure(RESTAPIError.fromError(error)))
			case .success(let val):
				let trimmedVal = val.trimmingCharacters(in: CharacterSet(arrayLiteral: "\""))
				completionHandler(.success(trimmedVal))
			}
		}
	}
	#endif
	
	/// Get metadata key's value.
	///
	/// Example:
	/// ```swift
	/// let value = try await uploadcare.fileMetadataValue(
	///     forKey: "myMeta",
	///     withUUID: "fileUUID"
	/// )
	/// print(value)
	/// ```
	///
	/// List of allowed characters for the key:
	/// - Latin letters in lower or upper case (a-z,A-Z)
	/// - digits (0-9)
	/// - underscore `_`
	/// - a hyphen `-`
	/// - dot `.`
	/// - colon `:`
	///
	/// - Parameters:
	///   - key: Key of file metadata.
	///   - uuid: File UUID.
	/// - Returns: Metadata value.
	@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
	public func fileMetadataValue(forKey key: String, withUUID uuid: String) async throws -> String {
		let url = urlWithPath("/files/\(uuid)/metadata/\(key)/")
		var urlRequest = requestManager.makeUrlRequest(fromURL: url, method: .get)
		requestManager.signRequest(&urlRequest)

		do {
			let val: String = try await requestManager.performRequest(urlRequest)
			let trimmedVal = val.trimmingCharacters(in: CharacterSet(arrayLiteral: "\""))
			return trimmedVal
		} catch let error {
			throw RESTAPIError.fromError(error)
		}
	}

	#if !os(Linux)
	/// Update metadata key's value. If the key does not exist, it will be created.
	///
	/// List of allowed characters for the key:
	/// - Latin letters in lower or upper case (a-z,A-Z)
	/// - digits (0-9)
	/// - underscore `_`
	/// - a hyphen `-`
	/// - dot `.`
	/// - colon `:`
	///
	/// Example:
	/// ```swift
	/// uploadcare.updateFileMetadata(withUUID: "fileUUID", key: "myMeta", value: "someValue") { result in
	///     switch result {
	///     case .failure(let error):
	///         print(error)
	///     case .success(let value):
	///         print(value)
	///     }
	/// }
	/// ```
	///
	/// - Parameters:
	///   - uuid: File UUID.
	///   - key: Key of file metadata.
	///   - value: New value.
	///   - completionHandler: Completion handler.
	public func updateFileMetadata(
		withUUID uuid: String,
		key: String,
		value: String,
		_ completionHandler: @escaping (Result<String, RESTAPIError>) -> Void
	) {
		let url = urlWithPath("/files/\(uuid)/metadata/\(key)/")
		var urlRequest = requestManager.makeUrlRequest(fromURL: url, method: .put)
		urlRequest.httpBody = "\"\(value)\"".data(using: .utf8)!
		urlRequest.allHTTPHeaderFields?.removeValue(forKey: "Content-Type")
		requestManager.signRequest(&urlRequest)

		requestManager.performRequest(urlRequest) { (result: Result<String, Error>) in
			switch result {
			case .failure(let error):
				completionHandler(.failure(RESTAPIError.fromError(error)))
			case .success(let val):
				let trimmedVal = val.trimmingCharacters(in: CharacterSet(arrayLiteral: "\""))
				completionHandler(.success(trimmedVal))
			}
		}
	}
	#endif
	
	/// Update metadata key's value. If the key does not exist, it will be created.
	///
	/// Example:
	/// ```swift
	/// let val = try await uploadcare.updateFileMetadata(
	///     withUUID: "fileUUID",
	///     key: "myMeta",
	///     value: "myValue"
	/// )
	/// print(val)
	/// ```
	///
	/// List of allowed characters for the key:
	/// - Latin letters in lower or upper case (a-z,A-Z)
	/// - digits (0-9)
	/// - underscore `_`
	/// - a hyphen `-`
	/// - dot `.`
	/// - colon `:`
	///
	/// - Parameters:
	///   - uuid: File UUID.
	///   - key: Key of file metadata.
	///   - value: New value.
	/// - Returns: Updated value.
	@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
	public func updateFileMetadata(withUUID uuid: String, key: String, value: String) async throws -> String {
		let url = urlWithPath("/files/\(uuid)/metadata/\(key)/")
		var urlRequest = requestManager.makeUrlRequest(fromURL: url, method: .put)
		urlRequest.httpBody = "\"\(value)\"".data(using: .utf8)!
		requestManager.signRequest(&urlRequest)

		do {
			let val: String = try await requestManager.performRequest(urlRequest)
			let trimmedVal = val.trimmingCharacters(in: CharacterSet(arrayLiteral: "\""))
			return trimmedVal
		} catch let error {
			throw RESTAPIError.fromError(error)
		}
	}

	#if !os(Linux)
	/// Delete metadata key.
	///
	/// List of allowed characters for the key:
	/// - Latin letters in lower or upper case (a-z,A-Z)
	/// - digits (0-9)
	/// - underscore `_`
	/// - a hyphen `-`
	/// - dot `.`
	/// - colon `:`
	///
	/// Example:
	/// ```swift
	/// uploadcare.deleteFileMetadata(forKey: "myMeta", withUUID: "fileUUID") { error in
	///     if let error {
	///         print(error)
	///     }
	/// }
	/// ```
	///
	/// - Parameters:
	///   - key: Key of file metadata.
	///   - uuid: File UUID.
	///   - completionHandler: Completion handler.
	public func deleteFileMetadata(
		forKey key: String,
		withUUID uuid: String,
		_ completionHandler: @escaping (RESTAPIError?) -> Void
	) {
		let url = urlWithPath("/files/\(uuid)/metadata/\(key)/")
		var urlRequest = requestManager.makeUrlRequest(fromURL: url, method: .delete)
		requestManager.signRequest(&urlRequest)

		requestManager.performRequest(urlRequest) { (result: Result<String, Error>) in
			switch result {
			case .failure(let error):
				if case .emptyResponse = error as? RequestManagerError {
					completionHandler(nil)
					return
				}
				completionHandler(RESTAPIError.fromError(error))
			case .success:
				completionHandler(nil)
			}
		}
	}
	#endif
	
	/// Delete metadata key.
	///
	/// Example:
	/// ```swift
	/// try await uploadcare.deleteFileMetadata(
	///     forKey: "myMeta",
	///     withUUID: "fileUUID"
	/// )
	/// ```
	///
	/// List of allowed characters for the key:
	/// - Latin letters in lower or upper case (a-z,A-Z)
	/// - digits (0-9)
	/// - underscore `_`
	/// - a hyphen `-`
	/// - dot `.`
	/// - colon `:`
	///
	/// - Parameters:
	///   - key: Key of file metadata.
	///   - uuid: File UUID.
	@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
	public func deleteFileMetadata(forKey key: String, withUUID uuid: String) async throws {
		let url = urlWithPath("/files/\(uuid)/metadata/\(key)/")
		var urlRequest = requestManager.makeUrlRequest(fromURL: url, method: .delete)
		requestManager.signRequest(&urlRequest)

		do {
			let _: String = try await requestManager.performRequest(urlRequest)
		} catch let error {
			if case .emptyResponse = error as? RequestManagerError {
				return
			}

			throw RESTAPIError.fromError(error)
		}
	}

	#if !os(Linux)
	/// Get list of groups
	///
	/// Example:
	/// ```swift
	/// let query = GroupsListQuery()
	///     .limit(100)
	///     .ordering(.datetimeCreatedDESC)
	///
	/// uploadcare.listOfGroups(withQuery: query) { result in
	///     switch result {
	///     case .failure(let error):
	///         print(error)
	///     case .success(let list):
	///         print(list)
	///     }
	/// }
	/// ```
	///
	/// - Parameters:
	///   - query: Request query object.
	///   - completionHandler: Completion handler.
	public func listOfGroups(
		withQuery query: GroupsListQuery?,
		_ completionHandler: @escaping (Result<GroupsList, RESTAPIError>) -> Void
	) {
		var queryString: String?
		if let queryValue = query {
			queryString = "\(queryValue.stringValue)"
		}
		listOfGroups(withQueryString: queryString, completionHandler)
	}
	#endif

	/// Get list of groups.
	///
	/// Example:
	/// ```swift
	/// let query = GroupsListQuery()
	///     .limit(100)
	///     .ordering(.datetimeCreatedDESC)
	///
	/// let list = try await uploadcare.listOfGroups(withQuery: query)
	/// print(list)
	/// ```
	///
	/// - Parameter query: Request query object.
	/// - Returns: List of groups.
	@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
	public func listOfGroups(withQuery query: GroupsListQuery?) async throws -> GroupsList {
		var queryString: String?
		if let queryValue = query {
			queryString = "\(queryValue.stringValue)"
		}
		return try await listOfGroups(withQueryString: queryString)
	}
	
	#if !os(Linux)
	/// Get list of groups
	/// - Parameters:
	///   - query: Query string.
	///   - completionHandler: Completion handler.
	internal func listOfGroups(
		withQueryString query: String?,
		_ completionHandler: @escaping (Result<GroupsList, RESTAPIError>) -> Void
	) {
		var urlString = RESTAPIBaseUrl + "/groups/"
		if let queryValue = query {
			urlString += "?\(queryValue)"
		}
		
		guard let url = URL(string: urlString) else {
			assertionFailure("Incorrect url")
			return
		}
		var urlRequest = requestManager.makeUrlRequest(fromURL: url, method: .get)
		requestManager.signRequest(&urlRequest)

		requestManager.performRequest(urlRequest) { (result: Result<GroupsList, Error>) in
			switch result {
			case .failure(let error): completionHandler(.failure(RESTAPIError.fromError(error)))
			case .success(let groupsList): completionHandler(.success(groupsList))
			}
		}
	}
	#endif

	/// Get list of groups.
	/// - Parameter query: Query string.
	/// - Returns: List of groups.
	@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
	internal func listOfGroups(withQueryString query: String?) async throws -> GroupsList {
		var urlString = RESTAPIBaseUrl + "/groups/"
		if let queryValue = query {
			urlString += "?\(queryValue)"
		}

		guard let url = URL(string: urlString) else {
			assertionFailure("Incorrect url")
			throw RESTAPIError.defaultError()
		}
		var urlRequest = requestManager.makeUrlRequest(fromURL: url, method: .get)
		requestManager.signRequest(&urlRequest)

		do {
			let groupsList: GroupsList = try await requestManager.performRequest(urlRequest)
			return groupsList
		} catch  {
			throw RESTAPIError.fromError(error)
		}
	}

	#if !os(Linux)
	/// Get a file group by UUID.
	///
	/// Example:
	/// ```swift
	/// let uuid = "c5bec8c7-d4b6-4921-9e55-6edb027546bc~1"
	/// uploadcare.groupInfo(withUUID: uuid) { result in
	///     switch result {
	///     case .failure(let error):
	///         print(error)
	///     case .success(let group):
	///         print(group)
	///     }
	/// }
	/// ```
	///
	/// - Parameters:
	///   - uuid: Group UUID.
	///   - completionHandler: Completion handler.
	public func groupInfo(
		withUUID uuid: String,
		_ completionHandler: @escaping (Result<Group, RESTAPIError>) -> Void
	) {
		let url = urlWithPath("/groups/\(uuid)/")
		var urlRequest = requestManager.makeUrlRequest(fromURL: url, method: .get)
		requestManager.signRequest(&urlRequest)

		requestManager.performRequest(urlRequest) { (result: Result<Group, Error>) in
			switch result {
			case .failure(let error): completionHandler(.failure(RESTAPIError.fromError(error)))
			case .success(let group): completionHandler(.success(group))
			}
		}
	}
	#endif

	/// Get a file group by UUID.
	///
	/// Example:
	/// ```swift
	/// let uuid = "c5bec8c7-d4b6-4921-9e55-6edb027546bc~1"
	/// let group = try await uploadcare.groupInfo(withUUID: uuid)
	/// print(group)
	/// ```
	///
	/// - Parameter uuid: Group UUID.
	/// - Returns: File group.
	@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
	public func groupInfo(withUUID uuid: String) async throws -> Group {
		let url = urlWithPath("/groups/\(uuid)/")
		var urlRequest = requestManager.makeUrlRequest(fromURL: url, method: .get)
		requestManager.signRequest(&urlRequest)

		do {
			let group: Group = try await requestManager.performRequest(urlRequest)
			return group
		} catch {
			throw RESTAPIError.fromError(error)
		}
	}

	#if !os(Linux)
	/// Delete a file group by its ID.
	///
	/// **Note**: The operation only removes the group object itself. **All the files that were part of the group are left as is.**
	///
	/// Example:
	/// ```swift
	/// uploadcare.deleteGroup(withUUID: "groupUUID") { error in
	///     if let error {
	///         print(error)
	///     }
	/// }
	/// ```
	///
	/// - Parameters:
	///   - uuid: Group UUID.
	///   - completionHandler: Completion handler.
	public func deleteGroup(
		withUUID uuid: String,
		_ completionHandler: @escaping (RESTAPIError?) -> Void
	) {
		let url = urlWithPath("/groups/\(uuid)/")
		var urlRequest = requestManager.makeUrlRequest(fromURL: url, method: .delete)
		requestManager.signRequest(&urlRequest)

		requestManager.performRequest(urlRequest) { (result: Result<Group, Error>) in
			switch result {
			case .failure(let error):
				if case .emptyResponse = error as? RequestManagerError {
					completionHandler(nil)
					return
				}
				completionHandler(RESTAPIError.fromError(error))
			case .success(_): completionHandler(nil)
			}
		}
	}
	#endif
	
	/// Delete a file group by its ID.
	///
	/// **Note**: The operation only removes the group object itself. **All the files that were part of the group are left as is.**
	///
	/// Example:
	/// ```swift
	/// try await uploadcare.deleteGroup(withUUID: "groupId")
	/// ```
	///
	/// - Parameter uuid: Group UUID.
	@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
	public func deleteGroup(withUUID uuid: String) async throws {
		let url = urlWithPath("/groups/\(uuid)/")
		var urlRequest = requestManager.makeUrlRequest(fromURL: url, method: .delete)
		requestManager.signRequest(&urlRequest)

		do {
			let _: Group = try await requestManager.performRequest(urlRequest)
		} catch {
			if case .emptyResponse = error as? RequestManagerError {
				return
			}
			throw RESTAPIError.fromError(error)
		}
	}


	#if !os(Linux)
	/// Getting info about account project.
	///
	/// Example:
	/// ```swift
	/// uploadcare.getProjectInfo { result in
	///     switch result {
	///     case .failure(let error):
	///         print(error)
	///     case .success(let project):
	///         print(project)
	///     }
	/// }
	/// ```
	///
	/// - Parameter completionHandler: Completion handler.
	public func getProjectInfo(_ completionHandler: @escaping (Result<Project, RESTAPIError>) -> Void) {
		let url = urlWithPath("/project/")
		var urlRequest = requestManager.makeUrlRequest(fromURL: url, method: .get)
		requestManager.signRequest(&urlRequest)

		requestManager.performRequest(urlRequest) { (result: Result<Project, Error>) in
			switch result {
			case .failure(let error): completionHandler(.failure(RESTAPIError.fromError(error)))
			case .success(let project): completionHandler(.success(project))
			}
		}
	}
	#endif

	/// Getting info about account project.
	///
	/// Example:
	/// ```swift
	/// let project = try await uploadcare.getProjectInfo()
	/// print(project)
	/// ```
	///
	/// - Returns: Project info.
	@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
	public func getProjectInfo() async throws -> Project {
		let url = urlWithPath("/project/")
		var urlRequest = requestManager.makeUrlRequest(fromURL: url, method: .get)
		requestManager.signRequest(&urlRequest)

		do {
			let project: Project = try await requestManager.performRequest(urlRequest)
			return project
		} catch {
			throw RESTAPIError.fromError(error)
		}
	}

	#if !os(Linux)
	/// This method allows you to get authonticated url from your backend using redirect.
	/// By request to that url your backend should generate authenticated url to your file and perform REDIRECT to generated url.
	/// Redirect url will be caught and returned in completion handler of that method
	///
	/// Example of URL: https://yourdomain.com/{UUID}/
	/// Redirect to: https://cdn.yourdomain.com/{uuid}/?token={token}&expire={timestamp}
	///
	/// URL for redirect will be returned in completion handler
	///
	/// For more details [check the documentation.](https://uploadcare.com/docs/delivery/file_api/#authenticated-urls).
	///
	/// Example:
	/// ```swift
	/// let url = URL(string: "https://yourdomain.com")!
	/// uploadcare.getAuthenticatedUrlFromUrl(url) { result in
	///     switch result {
	///     case .failure(let error):
	///         print(error)
	///     case .success(let value):
	///         print(value)
	///     }
	/// }
	/// ```
	///
	/// - Parameters:
	///   - url: URL for request to your backend.
	///   - completionHandler: Completion handler.
	public func getAuthenticatedUrlFromUrl(_ url: URL, _ completionHandler: @escaping (Result<String, RESTAPIError>) -> Void) {
		let urlString = url.absoluteString

		redirectValues[urlString] = ""

		let config = URLSessionConfiguration.default
		let urlSession = URLSession(configuration: config, delegate: self, delegateQueue: nil)

		let task = urlSession.dataTask(with: url) { [weak self] (data, response, error) in
			guard let self = self else { return }

			defer { self.redirectValues.removeValue(forKey: urlString) }

			if let error = error {
				completionHandler(.failure(RESTAPIError(detail: error.localizedDescription)))
				return
			}

			guard let redirectUrl = self.redirectValues[urlString], redirectUrl.isEmpty == false else {
				completionHandler(.failure(RESTAPIError(detail: "No redirect happened")))
				return
			}

			completionHandler(.success(redirectUrl))
		}
		task.resume()
	}
	#endif

	/// This method allows you to get authonticated url from your backend using redirect.
	/// By request to that url your backend should generate authenticated url to your file and perform REDIRECT to generated url.
	/// Redirect url will be caught and returned in completion handler of that method
	///
	/// Example of URL: https://yourdomain.com/{UUID}/
	///
	/// Redirect to: https://cdn.yourdomain.com/{uuid}/?token={token}&expire={timestamp}
	///
	/// URL for redirect will be returned from the function.
	///
	/// More details in documentation: https://uploadcare.com/docs/delivery/file_api/#authenticated-urls
	///
	/// Example:
	/// ```swift
	/// let url = URL(string: "https://yourdomain.com/FILE_UUID/")!
	/// let value = try await uploadcare.getAuthenticatedUrlFromUrl(url)
	/// print(value)
	/// ```
	///
	/// - Parameter url: URL for request to your backend.
	/// - Returns: URL to your backend.
	@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
	public func getAuthenticatedUrlFromUrl(_ url: URL) async throws -> String {
		let urlRequest = URLRequest(url: url)
		#if os(Linux)
		let redirect = try await requestManager.catchRedirect(urlRequest)
		guard redirect.isEmpty == false else {
			throw RESTAPIError(detail: "No redirect happened")
		}
		return redirect
		#else
		let urlString = url.absoluteString
		redirectValues[urlString] = ""
		defer { redirectValues.removeValue(forKey: urlString) }

		let config = URLSessionConfiguration.default
		let urlSession = URLSession(configuration: config, delegate: self, delegateQueue: nil)

		do {
			_ = try await urlSession.data(for: urlRequest)
		} catch {
			throw RESTAPIError(detail: error.localizedDescription)
		}

		guard let redirectUrl = self.redirectValues[urlString], redirectUrl.isEmpty == false else {
			throw RESTAPIError(detail: "No redirect happened")
		}
		return redirectUrl
		#endif
	}

	#if !os(Linux)
	/// List of project webhooks.
	///
	/// Example:
	/// ```swift
	/// uploadcare.getListOfWebhooks { result in
	///     switch result {
	///     case .failure(let error):
	///         print(error)
	///     case .success(let webhooks):
	///         print(webhooks)
	///     }
	/// }
	/// ```
	///
	/// - Parameter completionHandler: Completion handler.
	public func getListOfWebhooks(_ completionHandler: @escaping (Result<[Webhook], RESTAPIError>) -> Void) {
		let url = urlWithPath("/webhooks/")
		var urlRequest = requestManager.makeUrlRequest(fromURL: url, method: .get)
		requestManager.signRequest(&urlRequest)

		requestManager.performRequest(urlRequest) { (result: Result<[Webhook], Error>) in
			switch result {
			case .failure(let error): completionHandler(.failure(RESTAPIError.fromError(error)))
			case .success(let webhooks): completionHandler(.success(webhooks))
			}
		}
	}
	#endif

	/// Get list of project webhooks.
	///
	/// Example:
	/// ```swift
	/// let webhooks = try await uploadcare.getListOfWebhooks()
	/// print(webhooks)
	/// ```
	///
	/// - Returns: Array of webhooks.
	@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
	public func getListOfWebhooks() async throws -> [Webhook] {
		let url = urlWithPath("/webhooks/")
		var urlRequest = requestManager.makeUrlRequest(fromURL: url, method: .get)
		requestManager.signRequest(&urlRequest)

		do {
			let webhooks: [Webhook] = try await requestManager.performRequest(urlRequest)
			return webhooks
		} catch {
			throw RESTAPIError.fromError(error)
		}
	}

	private func createWebhookRequestBody(targetUrl: URL, event: Webhook.Event, isActive: Bool, signingSecret: String? = nil) throws -> Data {
		var bodyDictionary = [
			"target_url": targetUrl.absoluteString,
			"event": event.rawValue,
			"is_active": "\(isActive)"
		]

		if let signingSecret = signingSecret {
			bodyDictionary["signing_secret"] = signingSecret
		}

		return try JSONEncoder().encode(bodyDictionary)
	}

	#if !os(Linux)
	/// Create webhook.
	///
	/// Example:
	/// ```swift
	/// let url = URL(string: "https://yourwebhook.com")!
	/// uploadcare.createWebhook(targetUrl: url, event: .fileUploaded, isActive: true, signingSecret: "someSigningSecret") { result in
	///     switch result {
	///     case .failure(let error):
	///         print(error)
	///     case .success(let webhook):
	///         print(webhook)
	///     }
	/// }
	/// ```
	///
	/// - Parameters:
	///   - targetUrl: An URL that is triggered by an event, for example, a file upload. A target URL MUST be unique for each project — event type combination.
	///   - event: An event you subscribe to.
	///   - isActive: Marks a subscription as either active or not, defaults to true, otherwise false.
	///   - signingSecret: Optional secret that, if set, will be used to calculate signatures for the webhook payloads.
	///   - completionHandler: Completion handler.
	public func createWebhook(targetUrl: URL, event: Webhook.Event = .fileUploaded, isActive: Bool, signingSecret: String? = nil, _ completionHandler: @escaping (Result<Webhook, RESTAPIError>) -> Void) {
		let url = urlWithPath("/webhooks/")
		var urlRequest = requestManager.makeUrlRequest(fromURL: url, method: .post)
		do {
			urlRequest.httpBody = try createWebhookRequestBody(targetUrl: targetUrl, event: event, isActive: isActive, signingSecret: signingSecret)
		} catch let error {
			DLog(error.localizedDescription)
		}
		requestManager.signRequest(&urlRequest)

		requestManager.performRequest(urlRequest) { (result: Result<Webhook, Error>) in
			switch result {
			case .failure(let error): completionHandler(.failure(RESTAPIError.fromError(error)))
			case .success(let webhook): completionHandler(.success(webhook))
			}
		}
	}
	#endif

	/// Create a webhook.
	///
	/// Example:
	/// ```swift
	/// let url = URL(string: "https://yourwebhook.com")!
	/// let webhook = try await uploadcare.createWebhook(
	///     targetUrl: url,
	///     isActive: true,
	///     signingSecret: "someSigningSecret"
	/// )
	/// print(webhook)
	/// ```
	///
	/// - Parameters:
	///   - targetUrl: An URL that is triggered by an event, for example, a file upload. A target URL MUST be unique for each project — event type combination.
	///   - event: An event you subscribe to.
	///   - isActive: Marks a subscription as either active or not, defaults to true, otherwise false.
	///   - signingSecret: Optional secret that, if set, will be used to calculate signatures for the webhook payloads
	/// - Returns: Created webhook.
	@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
	public func createWebhook(targetUrl: URL, event: Webhook.Event = .fileUploaded, isActive: Bool, signingSecret: String? = nil) async throws -> Webhook {
		let url = urlWithPath("/webhooks/")
		var urlRequest = requestManager.makeUrlRequest(fromURL: url, method: .post)
		urlRequest.httpBody = try createWebhookRequestBody(targetUrl: targetUrl, event: event, isActive: isActive, signingSecret: signingSecret)
		requestManager.signRequest(&urlRequest)

		do {
			let webhook: Webhook = try await requestManager.performRequest(urlRequest)
			return webhook
		} catch {
			throw RESTAPIError.fromError(error)
		}
	}

	#if !os(Linux)
	/// Update webhook attributes.
	///
	/// Example:
	/// ```swift
	/// let url = URL(string: "https://yourwebhook.com")!
	/// let webhookId = 100
	/// uploadcare.updateWebhook(id: webhookId, targetUrl: url, event: .fileInfoUpdated, isActive: true, signingSecret: "someNewSigningSecret") { result in
	///     switch result {
	///     case .failure(let error):
	///         print(error)
	///     case .success(let webhook):
	///         print(webhook)
	///     }
	/// }
	/// ```
	///
	/// - Parameters:
	///   - id: Webhook ID.
	///   - targetUrl: Where webhook data will be posted.
	///   - event: An event you subscribe to.
	///   - isActive: Marks a subscription as either active or not.
	///   - signingSecret: Optional secret that, if set, will be used to calculate signatures for the webhook payloads.
	///   - completionHandler: Completion handler.
	public func updateWebhook(id: Int, targetUrl: URL, event: Webhook.Event = .fileUploaded, isActive: Bool, signingSecret: String? = nil, _ completionHandler: @escaping (Result<Webhook, RESTAPIError>) -> Void) {
		let url = urlWithPath("/webhooks/\(id)/")
		var urlRequest = requestManager.makeUrlRequest(fromURL: url, method: .put)
		do {
			urlRequest.httpBody = try createWebhookRequestBody(targetUrl: targetUrl, event: event, isActive: isActive, signingSecret: signingSecret)
		} catch let error {
			DLog(error.localizedDescription)
		}
		requestManager.signRequest(&urlRequest)

		requestManager.performRequest(urlRequest) { (result: Result<Webhook, Error>) in
			switch result {
			case .failure(let error): completionHandler(.failure(RESTAPIError.fromError(error)))
			case .success(let webhook): completionHandler(.success(webhook))
			}
		}
	}
	#endif

	/// Update webhook attributes.
	///
	/// Example:
	/// ```swift
	/// let url = URL(string: "https://yourwebhook.com")!
	/// let webhookId = 100
	/// let webhook = try await uploadcare.updateWebhook(
	///     id: webhookId,
	///     targetUrl: url,
	///     event: .fileInfoUpdated, 
	///     isActive: false,
	///     signingSecret: "someNewSigningSecret"
	/// )
	/// print(webhook)
	/// ```
	/// - Parameters:
	///   - id: Webhook ID
	///   - targetUrl: Where webhook data will be posted.
	///   - event: An event you subscribe to.
	///   - isActive: Marks a subscription as either active or not.
	///   - signingSecret: Optional secret that, if set, will be used to calculate signatures for the webhook payloads.
	/// - Returns: Updated webhook.
	@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
	public func updateWebhook(id: Int, targetUrl: URL, event: Webhook.Event = .fileUploaded, isActive: Bool, signingSecret: String? = nil) async throws -> Webhook {
		let url = urlWithPath("/webhooks/\(id)/")
		var urlRequest = requestManager.makeUrlRequest(fromURL: url, method: .put)
		urlRequest.httpBody = try createWebhookRequestBody(targetUrl: targetUrl, event: event, isActive: isActive, signingSecret: signingSecret)
		requestManager.signRequest(&urlRequest)

		do {
			let webhook: Webhook = try await requestManager.performRequest(urlRequest)
			return webhook
		} catch {
			throw RESTAPIError.fromError(error)
		}
	}

	#if !os(Linux)
	/// Delete a webhook.
	///
	/// Example:
	/// ```swift
	/// let url = URL(string: "https://yourwebhook.com")!
	/// let webhookId = 100
	/// uploadcare.deleteWebhook(forTargetUrl: url) { error in
	///     if let error = error {
	///         print(error)
	///     }
	/// }
	/// ```
	///
	/// - Parameters:
	///   - targetUrl: URL of the webhook target.
	///   - completionHandler: Completion handler.
	public func deleteWebhook(forTargetUrl targetUrl: URL, _ completionHandler: @escaping (RESTAPIError?) -> Void) {
		let url = urlWithPath("/webhooks/unsubscribe/")
		var urlRequest = requestManager.makeUrlRequest(fromURL: url, method: .delete)
		let bodyDictionary = [
			"target_url": targetUrl.absoluteString
		]
		do {
			urlRequest.httpBody = try JSONEncoder().encode(bodyDictionary)
		} catch let error {
			DLog(error.localizedDescription)
		}
		requestManager.signRequest(&urlRequest)

		requestManager.performRequest(urlRequest) { (result: Result<Bool, Error>) in
			switch result {
			case .failure(let error): completionHandler(RESTAPIError.fromError(error))
			case .success(_): completionHandler(nil)
			}
		}
	}
	#endif

	/// Delete a webhook.
	///
	/// Example:
	/// ```swift
	/// let url = URL(string: "https://yourwebhook.com")!
	/// try await uploadcare.deleteWebhook(forTargetUrl: targetUrl)
	/// ```
	/// - Parameter targetUrl: URL of the webhook target.
	@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
	public func deleteWebhook(forTargetUrl targetUrl: URL) async throws {
		let url = urlWithPath("/webhooks/unsubscribe/")
		var urlRequest = requestManager.makeUrlRequest(fromURL: url, method: .delete)
		urlRequest.httpBody = try JSONEncoder().encode(["target_url": targetUrl.absoluteString])
		requestManager.signRequest(&urlRequest)

		do {
			let _: Bool = try await requestManager.performRequest(urlRequest)
		} catch {
			throw RESTAPIError.fromError(error)
		}
	}

	#if !os(Linux)
	/// Uploadcare allows converting documents to the following target formats: DOC, DOCX, XLS, XLSX, ODT, ODS, RTF, TXT, PDF, JPG, PNG.
	///
	/// Example:
	/// ```swift
	/// let path = ":uuid/document/-/format/:target-format/"
	/// uploadcare.convertDocuments([path]) { result in
	///     switch result {
	///     case .failure(let error):
	///         print(error)
	///     case .success(let response):
	///         print(response)
	///     }
	/// }
	/// ```
	///
	/// - Parameters:
	///   - paths: An array of UUIDs of your source documents to convert together with the specified target format.
	///   See [documentation](https://uploadcare.com/docs/transformations/document_conversion/#convert-url-formatting).
	///   - store: A flag indicating if we should store your outputs.
	///   - completionHandler: Completion handler.
	public func convertDocuments(
		_ paths: [String],
		store: StoringBehavior? = nil,
		saveInGroup: Bool? = nil,
		_ completionHandler: @escaping (Result<ConvertDocumentsResponse, RESTAPIError>) -> Void
	) {
		let url = urlWithPath("/convert/document/")
		var urlRequest = requestManager.makeUrlRequest(fromURL: url, method: .post)

		let storeValue = store == StoringBehavior.auto ? .store : store
		var saveInGroupValue: String? = nil
		if let saveInGroup {
			saveInGroupValue = saveInGroup ? "true" : "false"
		}
		let requestData = ConvertRequestData(
			paths: paths,
			store: storeValue?.rawValue ?? StoringBehavior.store.rawValue, 
			saveInGroup: saveInGroupValue
		)

		urlRequest.httpBody = try? JSONEncoder().encode(requestData)
		requestManager.signRequest(&urlRequest)

		requestManager.performRequest(urlRequest) { (result: Result<ConvertDocumentsResponse, Error>) in
			switch result {
			case .failure(let error): completionHandler(.failure(RESTAPIError.fromError(error)))
			case .success(let response): completionHandler(.success(response))
			}
		}
	}
	#endif
	
	/// Uploadcare allows converting documents to the following target formats: DOC, DOCX, XLS, XLSX, ODT, ODS, RTF, TXT, PDF, JPG, PNG.
	///
	/// Example:
	/// ```swift
	/// let paths = ["filePath1", "filePath2"]
	///
	/// let response = try await uploadcare.convertDocumentsWithSettings(paths)
	/// print(response)
	/// ```
	///
	/// - Parameters:
	///   - paths: An array of UUIDs of your source documents to convert together with the specified target format. [See documentation.](https://uploadcare.com/docs/transformations/document_conversion/#convert-url-formatting)
	///   - store: A flag indicating if we should store your outputs.
	/// - Returns: Operation response.
	@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
	public func convertDocuments(_ paths: [String], store: StoringBehavior? = nil, saveInGroup: Bool? = nil) async throws -> ConvertDocumentsResponse {
		let url = urlWithPath("/convert/document/")
		var urlRequest = requestManager.makeUrlRequest(fromURL: url, method: .post)

		let storeValue = store == StoringBehavior.auto ? .store : store
		var saveInGroupValue: String? = nil
		if let saveInGroup {
			saveInGroupValue = saveInGroup ? "true" : "false"
		}
		let requestData = ConvertRequestData(
			paths: paths,
			store: storeValue?.rawValue ?? StoringBehavior.store.rawValue,
			saveInGroup: saveInGroupValue
		)

		urlRequest.httpBody = try? JSONEncoder().encode(requestData)
		requestManager.signRequest(&urlRequest)

		do {
			let response: ConvertDocumentsResponse = try await requestManager.performRequest(urlRequest)
			return response
		} catch {
			throw RESTAPIError.fromError(error)
		}
	}

	#if !os(Linux)
	/// Convert documents.
	///
	/// Example:
	/// ```swift
	/// let task1 = DocumentConversionJobSettings(forFile: file1)
	///     .format(.odt)
	/// let task2 = DocumentConversionJobSettings(forFile: file2)
	///     .format(.pdf)
	///
	/// uploadcare.convertDocumentsWithSettings([task1, task2]) { result in
	///     switch result {
	///     case .failure(let error):
	///         print(error)
	///     case .success(let response):
	///         print(response)
	///     }
	/// }
	/// ```
	///
	/// - Parameters:
	///   - files: Files array.
	///   - format: Target format (DOC, DOCX, XLS, XLSX, ODT, ODS, RTF, TXT, PDF, JPG, PNG).
	///   - store: A flag indicating if we should store your outputs.
	///   - completionHandler: Completion handler.
	public func convertDocumentsWithSettings(
		_ tasks: [DocumentConversionJobSettings],
		store: StoringBehavior? = nil,
		saveInGroup: Bool? = nil,
		_ completionHandler: @escaping (Result<ConvertDocumentsResponse, RESTAPIError>) -> Void
	) {
		var paths = [String]()
		tasks.forEach({ paths.append($0.stringValue) })
		convertDocuments(paths, store: store, saveInGroup: saveInGroup, completionHandler)
	}
	#endif
	
	/// Convert documents.
	///
	/// Example:
	/// ```swift
	/// let task1 = DocumentConversionJobSettings(forFile: file1)
	///     .format(.odt)
	/// let task2 = DocumentConversionJobSettings(forFile: file2)
	///     .format(.pdf)
	///
	/// let response = try await uploadcare.convertDocumentsWithSettings([task1, task2])
	/// print(response)
	///
	/// // possible problems:
	/// print(response.problems)
	///
	/// // a token that can be used to check a job status:
	/// let job = response.result.first
	/// let token = job?.token
	/// ```
	///
	/// - Parameters:
	///   - tasks: Files array.
	///   - store: A flag indicating if we should store your outputs.
	/// - Returns: Operation response.
	@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
	public func convertDocumentsWithSettings(_ tasks: [DocumentConversionJobSettings], store: StoringBehavior? = nil, saveInGroup: Bool? = nil) async throws -> ConvertDocumentsResponse {
		var paths = [String]()
		tasks.forEach({ paths.append($0.stringValue) })
		return try await convertDocuments(paths, store: store, saveInGroup: saveInGroup)
	}

	#if !os(Linux)
	/// Document conversion job status.
	///
	/// Example:
	/// ```swift
	/// uploadcare.documentConversionJobStatus(token: 123456) { result in
	///     switch result {
	///     case .failure(let error):
	///         print(error)
	///     case .success(let job):
	///         switch job.status {
	///         case .failed(let conversionError):
	///             print(conversionError)
	///         default:
	///             break
	///         }
	///     }
	/// }
	/// ```
	///
	/// - Parameters:
	///   - token: Job token.
	///   - completionHandler: Completion handler.
	public func documentConversionJobStatus(token: Int, _ completionHandler: @escaping (Result<ConvertDocumentJobStatus, RESTAPIError>) -> Void) {
		let url = urlWithPath("/convert/document/status/\(token)/")
		var urlRequest = requestManager.makeUrlRequest(fromURL: url, method: .get)
		requestManager.signRequest(&urlRequest)

		requestManager.performRequest(urlRequest) { (result: Result<ConvertDocumentJobStatus, Error>) in
			switch result {
			case .failure(let error): completionHandler(.failure(RESTAPIError.fromError(error)))
			case .success(let status): completionHandler(.success(status))
			}
		}
	}
	#endif
	
	/// Document conversion job status.
	///
	/// Example:
	/// ```swift
	/// let job = try await uploadcare.documentConversionJobStatus(token: 123456)
	///
	/// switch job.status {
	/// case .failed(let conversionError):
	///     print(conversionError)
	/// default:
	///     break
	/// }
	/// ```
	///
	/// - Parameter token: A job token from the ``convertDocuments(_:store:)`` result.
	/// - Returns: Job status.
	@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
	public func documentConversionJobStatus(token: Int) async throws -> ConvertDocumentJobStatus {
		let url = urlWithPath("/convert/document/status/\(token)/")
		var urlRequest = requestManager.makeUrlRequest(fromURL: url, method: .get)
		requestManager.signRequest(&urlRequest)

		do {
			let status: ConvertDocumentJobStatus = try await requestManager.performRequest(urlRequest)
			return status
		} catch {
			throw RESTAPIError.fromError(error)
		}
	}

	#if !os(Linux)
	/// Convert videos with settings.
	///
	/// ```swift
	/// let task1 = VideoConversionJobSettings(forFile: file1)
	///     .format(.webm)
	///     .size(VideoSize(width: 640, height: 480))
	///     .resizeMode(.addPadding)
	///     .quality(.lightest)
	///     .cut( VideoCut(startTime: "0:0:5.000", length: "15") )
	///     .thumbs(15)
	///
	/// let task2 = VideoConversionJobSettings(forFile: file2)
	///     .format(.mp4)
	///     .quality(.lightest)
	///
	/// uploadcare.convertVideosWithSettings([task1, task2]) { result in
	///     switch result {
	///     case .failure(let error):
	///         print(error)
	///     case .success(let response):
	///         print(response)
	///
	///         // a token for checking a job status:
	///         let job = response.result.first
	///         let token = job?.token
	/// }
	/// ```
	///
	/// - Parameters:
	///   - tasks: Array of ``VideoConversionJobSettings`` objects which settings for conversion for every file.
	///   - store: A flag indicating if we should store your outputs.
	///   - completionHandler: Completion handler.
	public func convertVideosWithSettings(
		_ tasks: [VideoConversionJobSettings],
		store: StoringBehavior? = nil,
		_ completionHandler: @escaping (Result<ConvertDocumentsResponse, RESTAPIError>) -> Void
	) {
		var paths = [String]()
		tasks.forEach({ paths.append($0.stringValue) })
		convertVideos(paths, completionHandler)
	}
	#endif
	
	/// Convert videos with settings.
	///
	/// Example:
	/// ```swift
	/// let task1 = VideoConversionJobSettings(forFile: file1)
	///     .format(.webm)
	///     .size(VideoSize(width: 640, height: 480))
	///     .resizeMode(.addPadding)
	///     .quality(.lightest)
	///     .cut( VideoCut(startTime: "0:0:5.000", length: "15") )
	///     .thumbs(15)
	///
	/// let task2 = VideoConversionJobSettings(forFile: file2)
	///     .format(.mp4)
	///     .quality(.lightest)
	///
	/// let response = try await uploadcare.convertVideosWithSettings([task1, task2])
	/// print(response)
	///
	/// // a token for checking a job status:
	/// let job = response.result.first
	/// let token = job?.token
	/// ```
	///
	/// - Parameters:
	///   - tasks: Array of ``VideoConversionJobSettings`` objects which settings for conversion for every file.
	///   - store: A flag indicating if we should store your outputs.
	/// - Returns: Operation response.
	@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
	public func convertVideosWithSettings(_ tasks: [VideoConversionJobSettings], store: StoringBehavior? = nil) async throws -> ConvertDocumentsResponse {
		var paths = [String]()
		tasks.forEach({ paths.append($0.stringValue) })
		return try await convertVideos(paths)
	}

	#if !os(Linux)
	/// Convert videos.
	///
	/// ```swift
	/// let path = ":uuid/video/-/format/ogg/"
	/// uploadcare.convertVideos([path]) { result in
	///     switch result {
	///     case .failure(let error):
	///         print(error)
	///     case .success(let response):
	///         print(response)
	/// }
	/// ```
	///
	/// - Parameters:
	///   - paths: An array of UUIDs of your video files to process together with a set of needed operations.
	///   [See documentation](https://uploadcare.com/docs/transformations/video_encoding/#process-operations).
	///   - store: A flag indicating if we should store your outputs.
	///   - completionHandler: Completion handler.
	public func convertVideos(
		_ paths: [String],
		store: StoringBehavior? = nil,
		_ completionHandler: @escaping (Result<ConvertDocumentsResponse, RESTAPIError>) -> Void
	) {
		let url = urlWithPath("/convert/video/")
		var urlRequest = requestManager.makeUrlRequest(fromURL: url, method: .post)

		let storeValue = store == StoringBehavior.auto ? .store : store
		let requestData = ConvertRequestData(
			paths: paths,
			store: storeValue?.rawValue ?? StoringBehavior.store.rawValue,
			saveInGroup: nil
		)

		urlRequest.httpBody = try? JSONEncoder().encode(requestData)
		requestManager.signRequest(&urlRequest)

		requestManager.performRequest(urlRequest) { (result: Result<ConvertDocumentsResponse, Error>) in
			switch result {
			case .failure(let error): completionHandler(.failure(RESTAPIError.fromError(error)))
			case .success(let response): completionHandler(.success(response))
			}
		}
	}
	#endif
	
	/// Convert videos.
	///
	/// Example:
	/// ```swift
	/// let paths = [":uuid/video/-/format/ogg/"]
	/// let response = try await uploadcare.convertVideos(paths)
	/// print(response)
	///
	/// // a token for checking a job status:
	/// let job = response.result.first
	/// let token = job?.token
	/// ```
	///
	/// - Parameters:
	///   - paths: An array of UUIDs of your video files to process together with a set of needed operations. [See documentation](https://uploadcare.com/docs/transformations/video_encoding/#process-operations).
	///   - store: A flag indicating if we should store your outputs.
	/// - Returns: Operation response.
	@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
	public func convertVideos(_ paths: [String], store: StoringBehavior? = nil) async throws -> ConvertDocumentsResponse {
		let url = urlWithPath("/convert/video/")
		var urlRequest = requestManager.makeUrlRequest(fromURL: url, method: .post)

		let storeValue = store == StoringBehavior.auto ? .store : store
		let requestData = ConvertRequestData(
			paths: paths,
			store: storeValue?.rawValue ?? StoringBehavior.store.rawValue,
			saveInGroup: nil
		)

		urlRequest.httpBody = try? JSONEncoder().encode(requestData)
		requestManager.signRequest(&urlRequest)

		do {
			let response: ConvertDocumentsResponse = try await requestManager.performRequest(urlRequest)
			return response
		} catch {
			throw RESTAPIError.fromError(error)
		}
	}

	#if !os(Linux)
	/// Video conversion job status.
	///
	/// Example:
	/// ```swift
	/// uploadcare.videoConversionJobStatus(token: 123456) { result in
	///     switch result {
	///     case .failure(let error):
	///         print(error)
	///     case .success(let job):
	///         print(job)
	///         switch job.status {
	///         case .failed(let conversionError):
	///             print(conversionError)
	///         default:
	///             break
	///         }
	///     }
	/// }
	/// ```
	///
	/// - Parameters:
	///   - token: Job token.
	///   - completionHandler: Completion handler.
	public func videoConversionJobStatus(token: Int, _ completionHandler: @escaping (Result<ConvertVideoJobStatus, RESTAPIError>) -> Void) {
		let url = urlWithPath("/convert/video/status/\(token)/")
		var urlRequest = requestManager.makeUrlRequest(fromURL: url, method: .get)
		requestManager.signRequest(&urlRequest)

		requestManager.performRequest(urlRequest) { (result: Result<ConvertVideoJobStatus, Error>) in
			switch result {
			case .failure(let error): completionHandler(.failure(RESTAPIError.fromError(error)))
			case .success(let status): completionHandler(.success(status))
			}
		}
	}
	#endif
	
	/// Video conversion job status.
	///
	/// Example:
	/// ```swift
	/// let job = try await uploadcare.videoConversionJobStatus(token: 123456)
	///
	/// switch job.status {
	/// case .failed(let conversionError):
	///     print(conversionError)
	/// default:
	///     break
	/// }
	/// ```
	///
	/// - Parameter token: A job token from the ``convertVideosWithSettings(_:store:)`` method .
	/// - Returns: Job status.
	@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
	public func videoConversionJobStatus(token: Int) async throws -> ConvertVideoJobStatus {
		let url = urlWithPath("/convert/video/status/\(token)/")
		var urlRequest = requestManager.makeUrlRequest(fromURL: url, method: .get)
		requestManager.signRequest(&urlRequest)

		do {
			let status: ConvertVideoJobStatus = try await requestManager.performRequest(urlRequest)
			return status
		} catch {
			throw RESTAPIError.fromError(error)
		}
	}
}

// MARK: - Upload
extension Uploadcare {
	#if !os(Linux)
	/// Upload file. This method will decide internally which upload method will be used (direct or multipart).
	///
	/// Example:
	/// ```swift
	/// guard let url = Bundle.main.url(forResource: "Mona_Lisa_23mb", withExtension: "jpg") else { return }
	/// guard let data = try? Data(contentsOf: url) else { return }
	///
	/// let task = uploadcare.uploadFile(data, withName: "some_file.ext", store: .auto, metadata: ["someKey": "someMetaValue"]) { progress in
	///     print("progress: \(progress)")
	/// } _: { result in
	///     switch result {
	///     case .failure(let error):
	///         print(error)
	///     case .success(let file):
	///         print(file)
	/// }
	///
	/// // You can cancel the uploading if needed
	/// task.cancel()
	///
	/// // You can pause the uploading
	/// (task as? UploadTaskResumable)?.pause()
	///
	/// // To resume the uploading:
	/// (task as? UploadTaskResumable)?.resume()
	/// ```
	///
	/// - Parameters:
	///   - data: File data.
	///   - name: File name.
	///   - store: Sets the file storing behavior.
	///   - uploadSignature: Sets the signature for the upload request.
	///   - onProgress: A callback that will be used to report upload progress.
	///   - completionHandler: Completion handler.
	/// - Returns: Upload task. Confirms to UploadTaskable protocol in any case. Might confirm to UploadTaskResumable protocol (which inherits UploadTaskable)  if multipart upload was used so you can pause and resume upload.
	@discardableResult
	public func uploadFile(
		_ data: Data,
		withName name: String,
		store: StoringBehavior? = nil,
		metadata: [String: String]? = nil,
		uploadSignature: UploadSignature? = nil,
		_ onProgress: ((Double) -> Void)? = nil,
		_ completionHandler: @escaping (Result<UploadedFile, UploadError>) -> Void
	) -> UploadTaskable {
		let filename = name.isEmpty ? "noname.ext" : name

		// using direct upload if file is small
		if data.count < UploadAPI.multipartMinFileSize {
			let files = [filename: data]
			return uploadAPI.directUpload(files: files, store: store, metadata: metadata, uploadSignature: uploadSignature, onProgress) { [weak self] result in
				switch result {
				case .failure(let error):
					completionHandler(.failure(error))
				case .success(let response):
					guard let fileUUID = response[filename] else {
						completionHandler(.failure(UploadError.defaultError()))
						return
					}

					if uploadSignature == nil && self?.secretKey == nil {
						let uploadedFile = UploadedFile(
							size: data.count,
							total: data.count,
							done: data.count,
							uuid: fileUUID,
							fileId: fileUUID,
							originalFilename: filename,
							filename: filename,
							mimeType: "application/octet-stream",
							isImage: false,
							isStored: store == .store,
							isReady: true,
							imageInfo: nil,
							videoInfo: nil,
							contentInfo: nil,
							metadata: metadata,
							s3Bucket: nil,
							defaultEffects: nil
						)
						completionHandler(.success(uploadedFile))
						return
					}

					self?.fileInfo(withUUID: fileUUID, { result in
						switch result {
						case .failure(let error):
							completionHandler(.failure(UploadError(status: 0, detail: error.detail)))
						case .success(let file):
							let uploadedFile = UploadedFile(
								size: file.size,
								total: file.size,
								done: file.size,
								uuid: file.uuid,
								fileId: file.uuid,
								originalFilename: file.originalFilename,
								filename: file.originalFilename,
								mimeType: file.mimeType,
								isImage: file.isImage,
								isStored: file.datetimeStored != nil,
								isReady: file.isReady,
								imageInfo: nil,
								videoInfo: nil,
								contentInfo: nil,
								metadata: nil,
								s3Bucket: nil, 
								defaultEffects: nil
							)

							completionHandler(.success(uploadedFile))
						}
					})
				}
			}
		}

		// using multipart upload otherwise
		return uploadAPI.multipartUpload(data, withName: filename, store: store, metadata: metadata, uploadSignature: uploadSignature, onProgress, completionHandler)
	}
	#endif


	/// Upload file. This method will decide internally which upload method will be used (direct or multipart).
	///
	/// Example:
	/// ```swift
	/// guard let url = Bundle.main.url(forResource: "Mona_Lisa_23mb", withExtension: "jpg") else { return }
	/// guard let data = try? Data(contentsOf: url) else { return }
	///
	/// let file = try await uploadcare.uploadFile(
	///     data,
	///     withName: "random_file_name.jpg",
	///     store: .auto
	/// ) { progress in
	///     print("progress: \(progress)")
	/// }
	/// ```
	///
	/// - Parameters:
	///   - data: File data.
	///   - name: File name.
	///   - store: Sets the file storing behavior.
	///   - metadata: File metadata.
	///   - uploadSignature: Sets the signature for the upload request.
	///   - onProgress: A callback that will be used to report upload progress.
	/// - Returns: Uploaded file.
	@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
	@discardableResult
	public func uploadFile(
		_ data: Data,
		withName name: String,
		store: StoringBehavior? = nil,
		metadata: [String: String]? = nil,
		uploadSignature: UploadSignature? = nil,
		_ onProgress: TaskProgressBlock? = nil
	) async throws -> UploadedFile {
		let filename = name.isEmpty ? "noname.ext" : name

		// using direct upload if file is small
		if data.count < UploadAPI.multipartMinFileSize {
			let files = [filename: data]

			let response = try await uploadAPI.directUploadInForeground(files: files, store: store, metadata: metadata, uploadSignature: uploadSignature)

			guard let fileUUID = response[filename] else {
				throw UploadError.defaultError()
			}

			defer {
				onProgress?(1.0)
			}

			if uploadSignature == nil && secretKey == nil {
				return UploadedFile(
					size: data.count,
					total: data.count,
					done: data.count,
					uuid: fileUUID,
					fileId: fileUUID,
					originalFilename: filename,
					filename: filename,
					mimeType: "application/octet-stream",
					isImage: false,
					isStored: store == .store,
					isReady: true,
					imageInfo: nil,
					videoInfo: nil,
					contentInfo: nil,
					metadata: metadata,
					s3Bucket: nil, 
					defaultEffects: nil
				)
			}

			let file = try await fileInfo(withUUID: fileUUID)
			return UploadedFile(
				size: file.size,
				total: file.size,
				done: file.size,
				uuid: file.uuid,
				fileId: file.uuid,
				originalFilename: file.originalFilename,
				filename: file.originalFilename,
				mimeType: file.mimeType,
				isImage: file.isImage,
				isStored: file.datetimeStored != nil,
				isReady: file.isReady,
				imageInfo: nil,
				videoInfo: nil,
				contentInfo: nil,
				metadata: nil,
				s3Bucket: nil,
				defaultEffects: nil
			)
		}

		// using multipart upload otherwise
		return try await uploadAPI.multipartUpload(data, withName: filename, store: store, metadata: metadata, uploadSignature: uploadSignature, onProgress)
	}
}

// MARK: - Factory
extension Uploadcare {
	/// Create group of uploaded files from array
	/// - Parameter files: files array
	public func group(ofFiles files: [UploadedFile]) -> UploadedFilesGroup {
		return UploadedFilesGroup(withFiles: files, uploadAPI: uploadAPI)
	}

	/// Create file model for uploading from Data
	/// - Parameters:
	///   - data: data
	///   - fileName: file name
	public func file(fromData data: Data) -> UploadedFile {
		return UploadedFile(withData: data, restAPI: self)
	}

	/// Create file model for uploading from URL
	/// - Parameters:
	///   - url: file url
	public func file(withContentsOf url: URL) -> UploadedFile? {
		var dataFromURL: Data?

		let semaphore = DispatchSemaphore(value: 0)
		DispatchQueue.global(qos: .utility).async {
			dataFromURL = try? Data(contentsOf: url, options: .mappedIfSafe)
			semaphore.signal()
		}
		semaphore.wait()

		guard let data = dataFromURL else { return nil }
		let file = UploadedFile(withData: data, restAPI: self)
		file.filename = url.lastPathComponent
		file.originalFilename = url.lastPathComponent
		return file
	}

	public func listOfFiles(_ files: [File]? = nil) -> FilesList {
		return FilesList(withFiles: files ?? [], api: self)
	}

	public func listOfGroups(_ groups: [Group]? = nil) -> GroupsList {
		return GroupsList(withGroups: groups ?? [], api: self)
	}
}

// MARK: - URLSessionTaskDelegate
extension Uploadcare: URLSessionTaskDelegate {
	public func urlSession(_ session: URLSession, task: URLSessionTask, willPerformHTTPRedirection response: HTTPURLResponse, newRequest request: URLRequest, completionHandler: @escaping (URLRequest?) -> Void) {
		if let key = task.originalRequest?.url?.absoluteString, let value = request.url?.absoluteString {
			redirectValues[key] = value
		}
		completionHandler(request)
	}
}

// MARK: - Deprecated
extension Uploadcare {
#if !os(Linux)
@available(*, unavailable, renamed: "executeAWSRekognition")
public func executeAWSRecognition(fileUUID: String, _ completionHandler: @escaping (Result<ExecuteAddonResponse, RESTAPIError>) -> Void) {}
#endif
}

@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0,  *)
extension Uploadcare {
	@available(*, unavailable, renamed: "executeAWSRekognition")
	public func executeAWSRecognition(fileUUID: String) async throws -> ExecuteAddonResponse {
		return ExecuteAddonResponse(requestID: "")
	}

	#if !os(Linux)
	@available(*, unavailable, renamed: "checkAWSRekognitionStatus")
	public func checkAWSRecognitionStatus(requestID: String, _ completionHandler: @escaping (Result<AddonExecutionStatus, RESTAPIError>) -> Void) {}
	#endif

	@available(*, unavailable, renamed: "checkAWSRekognitionStatus")
	public func checkAWSRecognitionStatus(requestID: String) async throws -> AddonExecutionStatus {
		return .unknown
	}
}
