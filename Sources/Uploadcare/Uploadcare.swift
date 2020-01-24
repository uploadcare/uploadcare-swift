import Foundation
import Alamofire


/// Upload API base url
let uploadAPIBaseUrl: String = "https://upload.uploadcare.com"


public struct Uploadcare {
	
	/// Public Key.  It is required when using Upload API.
	internal var publicKey: String
	
	/// Alamofire session manager
	private var manager = SessionManager()
	
	
	/// Initialization
	/// - Parameter publicKey: Public Key.  It is required when using Upload API.
	public init(withPublicKey publicKey: String) {
		self.publicKey = publicKey
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


extension Uploadcare {
	
	/// File info
	/// - Parameters:
	///   - fileId: File ID
	///   - completionHandler: completion handler
	public func fileInfo(
		withFileId fileId: String,
		_ completionHandler: @escaping (FileInfo?, Error?) -> Void
	) {
		let urlString = uploadAPIBaseUrl + "/info?pub_key=\(self.publicKey)&file_id=\(fileId)"
		guard let url = URL(string: urlString) else { return }
		var urlRequest = URLRequest(url: url)
		urlRequest.httpMethod = HTTPMethod.get.rawValue
		
		request(urlRequest)
			.validate(statusCode: 200..<300)
			.responseData { response in
				switch response.result {
				case .success(let data):
					let decodedData = try? JSONDecoder().decode(FileInfo.self, from: data)
		
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
	
	public func upload(
		task: UploadFromURLTask,
		_ completionHandler: @escaping (UploadFromURLResponse?, Error?) -> Void
	) {
		var urlString = uploadAPIBaseUrl + "/from_url?pub_key=\(self.publicKey)&source_url=\(task.sourceUrl.absoluteString)"
		guard let url = URL(string: urlString) else { return }
		var urlRequest = URLRequest(url: url)
		urlRequest.httpMethod = HTTPMethod.post.rawValue
		urlRequest.addValue("application/json", forHTTPHeaderField: "Content-Type")
		
		if let storeVal = task.store {
			urlString += "&store=\(storeVal.rawValue)"
		}
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
}
