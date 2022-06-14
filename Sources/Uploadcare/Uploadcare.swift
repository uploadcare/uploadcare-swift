import Foundation


/// Upload API base url
let uploadAPIBaseUrl = "https://upload.uploadcare.com"
let uploadAPIHost = "upload.uploadcare.com"

/// REST API base URL
let RESTAPIBaseUrl = "https://api.uploadcare.com"
let RESTAPIHost = "api.uploadcare.com"


public class Uploadcare: NSObject {
	
	// TODO: log turn on or off
	// TODO: add logs
	
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
	
	/// Library name
	private var libraryName = "UploadcareSwift"
	/// Library version
	private var libraryVersion = "0.6.0"

	/// Performs network requests
	private let requestManager: RequestManager

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
	/// Build url request for REST API
	/// - Parameter fromURL: request url
	func makeUrlRequest(fromURL url: URL, method: RequestManager.HTTPMethod) -> URLRequest {
		var urlRequest = URLRequest(url: url)
		urlRequest.httpMethod = method.rawValue
		urlRequest.addValue("application/json", forHTTPHeaderField: "Content-Type")
		urlRequest.addValue("application/vnd.uploadcare-v0.6+json", forHTTPHeaderField: "Accept")
		
		let userAgent = "\(libraryName)/\(libraryVersion)/\(publicKey) (Swift/\(getSwiftVersion()))"
		urlRequest.addValue(userAgent, forHTTPHeaderField: "User-Agent")
		
		return urlRequest
	}
	
	/// Adds signature to network request for secure authorization
	/// - Parameter urlRequest: url request
	func signRequest(_ urlRequest: inout URLRequest) {
		let dateString = GMTDate()
		urlRequest.addValue(dateString, forHTTPHeaderField: "Date")
		
		let secretKey = self.secretKey ?? ""
		
		switch authScheme {
		case .simple:
			urlRequest.addValue("\(authScheme.rawValue) \(publicKey):\(secretKey )", forHTTPHeaderField: "Authorization")
		case .signed:
			let content = urlRequest.httpBody?.toString() ?? ""
			
			var query = "/"
			if let q = urlRequest.url?.query {
				query = "/?" + q
			}
			let uri = (urlRequest.url?.path ?? "") + query

			let signString = [
				urlRequest.httpMethod ?? "GET",
				content.md5(),
				urlRequest.allHTTPHeaderFields?["Content-Type"] ?? "application/json",
				dateString,
				uri
			].joined(separator: "\n")
			
			let signature = signString.hmac(key: secretKey)
			
			let authHeader = "\(authScheme.rawValue) \(publicKey):\(signature)"
			urlRequest.addValue(authHeader, forHTTPHeaderField: "Authorization")
		}
	}

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
	
	/// Get list of files
	/// - Parameters:
	///   - query: query object
	///   - completionHandler: completion handler
	public func listOfFiles(withQuery query: PaginationQuery?, _ completionHandler: @escaping (FilesList?, RESTAPIError?) -> Void) {
		listOfFiles(withQueryString: query?.stringValue, completionHandler)
	}
	
	/// Get list of files
	/// - Parameters:
	///   - query: query string
	///   - completionHandler: completion handler
	internal func listOfFiles(
		withQueryString query: String?,
		_ completionHandler: @escaping (FilesList?, RESTAPIError?) -> Void
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
			case .failure(let error): completionHandler(nil, RESTAPIError.fromError(error))
			case .success(let responseData): completionHandler(responseData, nil)
			}
		}
	}
	
	/// File Info. Once you obtain a list of files, you might want to acquire some file-specific info.
	/// - Parameters:
	///   - uuid: FILE UUID
	///   - completionHandler: completion handler
	public func fileInfo(
		withUUID uuid: String,
		_ completionHandler: @escaping (File?, RESTAPIError?) -> Void
	) {
		let url = urlWithPath("/files/\(uuid)/")
		var urlRequest = makeUrlRequest(fromURL: url, method: .get)
		signRequest(&urlRequest)

		requestManager.performRequest(urlRequest) { (result: Result<File, Error>) in
			switch result {
			case .failure(let error): completionHandler(nil, RESTAPIError.fromError(error))
			case .success(let responseData): completionHandler(responseData, nil)
			}
		}
	}
	
	/// Delete file. Beside deleting in a multi-file mode, you can remove individual files.
	/// - Parameters:
	///   - uuid: file UUID
	///   - completionHandler: completion handler
	public func deleteFile(
		withUUID uuid: String,
		_ completionHandler: @escaping (File?, RESTAPIError?) -> Void
	) {
		let url = urlWithPath("/files/\(uuid)/storage/")
		var urlRequest = makeUrlRequest(fromURL: url, method: .delete)
		signRequest(&urlRequest)
		
		requestManager.performRequest(urlRequest) { (result: Result<File, Error>) in
			switch result {
			case .failure(let error): completionHandler(nil, RESTAPIError.fromError(error))
			case .success(let responseData): completionHandler(responseData, nil)
			}
		}
	}
	
	/// Batch file delete. Used to delete multiple files in one go. Up to 100 files are supported per request.
	/// - Parameters:
	///   - uuids: List of files UUIDs to store.
	///   - completionHandler: completion handler
	public func deleteFiles(
		withUUIDs uuids: [String],
		_ completionHandler: @escaping (BatchFilesOperationResponse?, RESTAPIError?) -> Void
	) {
		let url = urlWithPath("/files/storage/")
		var urlRequest = makeUrlRequest(fromURL: url, method: .delete)
		
		if let body = try? JSONEncoder().encode(uuids) {
			urlRequest.httpBody = body
		}
		signRequest(&urlRequest)

		requestManager.performRequest(urlRequest) { (result: Result<BatchFilesOperationResponse, Error>) in
			switch result {
			case .failure(let error): completionHandler(nil, RESTAPIError.fromError(error))
			case .success(let responseData): completionHandler(responseData, nil)
			}
		}
	}
	
	/// Store a single file by UUID.
	/// - Parameters:
	///   - uuid: file UUID
	///   - completionHandler: completion handler
	public func storeFile(
		withUUID uuid: String,
		_ completionHandler: @escaping (File?, RESTAPIError?) -> Void
	) {
		let url = urlWithPath("/files/\(uuid)/storage/")
		var urlRequest = makeUrlRequest(fromURL: url, method: .put)
		signRequest(&urlRequest)

		requestManager.performRequest(urlRequest) { (result: Result<File, Error>) in
			switch result {
			case .failure(let error): completionHandler(nil, RESTAPIError.fromError(error))
			case .success(let responseData): completionHandler(responseData, nil)
			}
		}
	}
	
	/// Batch file storing. Used to store multiple files in one go. Up to 100 files are supported per request.
	/// - Parameters:
	///   - uuids: List of files UUIDs to store.
	///   - completionHandler: completion handler
	public func storeFiles(
		withUUIDs uuids: [String],
		_ completionHandler: @escaping (BatchFilesOperationResponse?, RESTAPIError?) -> Void
	) {
		let url = urlWithPath("/files/storage/")
		var urlRequest = makeUrlRequest(fromURL: url, method: .put)

		if let body = try? JSONEncoder().encode(uuids) {
			urlRequest.httpBody = body
		}
		signRequest(&urlRequest)

		requestManager.performRequest(urlRequest) { (result: Result<BatchFilesOperationResponse, Error>) in
			switch result {
			case .failure(let error): completionHandler(nil, RESTAPIError.fromError(error))
			case .success(let responseData): completionHandler(responseData, nil)
			}
		}
	}
	
	/// Get list of groups
	/// - Parameters:
	///   - query: query object
	///   - completionHandler: completion handler
	public func listOfGroups(
		withQuery query: GroupsListQuery?,
		_ completionHandler: @escaping (GroupsList?, RESTAPIError?) -> Void
	) {
		var queryString: String?
		if let queryValue = query {
			queryString = "\(queryValue.stringValue)"
		}
		listOfGroups(withQueryString: queryString, completionHandler)
	}
	
	/// Get list of groups
	/// - Parameters:
	///   - query: query string
	///   - completionHandler: completion handler
	internal func listOfGroups(
		withQueryString query: String?,
		_ completionHandler: @escaping (GroupsList?, RESTAPIError?) -> Void
	) {
		var urlString = RESTAPIBaseUrl + "/groups/"
		if let queryValue = query {
			urlString += "?\(queryValue)"
		}
		
		guard let url = URL(string: urlString) else {
			assertionFailure("Incorrect url")
			return
		}
		var urlRequest = makeUrlRequest(fromURL: url, method: .get)
		signRequest(&urlRequest)

		requestManager.performRequest(urlRequest) { (result: Result<GroupsList, Error>) in
			switch result {
			case .failure(let error): completionHandler(nil, RESTAPIError.fromError(error))
			case .success(let responseData): completionHandler(responseData, nil)
			}
		}
	}
	
	/// Get a file group by UUID.
	/// - Parameters:
	///   - uuid: Group UUID.
	///   - completionHandler: completion handler
	public func groupInfo(
		withUUID uuid: String,
		_ completionHandler: @escaping (Group?, RESTAPIError?) -> Void
	) {
		let url = urlWithPath("/groups/\(uuid)/")
		var urlRequest = makeUrlRequest(fromURL: url, method: .get)
		signRequest(&urlRequest)

		requestManager.performRequest(urlRequest) { (result: Result<Group, Error>) in
			switch result {
			case .failure(let error): completionHandler(nil, RESTAPIError.fromError(error))
			case .success(let responseData): completionHandler(responseData, nil)
			}
		}
	}
	
	/// Mark all files in a group as stored.
	/// - Parameters:
	///   - uuid: Group UUID.
	///   - completionHandler: completion handler
	public func storeGroup(
		withUUID uuid: String,
		_ completionHandler: @escaping (RESTAPIError?) -> Void
	) {
		let url = urlWithPath("/groups/\(uuid)/storage/")
		var urlRequest = makeUrlRequest(fromURL: url, method: .put)
		signRequest(&urlRequest)

		requestManager.performRequest(urlRequest) { (result: Result<Group, Error>) in
			switch result {
			case .failure(let error): completionHandler(RESTAPIError.fromError(error))
			case .success(_): completionHandler(nil)
			}
		}
	}
	
	/// Copy file to local storage. Used to copy original files or their modified versions to default storage. Source files MAY either be stored or just uploaded and MUST NOT be deleted.
	/// - Parameters:
	///   - source: A CDN URL or just UUID of a file subjected to copy.
	///   - store: The parameter only applies to the Uploadcare storage. Default: "false"
	///   - makePublic: Applicable to custom storage only. True to make copied files available via public links, false to reverse the behavior. Default: "true"
	///   - completionHandler: completion handler
	public func copyFileToLocalStorage(
		source: String,
		store: Bool? = nil,
		makePublic: Bool? = nil,
		_ completionHandler: @escaping (CopyFileToLocalStorageResponse?, RESTAPIError?) -> Void
	) {
		let url = urlWithPath("/files/local_copy/")
		var urlRequest = makeUrlRequest(fromURL: url, method: .post)
		
		let bodyDictionary = [
			"source": source,
			"store": "\(store ?? false)",
			"make_public": "\(makePublic ?? true)"
		]
		if let body = try? JSONEncoder().encode(bodyDictionary) {
			urlRequest.httpBody = body
		}
		signRequest(&urlRequest)

		requestManager.performRequest(urlRequest) { (result: Result<CopyFileToLocalStorageResponse, Error>) in
			switch result {
			case .failure(let error): completionHandler(nil, RESTAPIError.fromError(error))
			case .success(let responseData): completionHandler(responseData, nil)
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
	public func copyFileToRemoteStorage(
		source: String,
		target: String,
		makePublic: Bool? = nil,
		pattern: NamesPattern?,
		_ completionHandler: @escaping (CopyFileToRemoteStorageResponse?, RESTAPIError?) -> Void
	) {
		let url = urlWithPath("/files/remote_copy/")
		var urlRequest = makeUrlRequest(fromURL: url, method: .post)
		
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
		signRequest(&urlRequest)

		requestManager.performRequest(urlRequest) { (result: Result<CopyFileToRemoteStorageResponse, Error>) in
			switch result {
			case .failure(let error): completionHandler(nil, RESTAPIError.fromError(error))
			case .success(let responseData): completionHandler(responseData, nil)
			}
		}
	}
	
	/// Getting info about account project.
	/// - Parameter completionHandler: completion handler
	public func getProjectInfo(_ completionHandler: @escaping (Project?, RESTAPIError?) -> Void) {
		let url = urlWithPath("/project/")
		var urlRequest = makeUrlRequest(fromURL: url, method: .get)
		signRequest(&urlRequest)

		requestManager.performRequest(urlRequest) { (result: Result<Project, Error>) in
			switch result {
			case .failure(let error): completionHandler(nil, RESTAPIError.fromError(error))
			case .success(let responseData): completionHandler(responseData, nil)
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
	public func getAuthenticatedUrlFromUrl(_ url: URL, _ completionHandler: @escaping (String?, RESTAPIError?) -> Void) {
		let urlString = url.absoluteString
        
		redirectValues[urlString] = ""

		let config = URLSessionConfiguration.default
		let urlSession = URLSession(configuration: config, delegate: self, delegateQueue: nil)

		let task = urlSession.dataTask(with: url) { [weak self] (data, response, error) in
			guard let self = self else { return }

			defer { self.redirectValues.removeValue(forKey: urlString) }

			if let error = error {
				completionHandler(nil, RESTAPIError(detail: error.localizedDescription))
				return
			}

			guard let redirectUrl = self.redirectValues[urlString], redirectUrl.isEmpty == false else {
				completionHandler(nil, RESTAPIError(detail: "No redirect happened"))
				return
			}

			completionHandler(redirectUrl, nil)
		}
		task.resume()
    }
    
    /// List of project webhooks.
    /// - Parameter completionHandler: completion handler
	public func getListOfWebhooks(_ completionHandler: @escaping ([Webhook]?, RESTAPIError?) -> Void) {
		let url = urlWithPath("/webhooks/")
		var urlRequest = makeUrlRequest(fromURL: url, method: .get)
		signRequest(&urlRequest)

		requestManager.performRequest(urlRequest) { (result: Result<[Webhook], Error>) in
			switch result {
			case .failure(let error): completionHandler(nil, RESTAPIError.fromError(error))
			case .success(let responseData): completionHandler(responseData, nil)
			}
		}
	}
    
    /// Create webhook
    /// - Parameters:
    ///   - targetUrl: A URL that is triggered by an event, for example, a file upload. A target URL MUST be unique for each project — event type combination.
    ///   - isActive: Marks a subscription as either active or not, defaults to true, otherwise false.
    ///   - signingSecret: Optional secret that, if set, will be used to calculate signatures for the webhook payloads
    ///   - completionHandler: completion handler
	public func createWebhook(targetUrl: URL, isActive: Bool, signingSecret: String? = nil, _ completionHandler: @escaping (Webhook?, RESTAPIError?) -> Void) {
		let url = urlWithPath("/webhooks/")
		var urlRequest = makeUrlRequest(fromURL: url, method: .post)
		var bodyDictionary = [
			"target_url": targetUrl.absoluteString,
			"event": "file.uploaded", // Presently, we only support the file.uploaded event.
			"is_active": "\(isActive)"
		]

		if let signingSecret = signingSecret {
			bodyDictionary["signing_secret"] = signingSecret
		}

		do {
			urlRequest.httpBody = try JSONEncoder().encode(bodyDictionary)
		} catch let error {
			DLog(error.localizedDescription)
		}
		signRequest(&urlRequest)

		requestManager.performRequest(urlRequest) { (result: Result<Webhook, Error>) in
			switch result {
			case .failure(let error): completionHandler(nil, RESTAPIError.fromError(error))
			case .success(let responseData): completionHandler(responseData, nil)
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
	public func updateWebhook(id: Int, targetUrl: URL, isActive: Bool, signingSecret: String? = nil, _ completionHandler: @escaping (Webhook?, RESTAPIError?) -> Void) {
		let url = urlWithPath("/webhooks/\(id)/")
		var urlRequest = makeUrlRequest(fromURL: url, method: .put)
		var bodyDictionary = [
			"target_url": targetUrl.absoluteString,
			"event": "file.uploaded", // Presently, we only support the file.uploaded event.
			"is_active": "\(isActive)"
		]

		if let signingSecret = signingSecret {
			bodyDictionary["signing_secret"] = signingSecret
		}

		do {
			urlRequest.httpBody = try JSONEncoder().encode(bodyDictionary)
		} catch let error {
			DLog(error.localizedDescription)
		}
		signRequest(&urlRequest)

		requestManager.performRequest(urlRequest) { (result: Result<Webhook, Error>) in
			switch result {
			case .failure(let error): completionHandler(nil, RESTAPIError.fromError(error))
			case .success(let responseData): completionHandler(responseData, nil)
			}
		}
	}
	
	/// Delete webhook
	/// - Parameters:
	///   - targetUrl: url of webhook target
	///   - completionHandler: completion handler
	public func deleteWebhook(forTargetUrl targetUrl: URL, _ completionHandler: @escaping (RESTAPIError?) -> Void) {
		let url = urlWithPath("/webhooks/unsubscribe/")
		var urlRequest = makeUrlRequest(fromURL: url, method: .delete)
		let bodyDictionary = [
			"target_url": targetUrl.absoluteString
		]
		do {
			urlRequest.httpBody = try JSONEncoder().encode(bodyDictionary)
		} catch let error {
			DLog(error.localizedDescription)
		}
		signRequest(&urlRequest)

		requestManager.performRequest(urlRequest) { (result: Result<Bool, Error>) in
			switch result {
			case .failure(let error): completionHandler(RESTAPIError.fromError(error))
			case .success(_): completionHandler(nil)
			}
		}
	}
	
	/// Uploadcare allows converting documents to the following target formats: DOC, DOCX, XLS, XLSX, ODT, ODS, RTF, TXT, PDF, JPG, PNG.
	/// - Parameters:
	///   - paths: An array of UUIDs of your source documents to convert together with the specified target format.
	///   See documentation: https://uploadcare.com/docs/transformations/document_conversion/#convert-url-formatting
	///   - store: A flag indicating if we should store your outputs.
	///   - completionHandler: completion handler
	public func convertDocuments(
		_ paths: [String],
		store: StoringBehavior? = nil,
		_ completionHandler: @escaping (ConvertDocumentsResponse?, RESTAPIError?) -> Void
	) {
		let url = urlWithPath("/convert/document/")
		var urlRequest = makeUrlRequest(fromURL: url, method: .post)
		
		let storeValue = store == StoringBehavior.auto ? .store : store
		let requestData = ConvertRequestData(
			paths: paths,
			store: storeValue?.rawValue ?? StoringBehavior.store.rawValue
		)

		urlRequest.httpBody = try? JSONEncoder().encode(requestData)
		signRequest(&urlRequest)

		requestManager.performRequest(urlRequest) { (result: Result<ConvertDocumentsResponse, Error>) in
			switch result {
			case .failure(let error): completionHandler(nil, RESTAPIError.fromError(error))
			case .success(let responseData): completionHandler(responseData, nil)
			}
		}
	}
	
	/// Convert documents
	/// - Parameters:
	///   - files: files array
	///   - format: target format (DOC, DOCX, XLS, XLSX, ODT, ODS, RTF, TXT, PDF, JPG, PNG)
	///   - store: A flag indicating if we should store your outputs.
	///   - completionHandler: completion handler
	public func convertDocumentsWithSettings(
		_ tasks: [DocumentConversionJobSettings],
		store: StoringBehavior? = nil,
		_ completionHandler: @escaping (ConvertDocumentsResponse?, RESTAPIError?) -> Void
	) {
		var paths = [String]()
		tasks.forEach({ paths.append($0.stringValue) })
		convertDocuments(paths, store: store, completionHandler)
	}
	
	/// Document conversion job status
	/// - Parameters:
	///   - token: Job token
	///   - completionHandler: completion handler
	public func documentConversionJobStatus(token: Int, _ completionHandler: @escaping (ConvertDocumentJobStatus?, RESTAPIError?) -> Void) {
		let url = urlWithPath("/convert/document/status/\(token)/")
		var urlRequest = makeUrlRequest(fromURL: url, method: .get)
		signRequest(&urlRequest)

		requestManager.performRequest(urlRequest) { (result: Result<ConvertDocumentJobStatus, Error>) in
			switch result {
			case .failure(let error): completionHandler(nil, RESTAPIError.fromError(error))
			case .success(let responseData): completionHandler(responseData, nil)
			}
		}
	}
	
	/// Convert videos with settings
	/// - Parameters:
	///   - tasks: array of VideoConversionJobSettings objects which settings for conversion for every file
	///   - store: A flag indicating if we should store your outputs.
	///   - completionHandler: completion handler
	public func convertVideosWithSettings(
		_ tasks: [VideoConversionJobSettings],
		store: StoringBehavior? = nil,
		_ completionHandler: @escaping (ConvertDocumentsResponse?, RESTAPIError?) -> Void
	) {
		var paths = [String]()
		tasks.forEach({ paths.append($0.stringValue) })
		convertVideos(paths, completionHandler)
	}
	
	/// Convert video
	/// - Parameters:
	///   - paths: An array of UUIDs of your video files to process together with a set of needed operations.
	///   See documentation: https://uploadcare.com/docs/transformations/video_encoding/#process-operations
	///   - store: A flag indicating if we should store your outputs.
	///   - completionHandler: completion handler
	public func convertVideos(
		_ paths: [String],
		store: StoringBehavior? = nil,
		_ completionHandler: @escaping (ConvertDocumentsResponse?, RESTAPIError?) -> Void
	) {
		let url = urlWithPath("/convert/video/")
		var urlRequest = makeUrlRequest(fromURL: url, method: .post)
		
		let storeValue = store == StoringBehavior.auto ? .store : store
		let requestData = ConvertRequestData(
			paths: paths,
			store: storeValue?.rawValue ?? StoringBehavior.store.rawValue
		)

		urlRequest.httpBody = try? JSONEncoder().encode(requestData)
		signRequest(&urlRequest)

		requestManager.performRequest(urlRequest) { (result: Result<ConvertDocumentsResponse, Error>) in
			switch result {
			case .failure(let error): completionHandler(nil, RESTAPIError.fromError(error))
			case .success(let responseData): completionHandler(responseData, nil)
			}
		}
	}
	
	/// Video conversion job status
	/// - Parameters:
	///   - token: Job token
	///   - completionHandler: completion handler
	public func videoConversionJobStatus(token: Int, _ completionHandler: @escaping (ConvertVideoJobStatus?, RESTAPIError?) -> Void) {
		let url = urlWithPath("/convert/video/status/\(token)/")
		var urlRequest = makeUrlRequest(fromURL: url, method: .get)
		signRequest(&urlRequest)

		requestManager.performRequest(urlRequest) { (result: Result<ConvertVideoJobStatus, Error>) in
			switch result {
			case .failure(let error): completionHandler(nil, RESTAPIError.fromError(error))
			case .success(let responseData): completionHandler(responseData, nil)
			}
		}
	}
}

// MARK: - Upload
extension Uploadcare {
	/// Upload file. This method will decide internally which upload will be used (direct or multipart)
	/// - Parameters:
	///   - data: File data
	///   - name: File name
	///   - store: Sets the file storing behavior
	///   - onProgress: A callback that will be used to report upload progress
	///   - completionHandler: Completion handler
	/// - Returns: Upload task. Confirms to UploadTaskable protocol in anycase. Might confirm to UploadTaskResumable protocol (which inherits UploadTaskable)  if multipart upload was used so you can pause and resume upload
	@discardableResult
	public func uploadFile(
		_ data: Data,
		withName name: String,
		store: StoringBehavior? = nil,
		_ onProgress: ((Double) -> Void)? = nil,
		_ completionHandler: @escaping (UploadedFile?, UploadError?) -> Void
	) -> UploadTaskable {
		let filename = name.isEmpty ? "noname.ext" : name

		// using direct upload if file is small
		if data.count < UploadAPI.multipartMinFileSize {
			let files = [filename: data]
			return uploadAPI.directUpload(files: files, store: store, onProgress) { [weak self] response, error in
				if let error = error {
					completionHandler(nil, error)
					return
				}

				guard let response = response, let fileUUID = response[filename] else {
					completionHandler(nil, UploadError.defaultError())
					return
				}

				self?.fileInfo(withUUID: fileUUID, { file, error in
					if let error = error {
						let uploadError = UploadError(status: 0, detail: error.detail)
						completionHandler(nil, uploadError)
						return
					}

					guard let file = file else {
						completionHandler(nil, UploadError.defaultError())
						return
					}

					let uploadedFile = UploadedFile(
						size: file.size,
						total: file.size,
						uuid: file.uuid,
						fileId: file.uuid,
						originalFilename: file.originalFilename,
						filename: file.originalFilename,
						mimeType: file.mimeType,
						isImage: file.isImage,
						isStored: store != .doNotStore,
						isReady: file.isReady,
						imageInfo: file.imageInfo,
						videoInfo: file.videoInfo,
						s3Bucket: nil
					)

					completionHandler(uploadedFile, nil)
					return
				})
			}
		}

		// using multipart upload otherwise
		return uploadAPI.multipartUpload(data, withName: filename, store: store, onProgress, completionHandler)
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

// MARK: - Factory
extension Uploadcare {
	public func listOfFiles(_ files: [File]? = nil) -> FilesList {
		return FilesList(withFiles: files ?? [], api: self)
	}
	
	public func listOfGroups(_ groups: [Group]? = nil) -> GroupsList {
		return GroupsList(withGroups: groups ?? [], api: self)
	}
}
