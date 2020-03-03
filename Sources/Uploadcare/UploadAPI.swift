//
//  File.swift
//  
//
//  Created by Sergei Armodin on 13.02.2020.
//

import Foundation
import Alamofire


public class UploadAPI {
	
	/// Each uploaded part should be 5MB
	static let uploadChunkSize = 5242880
	
	/// Public Key.  It is required when using Upload API.
	internal var publicKey: String
	
	/// Secret Key. Is used for authorization
	internal var secretKey: String?
	
	/// Alamofire session manager
	private var manager: SessionManager
	
	/// Upload queue for multipart uploading
	private var uploadQueue = DispatchQueue(label: "com.uploadcare.upload", qos: .utility, attributes: .concurrent)
	
	
	/// Initialization
	/// - Parameter publicKey: Public Key.  It is required when using Upload API.
	public init(withPublicKey publicKey: String, secretKey: String? = nil, manager: SessionManager) {
		self.publicKey = publicKey
		self.secretKey = secretKey
		self.manager = manager
	}
}


// MARK: - Private methods
private extension UploadAPI {
	/// /// Build url request for Upload API
	/// - Parameter fromURL: request url
	func makeUploadAPIURLRequest(fromURL url: URL, method: HTTPMethod) -> URLRequest {
		var urlRequest = URLRequest(url: url)
		urlRequest.httpMethod = method.rawValue
		urlRequest.addValue("application/json", forHTTPHeaderField: "Content-Type")
		return urlRequest
	}
	
	/// Make UploadError from data response
	/// - Parameter response: Data response
	func makeUploadError(fromResponse response: DataResponse<Data>) -> UploadError {
		let status: Int = response.response?.statusCode ?? 0
		
		var message = ""
		if let data = response.data {
			message = String(data: data, encoding: .utf8) ?? ""
		}
		
		return UploadError(status: status, message: message)
	}
}


// MARK: - File Info
extension UploadAPI {
	/// File info
	/// - Parameters:
	///   - fileId: File ID
	///   - completionHandler: completion handler
	public func fileInfo(
		withFileId fileId: String,
		_ completionHandler: @escaping (UploadedFile?, UploadError?) -> Void
	) {
		let urlString = uploadAPIBaseUrl + "/info?pub_key=\(self.publicKey)&file_id=\(fileId)"
		guard let url = URL(string: urlString) else {
			assertionFailure("Incorrect url")
			return
		}
		let urlRequest = makeUploadAPIURLRequest(fromURL: url, method: .get)
		
		request(urlRequest)
			.validate(statusCode: 200..<300)
			.responseData { response in
				switch response.result {
				case .success(let data):
					let decodedData = try? JSONDecoder().decode(UploadedFile.self, from: data)
		
					guard let fileInfo = decodedData else {
						completionHandler(nil, UploadError.defaultError())
						return
					}

					completionHandler(fileInfo, nil)
				case .failure(_):
					let error = self.makeUploadError(fromResponse: response)
					completionHandler(nil, error)
				}
		}
	}
}


// MARK: - Uploading
extension UploadAPI {
	/// Direct upload from url
	/// - Parameters:
	///   - task: upload settings
	///   - completionHandler: callback
	public func upload(
		task: UploadFromURLTask,
		_ completionHandler: @escaping (UploadFromURLResponse?, UploadError?) -> Void
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
		let urlRequest = makeUploadAPIURLRequest(fromURL: url, method: .post)
		
		request(urlRequest)
			.validate(statusCode: 200..<300)
			.responseData { response in
				switch response.result {
				case .success(let data):
					let decodedData = try? JSONDecoder().decode(UploadFromURLResponse.self, from: data)

					guard let responseData = decodedData else {
						completionHandler(nil, UploadError.defaultError())
						return
					}

					completionHandler(responseData, nil)
					break
				case .failure(_):
					let error = self.makeUploadError(fromResponse: response)
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
		_ completionHandler: @escaping (UploadFromURLStatus?, UploadError?) -> Void
	) {
		let urlString = uploadAPIBaseUrl + "/from_url/status/?token=\(token)"
		guard let url = URL(string: urlString) else {
			assertionFailure("Incorrect url")
			return
		}
		let urlRequest = makeUploadAPIURLRequest(fromURL: url, method: .get)
		
		request(urlRequest)
			.validate(statusCode: 200..<300)
			.responseData { response in
				switch response.result {
				case .success(let data):
					let decodedData = try? JSONDecoder().decode(UploadFromURLStatus.self, from: data)

					guard let responseData = decodedData else {
						completionHandler(nil, UploadError.defaultError())
						return
					}

					completionHandler(responseData, nil)
					break
				case .failure(_):
					let error = self.makeUploadError(fromResponse: response)
					completionHandler(nil, error)
				}
		}
	}
	
	// TODO: Signature
	/// Direct upload comply with the RFC 7578 standard and work by making POST requests via HTTPS.
	/// - Parameters:
	///   - files: Files dictionary where key is filename, value file in Data format
	///   - store: Sets the file storing behavior.
	///   - signature: signature
	///   - expire: signature expire
	///   - completionHandler: callback
	public func upload(
		files: [String:Data],
		store: StoringBehavior? = nil,
		signature: String? = nil,
		expire: Int? = nil,
		_ completionHandler: @escaping ([String: String]?, UploadError?) -> Void
	) {
		let urlString = uploadAPIBaseUrl + "/base/"
		manager.upload(
			multipartFormData: { (multipartFormData) in
				if let publicKeyData = self.publicKey.data(using: .utf8) {
					multipartFormData.append(publicKeyData, withName: "UPLOADCARE_PUB_KEY")
				}
				
				for file in files {
					multipartFormData.append(file.value, withName: file.key, fileName: file.key, mimeType: detectMimeType(for: file.value))
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
				
				upload.uploadProgress(closure: { (progress) in
					DLog("Upload progress: \(progress.fractionCompleted)")
				})
				
				upload.response { (response) in
					if response.response?.statusCode == 200, let data = response.data {
						let decodedData = try? JSONDecoder().decode([String:String].self, from: data)
						guard let resultData = decodedData else {
							completionHandler(nil, UploadError.defaultError())
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
					let error = UploadError(status: status, message: message)
					completionHandler(nil, error)
				}

			case .failure(let encodingError):
				completionHandler(nil, UploadError(status: 0, message: encodingError.localizedDescription))
			}
		}
	}
	
	public func uploadFile(
		_ data: Data,
		withName filename: String,
		store: StoringBehavior? = nil,
		_ completionHandler: @escaping (UploadedFile?, UploadError?) -> Void
	) {
		let totalSize = data.count
		let fileMimeType = detectMimeType(for: data)
		
		// Starting a multipart upload transaction
		startMulipartUpload(
			withName: filename,
			size: totalSize,
			mimeType: fileMimeType) { (response, error) in
				if let error = error {
					completionHandler(nil, error)
					return
				}
				
				// Uploading individual file parts
				guard let parts = response?.parts, let uuid = response?.uuid else {
					completionHandler(nil, UploadError.defaultError())
					return
				}
				
				var offset = 0
				var i = 0
				let uploadGroup = DispatchGroup()
				
				while offset < totalSize {
					let bytesLeft = totalSize - offset
					let currentChunkSize = bytesLeft > Self.uploadChunkSize ? Self.uploadChunkSize : bytesLeft

					// data chunk
					let range = NSRange(location: offset, length: currentChunkSize)
					guard let dataRange = Range(range) else {
						completionHandler(nil, UploadError.defaultError())
						return
					}
					let chunk = data.subdata(in: dataRange)

					// presigned upload url
					let partUrl = parts[i]
					
					// uploading individual part
					self.uploadIndividualFilePart(
						chunk,
						toPresignedUrl: partUrl,
						withMimeType: fileMimeType,
						group: uploadGroup,
						completeMessage: "Uploaded \(i) of \(parts.count)"
					)
					
					offset += currentChunkSize
					i += 1
				}
				
				// Completing a multipart upload
				uploadGroup.notify(queue: self.uploadQueue) {
					self.completeMultipartUpload(forFileUIID: uuid) { (file, error) in
						if let error = error {
							completionHandler(nil, error)
							return
						}
						guard let uploadedFile = file else {
							completionHandler(nil, UploadError.defaultError())
							return
						}
						completionHandler(uploadedFile, nil)
					}
				}
		}
	}
		
	/// Start multipart upload. Multipart Uploads are useful when you are dealing with files larger than 100MB or explicitly want to use accelerated uploads.
	/// - Parameters:
	///   - filename: An original filename
	///   - size: Precise file size in bytes. Should not exceed your project file size cap.
	///   - mimeType: A file MIME-type.
	///   - store: Sets the file storing behavior.
	///   - signature: signature
	///   - expire: expire sets the time until your signature is valid
	///   - completionHandler: callback
	private func startMulipartUpload(
		withName filename: String,
		size: Int,
		mimeType: String,
		store: StoringBehavior? = nil,
		signature: String? = nil,
		expire: Int? = nil,
		_ completionHandler: @escaping (StartMulipartUploadResponse?, UploadError?) -> Void
	) {
		let urlString = uploadAPIBaseUrl + "/multipart/start/"
		manager.upload(
			multipartFormData: { (multipartFormData) in
				if let filenameData = filename.data(using: .utf8) {
					multipartFormData.append(filenameData, withName: "filename")
				}

				if let sizeData = "\(size)".data(using: .utf8) {
					multipartFormData.append(sizeData, withName: "size")
				}
				
				if let contentTypeData = mimeType.data(using: .utf8) {
					multipartFormData.append(contentTypeData, withName: "content_type")
				}
				
				if let publicKeyData = self.publicKey.data(using: .utf8) {
					multipartFormData.append(publicKeyData, withName: "UPLOADCARE_PUB_KEY")
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
				upload.response { (response) in
					if response.response?.statusCode == 200, let data = response.data {
						let decodedData = try? JSONDecoder().decode(StartMulipartUploadResponse.self, from: data)
						guard let resultData = decodedData else {
							completionHandler(nil, UploadError.defaultError())
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
					let error = UploadError(status: status, message: message)
					completionHandler(nil, error)
				}
				
			case .failure(let encodingError):
				completionHandler(nil, UploadError(status: 0, message: encodingError.localizedDescription))
			}
		}
	}
	
	private func uploadIndividualFilePart(
		_ part: Data,
		toPresignedUrl urlString: String,
		withMimeType mimeType: String,
		group: DispatchGroup? = nil,
		completeMessage: String? = nil
	) {
		group?.enter()
		// using concurrent queue for parts uploading
		uploadQueue.async { [weak self] in
			guard let self = self else { return }
			
			guard let url = URL(string: urlString) else {
				assertionFailure("Incorrect url")
				group?.leave()
				return
			}
			var urlRequest = URLRequest(url: url)
			urlRequest.httpMethod = HTTPMethod.put.rawValue
			urlRequest.addValue(mimeType, forHTTPHeaderField: "Content-Type")
			urlRequest.httpBody = part
			
			request(urlRequest)
				.validate(statusCode: 200..<300)
				.responseData { response in
					switch response.result {
					case .success(_):
						if let message = completeMessage {
							DLog(message)
						}
						group?.leave()
					case .failure(_):
						let error = self.makeUploadError(fromResponse: response)
						DLog(error)
						self.uploadIndividualFilePart(part, toPresignedUrl: urlString, withMimeType: mimeType, group: group)
					}
			}
		}
	}
	
	/// Complete multipart upload transaction when all files parts are uploaded.
	/// - Parameters:
	///   - forFileUIID: Uploaded file UUID from multipart upload start response.
	///   - completionHandler: callback
	private func completeMultipartUpload(
		forFileUIID: String,
		_ completionHandler: @escaping (UploadedFile?, UploadError?) -> Void
	) {
		let urlString = uploadAPIBaseUrl + "/multipart/complete/"
		manager.upload(
			multipartFormData: { (multipartFormData) in
				if let forFileUIIDData = forFileUIID.data(using: .utf8) {
					multipartFormData.append(forFileUIIDData, withName: "uuid")
				}
				if let publicKeyData = self.publicKey.data(using: .utf8) {
					multipartFormData.append(publicKeyData, withName: "UPLOADCARE_PUB_KEY")
				}
		},
			to: urlString
		) { (result) in
			switch result {
			case .success(let upload, _, _):
				upload.response { (response) in
					if response.response?.statusCode == 200, let data = response.data {
						let decodedData = try? JSONDecoder().decode(UploadedFile.self, from: data)
						guard let resultData = decodedData else {
							completionHandler(nil, UploadError.defaultError())
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
					let error = UploadError(status: status, message: message)
					completionHandler(nil, error)
				}
				
			case .failure(let encodingError):
				completionHandler(nil, UploadError(status: 0, message: encodingError.localizedDescription))
			}
		}
	}
}


// MARK: - Groups
extension UploadAPI {
	// TODO: Signature
	/// Create files group from a set of files
	/// - Parameters:
	///   - files: files array
	///   - signature: signature
	///   - expire: expire
	///   - completionHandler: callback
	public func createFilesGroup(
		files: [UploadedFile],
		signature: String? = nil,
		expire: Int? = nil,
		_ completionHandler: @escaping (UploadedFilesGroup?, UploadError?) -> Void
	) {
		let fileIds: [String] = files.map { (file) -> String in
			return file.fileId
		}
		createFilesGroup(fileIds: fileIds, completionHandler)
	}
	
	/// Create files group from a set of files UUIDs.
	/// - Parameters:
	///   - fileIds: That parameter defines a set of files you want to join in a group. Each parameter can be a file UUID or a CDN URL, with or without applied Media Processing operations.
	///   - signature: signature
	///   - expire: expire
	///   - completionHandler: callback
	public func createFilesGroup(
		fileIds: [String],
		signature: String? = nil,
		expire: Int? = nil,
		_ completionHandler: @escaping (UploadedFilesGroup?, UploadError?) -> Void
	) {
		var urlString = uploadAPIBaseUrl + "/group/?pub_key=\(self.publicKey)"
		for (index, fileId) in fileIds.enumerated() {
			urlString += "&files[\(index)]=\(fileId)"
		}
		guard let url = URL(string: urlString) else {
			assertionFailure("Incorrect url")
			return
		}
		let urlRequest = makeUploadAPIURLRequest(fromURL: url, method: .post)
		
		request(urlRequest)
			.validate(statusCode: 200..<300)
			.responseData { response in
				switch response.result {
				case .success(let data):
					let decodedData = try? JSONDecoder().decode(UploadedFilesGroup.self, from: data)

					guard let responseData = decodedData else {
						completionHandler(nil, UploadError.defaultError())
						return
					}

					completionHandler(responseData, nil)
					break
				case .failure(_):
					let error = self.makeUploadError(fromResponse: response)
					completionHandler(nil, error)
				}
		}
	}
	
	/// Files group info
	/// - Parameters:
	///   - groupId: Group ID. Group IDs look like UUID~N.
	///   - signature: signature
	///   - expire: expire
	///   - completionHandler: callback
	public func filesGroupInfo(
		groupId: String,
		signature: String? = nil,
		expire: Int? = nil,
		_ completionHandler: @escaping (UploadedFilesGroup?, UploadError?) -> Void
	) {
		let urlString = uploadAPIBaseUrl + "/group/info/?pub_key=\(self.publicKey)&group_id=\(groupId)"
		guard let url = URL(string: urlString) else {
			assertionFailure("Incorrect url")
			return
		}
		let urlRequest = makeUploadAPIURLRequest(fromURL: url, method: .get)
		
		request(urlRequest)
			.validate(statusCode: 200..<300)
			.responseData { response in
				switch response.result {
				case .success(let data):
					let decodedData = try? JSONDecoder().decode(UploadedFilesGroup.self, from: data)

					guard let responseData = decodedData else {
						completionHandler(nil, UploadError.defaultError())
						return
					}

					completionHandler(responseData, nil)
					break
				case .failure(_):
					let error = self.makeUploadError(fromResponse: response)
					completionHandler(nil, error)
				}
		}
	}
}


// MARK: - Factory
extension UploadAPI {
	public func group(ofFiles files: [UploadedFile]) -> UploadedFilesGroup {
		return UploadedFilesGroup(withFiles: files, uploadAPI: self)
	}
	
	public func file(fromData data: Data, withName fileName: String) -> UploadedFile {
		return UploadedFile(withData: data, fileName: fileName, uploadAPI: self)
	}
}
