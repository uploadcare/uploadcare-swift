import Foundation
import Alamofire


/// Upload API base url
let uploadAPIBaseUrl: String = "https://upload.uploadcare.com"

/// REST API base URL
let RESTAPIBaseUrl: String = "https://api.uploadcare.com"


public struct Uploadcare {
	
	/// Authorization scheme for REST API requests
	public enum AuthScheme: String {
		case simple = "Uploadcare.Simple"
		case signed = "Uploadcare"
	}
	
	/// Public Key.  It is required when using Upload API.
	internal var publicKey: String
	
	/// Secret Key. Is used for authorization
	internal var secretKey: String
	
	/// Auth scheme
	internal var authScheme: AuthScheme = .simple
	
	/// Alamofire session manager
	private var manager = SessionManager()
	
	
	/// Initialization
	/// - Parameter publicKey: Public Key.  It is required when using Upload API.
	public init(withPublicKey publicKey: String, secretKey: String) {
		self.publicKey = publicKey
		self.secretKey = secretKey
	}
	
	
	/// Method for integration testing
	public static func sayHi() {
		print("Uploadcare says Hi!")
	}
}


private extension Uploadcare {
	func makeError(fromResponse response: DataResponse<Data>) -> Error {
		let status: Int = response.response?.statusCode ?? 0
		
		var message = ""
		if let data = response.data {
			message = String(data: data, encoding: .utf8) ?? ""
		}
		
		return Error(status: status, message: message)
	}
}


// MARK: - Upload API
extension Uploadcare {
	
	/// File info
	/// - Parameters:
	///   - fileId: File ID
	///   - completionHandler: completion handler
	public func uploadedFileInfo(
		withFileId fileId: String,
		_ completionHandler: @escaping (UploadedFileInfo?, Error?) -> Void
	) {
		let urlString = uploadAPIBaseUrl + "/info?pub_key=\(self.publicKey)&file_id=\(fileId)"
		guard let url = URL(string: urlString) else {
			assertionFailure("Incorrect url")
			return
		}
		var urlRequest = URLRequest(url: url)
		urlRequest.httpMethod = HTTPMethod.get.rawValue
		
		request(urlRequest)
			.validate(statusCode: 200..<300)
			.responseData { response in
				switch response.result {
				case .success(let data):
					let decodedData = try? JSONDecoder().decode(UploadedFileInfo.self, from: data)
		
					guard let fileInfo = decodedData else {
						completionHandler(nil, Error.defaultError())
						return
					}

					completionHandler(fileInfo, nil)
				case .failure(_):
					let error = self.makeError(fromResponse: response)
					completionHandler(nil, error)
				}
		}
	}
	
	/// Direct upload from url
	/// - Parameters:
	///   - task: upload settings
	///   - completionHandler: callback
	public func upload(
		task: UploadFromURLTask,
		_ completionHandler: @escaping (UploadFromURLResponse?, Error?) -> Void
	) {
		var urlString = uploadAPIBaseUrl + "/from_url?pub_key=\(self.publicKey)&source_url=\(task.sourceUrl.absoluteString)"
			
		urlString += "&store=\(task.store.rawValue)"
		
		if let filenameVal = task.filename {
			urlString += "&filename=\(filenameVal)"
		}
		if let checkURLDuplicatesVal = task.checkURLDuplicates {
			let val = checkURLDuplicatesVal == true ? "1" : "0"
			urlString += "&check_URL_duplicates=\(val)"
		}
		if let saveURLDuplicatesVal = task.saveURLDuplicates {
			let val = saveURLDuplicatesVal == true ? "1" : "0"
			urlString += "&save_URL_duplicates=\(val)"
		}
		if let signatureVal = task.signature {
			urlString += "&signature=\(signatureVal)"
		}
		if let expireVal = task.expire {
			urlString += "&expire=\(Int(expireVal))"
		}
		
		guard let url = URL(string: urlString) else {
			assertionFailure("Incorrect url")
			return
		}
		var urlRequest = URLRequest(url: url)
		urlRequest.httpMethod = HTTPMethod.post.rawValue
		urlRequest.addValue("application/json", forHTTPHeaderField: "Content-Type")
		
		request(urlRequest)
			.validate(statusCode: 200..<300)
			.responseData { response in
				switch response.result {
				case .success(let data):
					let decodedData = try? JSONDecoder().decode(UploadFromURLResponse.self, from: data)

					guard let responseData = decodedData else {
						completionHandler(nil, Error.defaultError())
						return
					}

					completionHandler(responseData, nil)
					break
				case .failure(_):
					let error = self.makeError(fromResponse: response)
					completionHandler(nil, error)
				}
		}
	}
	
	/// Get status for file upload from URL
	/// - Parameters:
	///   - token: token recieved from upload method
	///   - completionHandler: callback
	public func uploadStatus(
		forToken token: String,
		_ completionHandler: @escaping (UploadFromURLStatus?, Error?) -> Void
	) {
		let urlString = uploadAPIBaseUrl + "/from_url/status/?token=\(token)"
		guard let url = URL(string: urlString) else {
			assertionFailure("Incorrect url")
			return
		}
		var urlRequest = URLRequest(url: url)
		urlRequest.httpMethod = HTTPMethod.get.rawValue
		urlRequest.addValue("application/json", forHTTPHeaderField: "Content-Type")
		
		request(urlRequest)
			.validate(statusCode: 200..<300)
			.responseData { response in
				switch response.result {
				case .success(let data):
					let decodedData = try? JSONDecoder().decode(UploadFromURLStatus.self, from: data)

					guard let responseData = decodedData else {
						completionHandler(nil, Error.defaultError())
						return
					}

					completionHandler(responseData, nil)
					break
				case .failure(_):
					let error = self.makeError(fromResponse: response)
					completionHandler(nil, error)
				}
		}
	}
	
	public func upload(
		files: [String:Data],
		store: StoringBehavior? = nil,
		signature: String? = nil,
		expire: Int? = nil,
		_ completionHandler: @escaping ([String: String]?, Error?) -> Void
	) {
		let urlString = uploadAPIBaseUrl + "/base/"
		manager.upload(
			multipartFormData: { (multipartFormData) in
				if let publicKeyData = self.publicKey.data(using: .utf8) {
					multipartFormData.append(publicKeyData, withName: "UPLOADCARE_PUB_KEY")
				}
				
				for file in files {
					multipartFormData.append(file.value, withName: file.key, fileName: file.key, mimeType: mimeType(for: file.value))
				}
				
				if let storeVal = store, let data = storeVal.rawValue.data(using: .utf8) {
					multipartFormData.append(data, withName: "UPLOADCARE_STORE")
				}
				
				if let signatureVal = signature, let data = signatureVal.data(using: .utf8) {
					multipartFormData.append(data, withName: "signature")
				}
				if var expireVal = expire {
					let data = Data(bytes: &expireVal, count: MemoryLayout.size(ofValue: expireVal))
					multipartFormData.append(data, withName: "expire")
				}
		},
			to: urlString
		) { (result) in
			switch result {
			case .success(let upload, _, _):
				
//				upload.uploadProgress(closure: { (progress) in
//					DLog("Upload progress: \(progress.fractionCompleted)")
//				})
				
				upload.response { (response) in
					if response.response?.statusCode == 200, let data = response.data {
						let decodedData = try? JSONDecoder().decode([String:String].self, from: data)
						guard let resultData = decodedData else {
							completionHandler(nil, Error.defaultError())
							return
						}
						completionHandler(resultData, nil)
						return
					}
					
					// error happened
					let status: Int = response.response?.statusCode ?? 0
					var message = ""
					if let data = response.data {
						message = String(data: data, encoding: .utf8) ?? ""
					}
					let error = Error(status: status, message: message)
					completionHandler(nil, error)
				}

			case .failure(let encodingError):
				completionHandler(nil, Error(status: 0, message: encodingError.localizedDescription))
			}
		}
	}
}


// MARK: - Private methods
internal extension Uploadcare {
	/// Build url request for REST API
	/// - Parameter fromURL: request url
	func makeUrlRequest(fromURL url: URL, method: HTTPMethod) -> URLRequest {
		let dateString = GMTDate()
		
		var urlRequest = URLRequest(url: url)
		urlRequest.httpMethod = method.rawValue
		urlRequest.addValue("application/json", forHTTPHeaderField: "Content-Type")
		urlRequest.addValue("application/vnd.uploadcare-v0.6+json", forHTTPHeaderField: "Accept")
		urlRequest.addValue(dateString, forHTTPHeaderField: "Date")
		
		switch authScheme {
		case .simple:
			urlRequest.addValue("\(authScheme.rawValue) \(publicKey):\(secretKey)", forHTTPHeaderField: "Authorization")
		case .signed:
			// TODO: - implement
			break
		}
		
		return urlRequest
	}
}


// MARK: - REST API
extension Uploadcare {
	
	/// Get list of files
	/// - Parameters:
	///   - query: query object
	///   - completionHandler: callback
	public func listOfFiles(
		withQuery query: PaginationQuery?,
		_ completionHandler: @escaping (FilesListResponse?, RESTAPIError?) -> Void
	) {
		var urlString = RESTAPIBaseUrl + "/files/"
		if let queryValue = query {
			urlString += "?\(queryValue.stringValue)"
		}
		
		guard let url = URL(string: urlString) else {
			assertionFailure("Incorrect url")
			return
		}
		let urlRequest = makeUrlRequest(fromURL: url, method: .get)
		
		request(urlRequest)
			.validate(statusCode: 200..<300)
			.responseData { response in
				switch response.result {
				case .success(let data):
					let decodedData = try? JSONDecoder().decode(FilesListResponse.self, from: data)

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
	///   - completionHandler: callback
	public func fileInfo(
		withUUID uuid: String,
		_ completionHandler: @escaping (FileInfo?, RESTAPIError?) -> Void
	) {
		let urlString = RESTAPIBaseUrl + "/files/\(uuid)/"
		guard let url = URL(string: urlString) else {
			assertionFailure("Incorrect url")
			return
		}
		let urlRequest = makeUrlRequest(fromURL: url, method: .get)
		
		request(urlRequest)
			.validate(statusCode: 200..<300)
			.responseData { response in
				switch response.result {
				case .success(let data):
					
					let decodedData = try? JSONDecoder().decode(FileInfo.self, from: data)
					
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
	///   - completionHandler: callback
	public func deleteFile(
		withUUID uuid: String,
		_ completionHandler: @escaping (FileInfo?, RESTAPIError?) -> Void
	) {
		let urlString = RESTAPIBaseUrl + "/files/\(uuid)/"
		guard let url = URL(string: urlString) else {
			assertionFailure("Incorrect url")
			return
		}
		let urlRequest = makeUrlRequest(fromURL: url, method: .delete)
		
		request(urlRequest)
			.validate(statusCode: 200..<300)
			.responseData { response in
				switch response.result {
				case .success(let data):
					
					let decodedData = try? JSONDecoder().decode(FileInfo.self, from: data)
					
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
	///   - completionHandler: callback
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
		
		request(urlRequest)
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
	///   - completionHandler: callback
	public func storeFile(
		withUUID uuid: String,
		_ completionHandler: @escaping (FileInfo?, RESTAPIError?) -> Void
	) {
		let urlString = RESTAPIBaseUrl + "/files/\(uuid)/storage/"
		guard let url = URL(string: urlString) else {
			assertionFailure("Incorrect url")
			return
		}
		let urlRequest = makeUrlRequest(fromURL: url, method: .put)
		
		request(urlRequest)
			.validate(statusCode: 200..<300)
			.responseData { response in
				switch response.result {
				case .success(let data):
					
					let decodedData = try? JSONDecoder().decode(FileInfo.self, from: data)
					
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
	///   - completionHandler: callback
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
		
		request(urlRequest)
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
	///   - completionHandler: callback
	public func listOfGroups(
		withQuery query: GroupsListQuery?,
		_ completionHandler: @escaping (GroupsListResponse?, RESTAPIError?) -> Void
	) {
		var urlString = RESTAPIBaseUrl + "/groups/"
		if let queryValue = query {
			urlString += "?\(queryValue.stringValue)"
		}
		
		guard let url = URL(string: urlString) else {
			assertionFailure("Incorrect url")
			return
		}
		let urlRequest = makeUrlRequest(fromURL: url, method: .get)
		
		request(urlRequest)
			.validate(statusCode: 200..<300)
			.responseData { response in
				switch response.result {
				case .success(let data):
					let decodedData = try? JSONDecoder().decode(GroupsListResponse.self, from: data)
					
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
	///   - completionHandler: callback
	public func groupInfo(
		withUUID uuid: String,
		_ completionHandler: @escaping (Group?, RESTAPIError?) -> Void
	) {
		let urlString = RESTAPIBaseUrl + "/groups/\(uuid)/"
		guard let url = URL(string: urlString) else {
			assertionFailure("Incorrect url")
			return
		}
		let urlRequest = makeUrlRequest(fromURL: url, method: .get)
		
		request(urlRequest)
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
	///   - completionHandler: callback
	public func storeGroup(
		withUUID uuid: String,
		_ completionHandler: @escaping (RESTAPIError?) -> Void
	) {
		let urlString = RESTAPIBaseUrl + "/groups/\(uuid)/storage/"
		guard let url = URL(string: urlString) else {
			assertionFailure("Incorrect url")
			return
		}
		let urlRequest = makeUrlRequest(fromURL: url, method: .put)
		
		request(urlRequest)
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
	///   - completionHandler: <#completionHandler description#>
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
		
		request(urlRequest)
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
}
