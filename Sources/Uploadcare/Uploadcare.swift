import Foundation
import Alamofire


/// Upload API base url
let uploadAPIBaseUrl: String = "https://upload.uploadcare.com"

/// REST API base URL
let RESTAPIBaseUrl: String = "https://api.uploadcare.com"


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
	public var authScheme: AuthScheme = .signed
	

	// MARK: - Public properties
	public var uploadAPI: UploadAPI
	
	// MARK: - Private properties
	
	/// Public Key.  It is required when using Upload API.
	internal var publicKey: String
	
	/// Secret Key. Optional. Is used for authorization
	internal var secretKey: String?
	
	/// Alamofire session manager
	private var manager = Session()
	
	/// Library name
	private var libraryName = "UploadcareSwift"
	
	/// Library version
	private var libraryVersion = "0.1.0"
    
    private var redirectValues = [String: String]()
	
	
	/// Initialization
	/// - Parameter publicKey: Public Key.  It is required when using Upload API.
	public init(withPublicKey publicKey: String, secretKey: String? = nil) {
		self.publicKey = publicKey
		self.secretKey = secretKey
		
		self.uploadAPI = UploadAPI(withPublicKey: publicKey, secretKey: secretKey, manager: self.manager)
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
	func makeUrlRequest(fromURL url: URL, method: HTTPMethod) -> URLRequest {
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
				urlRequest.method?.rawValue ?? "GET",
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
}


// MARK: - REST API
extension Uploadcare {
	
	/// Get list of files
	/// - Parameters:
	///   - query: query object
	///   - completionHandler: completion handler
	public func listOfFiles(
		withQuery query: PaginationQuery?,
		_ completionHandler: @escaping (FilesList?, RESTAPIError?) -> Void
	) {
		var queryString: String?
		if let queryValue = query {
			queryString = "\(queryValue.stringValue)"
		}
		listOfFiles(withQueryString: queryString, completionHandler)
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
		var urlRequest = makeUrlRequest(fromURL: url, method: .get)
		signRequest(&urlRequest)
		
		manager.request(urlRequest)
			.validate(statusCode: 200..<300)
			.responseData { response in
				switch response.result {
				case .success(let data):
					let decodedData = try? JSONDecoder().decode(FilesList.self, from: data)

					guard let responseData = decodedData else {
						completionHandler(nil, RESTAPIError.defaultError())
						return
					}

					completionHandler(responseData, nil)
				case .failure(_):
					guard let data = response.data, let decodedData = try? JSONDecoder().decode(RESTAPIError.self, from: data) else {
						completionHandler(nil, RESTAPIError.defaultError())
						return
					}
					completionHandler(nil, decodedData)
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
		let urlString = RESTAPIBaseUrl + "/files/\(uuid)/"
		guard let url = URL(string: urlString) else {
			assertionFailure("Incorrect url")
			return
		}
		var urlRequest = makeUrlRequest(fromURL: url, method: .get)
		signRequest(&urlRequest)
		
		manager.request(urlRequest)
			.validate(statusCode: 200..<300)
			.responseData { response in
				switch response.result {
				case .success(let data):
					
					let decodedData = try? JSONDecoder().decode(File.self, from: data)
					
					guard let responseData = decodedData else {
						completionHandler(nil, RESTAPIError.defaultError())
						return
					}
					
					completionHandler(responseData, nil)
				case .failure(_):
					guard let data = response.data, let decodedData = try? JSONDecoder().decode(RESTAPIError.self, from: data) else {
						completionHandler(nil, RESTAPIError.defaultError())
						return
					}
					completionHandler(nil, decodedData)
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
		let urlString = RESTAPIBaseUrl + "/files/\(uuid)/storage/"
		guard let url = URL(string: urlString) else {
			assertionFailure("Incorrect url")
			return
		}
		var urlRequest = makeUrlRequest(fromURL: url, method: .delete)
		signRequest(&urlRequest)
		
		let redirector = Redirector(behavior: .modify({ [weak self] (task, request, response) -> URLRequest? in
			guard let url = request.url else { return request }
			guard var newRequest = self?.makeUrlRequest(fromURL: url, method: .delete) else { return request }
			self?.signRequest(&newRequest)
			return newRequest
		}))
		manager.request(urlRequest)
			.redirect(using: redirector)
			.validate(statusCode: 200..<300)
			.responseData { response in
				switch response.result {
				case .success(let data):
					
					let decodedData = try? JSONDecoder().decode(File.self, from: data)
					
					guard let responseData = decodedData else {
						completionHandler(nil, RESTAPIError.defaultError())
						return
					}
					
					completionHandler(responseData, nil)
				case .failure(_):
					guard let data = response.data, let decodedData = try? JSONDecoder().decode(RESTAPIError.self, from: data) else {
						completionHandler(nil, RESTAPIError.defaultError())
						return
					}
					completionHandler(nil, decodedData)
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
		let urlString = RESTAPIBaseUrl + "/files/storage/"
		guard let url = URL(string: urlString) else {
			assertionFailure("Incorrect url")
			return
		}
		var urlRequest = makeUrlRequest(fromURL: url, method: .delete)
		
		if let body = try? JSONEncoder().encode(uuids) {
			urlRequest.httpBody = body
		}
		signRequest(&urlRequest)
		
		manager.request(urlRequest)
			.validate(statusCode: 200..<300)
			.responseData { response in
				switch response.result {
				case .success(let data):
					let decodedData = try? JSONDecoder().decode(BatchFilesOperationResponse.self, from: data)
					
					guard let responseData = decodedData else {
						completionHandler(nil, RESTAPIError.defaultError())
						return
					}
					
					completionHandler(responseData, nil)
				case .failure(_):
					guard let data = response.data, let decodedData = try? JSONDecoder().decode(RESTAPIError.self, from: data) else {
						completionHandler(nil, RESTAPIError.defaultError())
						return
					}
					completionHandler(nil, decodedData)
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
		let urlString = RESTAPIBaseUrl + "/files/\(uuid)/storage/"
		guard let url = URL(string: urlString) else {
			assertionFailure("Incorrect url")
			return
		}
		var urlRequest = makeUrlRequest(fromURL: url, method: .put)
		signRequest(&urlRequest)
		
		manager.request(urlRequest)
			.validate(statusCode: 200..<300)
			.responseData { response in
				switch response.result {
				case .success(let data):
					
					let decodedData = try? JSONDecoder().decode(File.self, from: data)
					
					guard let responseData = decodedData else {
						completionHandler(nil, RESTAPIError.defaultError())
						return
					}
					
					completionHandler(responseData, nil)
				case .failure(_):
					guard let data = response.data, let decodedData = try? JSONDecoder().decode(RESTAPIError.self, from: data) else {
						completionHandler(nil, RESTAPIError.defaultError())
						return
					}
					completionHandler(nil, decodedData)
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
		let urlString = RESTAPIBaseUrl + "/files/storage/"
		guard let url = URL(string: urlString) else {
			assertionFailure("Incorrect url")
			return
		}
		var urlRequest = makeUrlRequest(fromURL: url, method: .put)
		
		if let body = try? JSONEncoder().encode(uuids) {
			urlRequest.httpBody = body
		}
		signRequest(&urlRequest)
		
		manager.request(urlRequest)
			.validate(statusCode: 200..<300)
			.responseData { response in
				switch response.result {
				case .success(let data):
					let decodedData = try? JSONDecoder().decode(BatchFilesOperationResponse.self, from: data)
					
					guard let responseData = decodedData else {
						completionHandler(nil, RESTAPIError.defaultError())
						return
					}
					
					completionHandler(responseData, nil)
				case .failure(_):
					guard let data = response.data, let decodedData = try? JSONDecoder().decode(RESTAPIError.self, from: data) else {
						completionHandler(nil, RESTAPIError.defaultError())
						return
					}
					completionHandler(nil, decodedData)
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
		
		manager.request(urlRequest)
			.validate(statusCode: 200..<300)
			.responseData { response in
				switch response.result {
				case .success(let data):
					let decodedData = try? JSONDecoder().decode(GroupsList.self, from: data)
					
					guard let responseData = decodedData else {
						completionHandler(nil, RESTAPIError.defaultError())
						return
					}

					completionHandler(responseData, nil)
				case .failure(_):
					guard let data = response.data, let decodedData = try? JSONDecoder().decode(RESTAPIError.self, from: data) else {
						completionHandler(nil, RESTAPIError.defaultError())
						return
					}
					completionHandler(nil, decodedData)
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
		let urlString = RESTAPIBaseUrl + "/groups/\(uuid)/"
		guard let url = URL(string: urlString) else {
			assertionFailure("Incorrect url")
			return
		}
		var urlRequest = makeUrlRequest(fromURL: url, method: .get)
		signRequest(&urlRequest)
		
		manager.request(urlRequest)
			.validate(statusCode: 200..<300)
			.responseData { response in
				switch response.result {
				case .success(let data):
					
					let decodedData = try? JSONDecoder().decode(Group.self, from: data)
					
					guard let responseData = decodedData else {
						completionHandler(nil, RESTAPIError.defaultError())
						return
					}
					
					completionHandler(responseData, nil)
				case .failure(_):
					guard let data = response.data, let decodedData = try? JSONDecoder().decode(RESTAPIError.self, from: data) else {
						completionHandler(nil, RESTAPIError.defaultError())
						return
					}
					completionHandler(nil, decodedData)
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
		let urlString = RESTAPIBaseUrl + "/groups/\(uuid)/storage/"
		guard let url = URL(string: urlString) else {
			assertionFailure("Incorrect url")
			return
		}
		var urlRequest = makeUrlRequest(fromURL: url, method: .put)
		signRequest(&urlRequest)
		
		manager.request(urlRequest)
			.validate(statusCode: 200..<300)
			.responseData { response in
				switch response.result {
				case .success(_):
					completionHandler(nil)
				case .failure(_):
					guard let data = response.data, let decodedData = try? JSONDecoder().decode(RESTAPIError.self, from: data) else {
						completionHandler(RESTAPIError.defaultError())
						return
					}
					completionHandler(decodedData)
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
		let urlString = RESTAPIBaseUrl + "/files/local_copy/"
		guard let url = URL(string: urlString) else {
			assertionFailure("Incorrect url")
			return
		}
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
		
		manager.request(urlRequest)
			.validate(statusCode: 200..<300)
			.responseData { response in
				switch response.result {
				case .success(let data):
					let decodedData = try? JSONDecoder().decode(CopyFileToLocalStorageResponse.self, from: data)
					
					guard let responseData = decodedData else {
						DLog(String(data: data, encoding: .utf8) ?? "")
						completionHandler(nil, RESTAPIError.defaultError())
						return
					}
					
					completionHandler(responseData, nil)
				case .failure(_):
					guard let data = response.data, let decodedData = try? JSONDecoder().decode(RESTAPIError.self, from: data) else {
						completionHandler(nil, RESTAPIError.defaultError())
						return
					}
					completionHandler(nil, decodedData)
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
		let urlString = RESTAPIBaseUrl + "/files/remote_copy/"
		guard let url = URL(string: urlString) else {
			assertionFailure("Incorrect url")
			return
		}
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
		
		manager.request(urlRequest)
			.validate(statusCode: 200..<300)
			.responseData { response in
				switch response.result {
				case .success(let data):
					let decodedData = try? JSONDecoder().decode(CopyFileToRemoteStorageResponse.self, from: data)
					
					guard let responseData = decodedData else {
						DLog(String(data: data, encoding: .utf8) ?? "")
						completionHandler(nil, RESTAPIError.defaultError())
						return
					}
					
					completionHandler(responseData, nil)
				case .failure(_):
					guard let data = response.data, let decodedData = try? JSONDecoder().decode(RESTAPIError.self, from: data) else {
						completionHandler(nil, RESTAPIError.defaultError())
						return
					}
					completionHandler(nil, decodedData)
				}
		}
	}
	
	/// Getting info about account project.
	/// - Parameter completionHandler: completion handler
	public func getProjectInfo(_ completionHandler: @escaping (Project?, RESTAPIError?) -> Void) {
		let urlString = RESTAPIBaseUrl + "/project/"
		guard let url = URL(string: urlString) else {
			assertionFailure("Incorrect url")
			return
		}
		var urlRequest = makeUrlRequest(fromURL: url, method: .get)
		signRequest(&urlRequest)
		
		manager.request(urlRequest)
			.validate(statusCode: 200..<300)
			.responseData { response in
				switch response.result {
				case .success(let data):
					let decodedData = try? JSONDecoder().decode(Project.self, from: data)

					guard let responseData = decodedData else {
						completionHandler(nil, RESTAPIError.defaultError())
						return
					}

					completionHandler(responseData, nil)
				case .failure(_):
					guard let data = response.data, let decodedData = try? JSONDecoder().decode(RESTAPIError.self, from: data) else {
						completionHandler(nil, RESTAPIError.defaultError())
						return
					}
					completionHandler(nil, decodedData)
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
        let urlString = RESTAPIBaseUrl + "/webhooks/"
        guard let url = URL(string: urlString) else {
            assertionFailure("Incorrect url")
            return
        }
        var urlRequest = makeUrlRequest(fromURL: url, method: .get)
        signRequest(&urlRequest)
        
        manager.request(urlRequest)
            .validate(statusCode: 200..<300)
            .responseData { response in
                switch response.result {
                case .success(let data):
                    let decodedData = try? JSONDecoder().decode([Webhook].self, from: data)

                    guard let responseData = decodedData else {
                        completionHandler(nil, RESTAPIError.defaultError())
                        return
                    }

                    completionHandler(responseData, nil)
                case .failure(_):
                    guard let data = response.data, let decodedData = try? JSONDecoder().decode(RESTAPIError.self, from: data) else {
                        completionHandler(nil, RESTAPIError.defaultError())
                        return
                    }
                    completionHandler(nil, decodedData)
                }
        }
    }
    
    /// Create webhook
    /// - Parameters:
    ///   - targetUrl: A URL that is triggered by an event, for example, a file upload. A target URL MUST be unique for each project — event type combination.
    ///   - isActive: Marks a subscription as either active or not, defaults to true, otherwise false.
    ///   - completionHandler: completion handler
    public func createWebhook(targetUrl: URL, isActive: Bool, _ completionHandler: @escaping (Webhook?, RESTAPIError?) -> Void) {
        let urlString = RESTAPIBaseUrl + "/webhooks/"
        guard let url = URL(string: urlString) else {
            assertionFailure("Incorrect url")
            return
        }
        var urlRequest = makeUrlRequest(fromURL: url, method: .post)
        let bodyDictionary = [
            "target_url": targetUrl.absoluteString,
            "event": "file.uploaded", // Presently, we only support the file.uploaded event.
            "is_active": "\(isActive)"
        ]
        if let body = try? JSONEncoder().encode(bodyDictionary) {
            urlRequest.httpBody = body
        }
        signRequest(&urlRequest)
        
        manager.request(urlRequest)
            .validate(statusCode: 200..<300)
            .responseData { response in
                switch response.result {
                case .success(let data):
                    let decodedData = try? JSONDecoder().decode(Webhook.self, from: data)
                    
                    guard let responseData = decodedData else {
                        DLog(String(data: data, encoding: .utf8) ?? "")
                        completionHandler(nil, RESTAPIError.defaultError())
                        return
                    }
                    
                    completionHandler(responseData, nil)
                case .failure(_):
                    guard let data = response.data, let decodedData = try? JSONDecoder().decode(RESTAPIError.self, from: data) else {
                        DLog(response.data?.toString() ?? "")
                        completionHandler(nil, RESTAPIError.defaultError())
                        return
                    }
                    completionHandler(nil, decodedData)
                }
        }
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
