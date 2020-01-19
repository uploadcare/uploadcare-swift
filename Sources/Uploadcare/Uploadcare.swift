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
}


//public protocol Uploadable {
//	func directUpload()
//}


//extension Uploadcare: Uploadable {
//	func directUpload()
//}
