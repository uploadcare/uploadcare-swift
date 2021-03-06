//
//  UploadAPI.swift
//  
//
//  Created by Sergey Armodin on 13.02.2020.
//  Copyright © 2020 Uploadcare, Inc. All rights reserved.
//

import Foundation
import Alamofire

public typealias TaskCompletionHandler = ([String: String]?, UploadError?) -> Void
public typealias TaskProgressBlock = (Double) -> Void

public class UploadAPI: NSObject {
    // MARK: - Public properties
    /// Minimum file size for multipart uploads
    public static let multipartMinFileSize = 10485760
    
	/// Each uploaded part should be 5MB
	static let uploadChunkSize = 5242880
	
	/// Public Key.  It is required when using Upload API.
	internal var publicKey: String
	
	/// Secret Key. Is used for authorization
	internal var secretKey: String?
	
	/// Signature
	internal var signature: UploadSignature?
	
	/// Alamofire session manager
	private var manager: Session
	
	/// Upload queue for multipart uploading
	private var uploadQueue = DispatchQueue(label: "com.uploadcare.upload", qos: .utility, attributes: .concurrent)
	
	/// Running background tasks where key is URLSessionTask.taskIdentifier
	private var backgroundTasks = [Int: BackgroundUploadTask]()
	
	
	/// Initialization
	/// - Parameter publicKey: Public Key.  It is required when using Upload API.
	public init(withPublicKey publicKey: String, secretKey: String? = nil, manager: Session) {
		self.publicKey = publicKey
		self.secretKey = secretKey
		self.manager = manager
		
		super.init()
		
		BackgroundSessionManager.instance.sessionDelegate = self
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
	func makeUploadError(fromResponse response: DataResponse<Data, AFError>) -> UploadError {
		let status: Int = response.response?.statusCode ?? 0
		
		var message = ""
		if let data = response.data {
			message = String(data: data, encoding: .utf8) ?? ""
		}
		
		return UploadError(status: status, detail: message)
	}
	
	/// Generate signature for signed requests
	func generateSignature() {
		guard let secretKey = self.secretKey else { return }
		
		let expire = Int(Date().timeIntervalSince1970 + Double(60*30))
		let expireString = String(expire)
		
		self.signature = UploadSignature(signature: expireString.sha256(key: secretKey), expire: expire)
	}
	
	/// Get current signature for signed requests. Generates new one if signature is expired
	/// - Returns: signature
	func getSignature() -> UploadSignature? {
		guard self.secretKey != nil else { return nil }
		
		// check if signature expired
		if let signature = self.signature, signature.expire < Int(Date().timeIntervalSince1970) {
			generateSignature()
		}
		
		// generate signature if need
		if self.signature == nil {
			generateSignature()
		}
		
		return self.signature
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
		
		manager.request(urlRequest)
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
			let name = filenameVal.isEmpty ? "noname.ext" : filenameVal
			urlString += "&filename=\(name)"
		}
		if let checkURLDuplicatesVal = task.checkURLDuplicates {
			let val = checkURLDuplicatesVal == true ? "1" : "0"
			urlString += "&check_URL_duplicates=\(val)"
		}
		if let saveURLDuplicatesVal = task.saveURLDuplicates {
			let val = saveURLDuplicatesVal == true ? "1" : "0"
			urlString += "&save_URL_duplicates=\(val)"
		}
		
		if let uploadSignature = getSignature() {
			urlString += "&signature=\(uploadSignature.signature)"
			urlString += "&expire=\(uploadSignature.expire)"
		}
		
		guard let url = URL(string: urlString) else {
			assertionFailure("Incorrect url")
			return
		}
		let urlRequest = makeUploadAPIURLRequest(fromURL: url, method: .post)
		
		manager.request(urlRequest)
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
		
		manager.request(urlRequest)
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
	
	/// Direct upload comply with the RFC 7578 standard and work by making POST requests via HTTPS.
	/// This method uploads data using background URLSession. Uploading will continue even if your app will be closed
	/// - Parameters:
	///   - files: Files dictionary where key is filename, value file in Data format
	///   - store: Sets the file storing behavior
	///   - completionHandler: callback
	@discardableResult
	public func upload(
		files: [String:Data],
		store: StoringBehavior? = nil,
		_ onProgress: TaskProgressBlock? = nil,
		_ completionHandler: @escaping TaskCompletionHandler
	) -> UploadTaskable {
		let urlString = uploadAPIBaseUrl + "/base/"
		let url = URL(string: urlString)
		var urlRequest = makeUploadAPIURLRequest(fromURL: url!, method: .post)
		
		// Making request body
		let builder = MultipartRequestBuilder(request: urlRequest)
		builder.addMultiformValue(publicKey, forName: "UPLOADCARE_PUB_KEY")
		
		if let storeVal = store {
			builder.addMultiformValue(storeVal.rawValue, forName: "UPLOADCARE_STORE")
		}
		
		if let uploadSignature = getSignature() {
			builder.addMultiformValue(uploadSignature.signature, forName: "signature")
			builder.addMultiformValue("\(uploadSignature.expire)", forName: "expire")
		}
		
		for file in files {
			let fileName = file.key.isEmpty ? "noname.ext" : file.key
			builder.addMultiformData(file.value, forName: fileName)
		}
		
		urlRequest = builder.finalize()
		
		// writing data to temp file
		let tempDir = FileManager.default.temporaryDirectory
		let localURL = tempDir.appendingPathComponent(UUID().uuidString)
		
		if let data = urlRequest.httpBody {
			try? data.write(to: localURL)
		}
		let backgroundTask = BackgroundSessionManager.instance.session.uploadTask(with: urlRequest, fromFile: localURL)
		backgroundTask.earliestBeginDate = Date()
		backgroundTask.countOfBytesClientExpectsToSend = Int64(urlRequest.httpBody?.count ?? 0)
		
		let backgroundUploadTask = BackgroundUploadTask(task: backgroundTask, completionHandler: completionHandler, progressCallback: onProgress)
		backgroundUploadTask.localDataUrl = localURL
		backgroundTasks[backgroundTask.taskIdentifier] = backgroundUploadTask
		
		backgroundTask.resume()
		return backgroundUploadTask
	}
	
	/// Direct upload comply with the RFC 7578 standard and work by making POST requests via HTTPS.
	/// - Parameters:
	///   - files: Files dictionary where key is filename, value file in Data format
	///   - store: Sets the file storing behavior
	///   - completionHandler: callback
	@discardableResult
	func uploadInForeground(
		files: [String:Data],
		store: StoringBehavior? = nil,
		_ onProgress: ((Double) -> Void)? = nil,
		_ completionHandler: @escaping ([String: String]?, UploadError?) -> Void
	) -> UploadTaskable {
		let urlString = uploadAPIBaseUrl + "/base/"
		let request = manager.upload(
			multipartFormData: { [weak self] (multipartFormData) in
				if let publicKeyData = self?.publicKey.data(using: .utf8) {
					multipartFormData.append(publicKeyData, withName: "UPLOADCARE_PUB_KEY")
				}
				
				for file in files {
					let fileName = file.key.isEmpty ? "noname.ext" : file.key
					multipartFormData.append(file.value, withName: fileName, fileName: fileName, mimeType: detectMimeType(for: file.value))
				}
				
				if let storeVal = store, let data = storeVal.rawValue.data(using: .utf8) {
					multipartFormData.append(data, withName: "UPLOADCARE_STORE")
				}
				
				if let uploadSignature = self?.getSignature() {
					if let signatureData = uploadSignature.signature.data(using: .utf8) {
						multipartFormData.append(signatureData, withName: "signature")
					}
					
					if let expireData = String(uploadSignature.expire).data(using: .utf8) {
						multipartFormData.append(expireData, withName: "expire")
					}
				}
		},
			to: urlString)
			.uploadProgress(closure: { (progress) in
				onProgress?(progress.fractionCompleted)
			})
			.responseData { (response) in
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
				let defaultErrorMessage = "Error happened or upload was cancelled"
				var message = defaultErrorMessage
				if let data = response.data {
					message = String(data: data, encoding: .utf8) ?? defaultErrorMessage
				}
				let error = UploadError(status: status, detail: message)
				completionHandler(nil, error)
		}
		
		return UploadTask(request: request)
	}
	
	/// Multipart file uploading
	/// - Parameters:
	///   - data: Data
	///   - filename: File name
	///   - store: Sets the file storing behavior
	///   - completionHandler: completion handler
	@discardableResult
	public func uploadFile(
		_ data: Data,
		withName name: String,
		store: StoringBehavior? = nil,
		_ onProgress: ((Double) -> Void)? = nil,
		_ completionHandler: @escaping (UploadedFile?, UploadError?) -> Void
	) -> UploadTaskResumable {
		let totalSize = data.count
		let fileMimeType = detectMimeType(for: data)
	
		let task = MultipartUploadTask()
		task.queue = self.uploadQueue
		let filename = name.isEmpty ? "noname.ext" : name
		
		// Starting a multipart upload transaction
		startMulipartUpload(
			withName: filename,
			size: totalSize,
			mimeType: fileMimeType) { [weak self] (response, error) in
				guard let self = self else { return }
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
				var numberOfUploadedChunks = 0
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
						task: task,
						group: uploadGroup,
						completeMessage: nil, //"Uploaded \(i) of \(parts.count)",
						onComplete: {
							numberOfUploadedChunks += 1
							
							let total = Double(parts.count)
							let ready = Double(numberOfUploadedChunks)
							let percent = round(ready * 100 / total)
							onProgress?(percent / 100)
					})
					
					offset += currentChunkSize
					i += 1
				}
				
				// Completing a multipart upload
				uploadGroup.notify(queue: self.uploadQueue) {
					guard task.isCancelled == false else {
						completionHandler(nil, UploadError(status: 0, detail: "Upload cancelled"))
						return
					}
					task.complete()
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
		
		return task
	}
		
	/// Start multipart upload. Multipart Uploads are useful when you are dealing with files larger than 100MB or explicitly want to use accelerated uploads.
	/// - Parameters:
	///   - filename: An original filename
	///   - size: Precise file size in bytes. Should not exceed your project file size cap.
	///   - mimeType: A file MIME-type.
	///   - store: Sets the file storing behavior.
	///   - completionHandler: callback
	private func startMulipartUpload(
		withName filename: String,
		size: Int,
		mimeType: String,
        store: StoringBehavior = .store,
		_ completionHandler: @escaping (StartMulipartUploadResponse?, UploadError?) -> Void
	) {
		let urlString = uploadAPIBaseUrl + "/multipart/start/"
		manager.upload(
			multipartFormData: { [weak self] (multipartFormData) in
				if let filenameData = filename.data(using: .utf8) {
					multipartFormData.append(filenameData, withName: "filename")
				}

				if let sizeData = "\(size)".data(using: .utf8) {
					multipartFormData.append(sizeData, withName: "size")
				}
				
				if let contentTypeData = mimeType.data(using: .utf8) {
					multipartFormData.append(contentTypeData, withName: "content_type")
				}
				
				if let publicKeyData = self?.publicKey.data(using: .utf8) {
					multipartFormData.append(publicKeyData, withName: "UPLOADCARE_PUB_KEY")
				}
				
				if let data = store.rawValue.data(using: .utf8) {
					multipartFormData.append(data, withName: "UPLOADCARE_STORE")
				}
				
                if let uploadSignature = self?.getSignature() {
					if let signatureData = uploadSignature.signature.data(using: .utf8) {
						multipartFormData.append(signatureData, withName: "signature")
					}

					if let expireData = String(uploadSignature.expire).data(using: .utf8) {
						multipartFormData.append(expireData, withName: "expire")
					}
				}
		},
			to: urlString)
			.validate(statusCode: 200..<300)
			.responseData { response in
				switch response.result {
				case .success(_):
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
					let error = UploadError(status: status, detail: message)
					completionHandler(nil, error)
				case .failure(let encodingError):
					completionHandler(nil, UploadError(status: 0, detail: encodingError.localizedDescription))
				}
		}
	}
	
	private func uploadIndividualFilePart(
		_ part: Data,
		toPresignedUrl urlString: String,
		withMimeType mimeType: String,
		task: MultipartUploadTask,
		group: DispatchGroup? = nil,
		completeMessage: String? = nil,
		onComplete: (()->Void)? = nil
	) {
		group?.enter()
		
		let workItem = DispatchWorkItem { [weak self, weak task] in
			guard let self = self, let task = task else { return }
			
			guard let url = URL(string: urlString) else {
				assertionFailure("Incorrect url")
				group?.leave()
				return
			}
			var urlRequest = URLRequest(url: url)
			urlRequest.httpMethod = HTTPMethod.put.rawValue
			urlRequest.addValue(mimeType, forHTTPHeaderField: "Content-Type")
			urlRequest.httpBody = part
			
			let request = self.manager.request(urlRequest)
				.responseData { response in
					if response.response?.statusCode == 200 {
						if let message = completeMessage {
							DLog(message)
						}
						onComplete?()
						group?.leave()
					} else {
						if task.isCancelled {
							group?.leave()
							return
						}
						let error = self.makeUploadError(fromResponse: response)
						DLog(error)
						self.uploadIndividualFilePart(part, toPresignedUrl: urlString, withMimeType: mimeType, task: task, group: group)
					}
			}
			task.appendRequest(request)
		}
		
		// using concurrent queue for parts uploading
		uploadQueue.async(execute: workItem)
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
			to: urlString)
			.validate(statusCode: 200..<300)
			.responseData { response in
				switch response.result {
				case .success(_):
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
					let error = UploadError(status: status, detail: message)
					completionHandler(nil, error)
					
				case .failure(let encodingError):
					completionHandler(
						nil,
						UploadError(status: 0, detail: encodingError.localizedDescription)
					)
				}
		}
	}
}


// MARK: - Groups
extension UploadAPI {
	/// Create files group from a set of files
	/// - Parameters:
	///   - files: files array
	///   - completionHandler: callback
	public func createFilesGroup(
		files: [UploadedFile],
		_ completionHandler: @escaping (UploadedFilesGroup?, UploadError?) -> Void
	) {
		let fileIds: [String] = files.map { $0.fileId }
		createFilesGroup(fileIds: fileIds, completionHandler)
	}
	
	/// Create files group from a set of files UUIDs.
	/// - Parameters:
	///   - fileIds: That parameter defines a set of files you want to join in a group. Each parameter can be a file UUID or a CDN URL, with or without applied Media Processing operations.
	///   - completionHandler: callback
	public func createFilesGroup(
		fileIds: [String],
		_ completionHandler: @escaping (UploadedFilesGroup?, UploadError?) -> Void
	) {
		var urlString = uploadAPIBaseUrl + "/group/?pub_key=\(self.publicKey)"
		for (index, fileId) in fileIds.enumerated() {
			urlString += "&files[\(index)]=\(fileId)"
		}

		if let uploadSignature = self.getSignature() {
			urlString += "&signature=\(uploadSignature.signature)"
			urlString += "&expire=\(uploadSignature.expire)"
		}
		
		guard let url = URL(string: urlString) else {
			assertionFailure("Incorrect url")
			return
		}
		let urlRequest = makeUploadAPIURLRequest(fromURL: url, method: .post)
		
		manager.request(urlRequest)
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
	///   - completionHandler: callback
	public func filesGroupInfo(
		groupId: String,
		_ completionHandler: @escaping (UploadedFilesGroup?, UploadError?) -> Void
	) {
		var urlString = uploadAPIBaseUrl + "/group/info/?pub_key=\(self.publicKey)&group_id=\(groupId)"
		
		if let uploadSignature = self.getSignature() {
			urlString += "&signature=\(uploadSignature.signature)"
			urlString += "&expire=\(uploadSignature.expire)"
		}
		
		guard let url = URL(string: urlString) else {
			assertionFailure("Incorrect url")
			return
		}
		let urlRequest = makeUploadAPIURLRequest(fromURL: url, method: .get)
		
		manager.request(urlRequest)
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
	/// Create group of uploaded files from array
	/// - Parameter files: files array
	public func group(ofFiles files: [UploadedFile]) -> UploadedFilesGroup {
		return UploadedFilesGroup(withFiles: files, uploadAPI: self)
	}
	
	/// Create file model for uploading from Data
	/// - Parameters:
	///   - data: data
	///   - fileName: file name
	public func file(fromData data: Data) -> UploadedFile {
		return UploadedFile(withData: data, uploadAPI: self)
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
		let file = UploadedFile(withData: data, uploadAPI: self)
		file.filename = url.lastPathComponent
		file.originalFilename = url.lastPathComponent
		return file
	}
}



// MARK: - URLSessionTaskDelegate
extension UploadAPI: URLSessionDataDelegate {
	public func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive response: URLResponse, completionHandler: @escaping (URLSession.ResponseDisposition) -> Void) {
		// without adding this method background task will not trigger urlSession(_:dataTask:didReceive:completionHandler:)
	}
}

// MARK: - URLSessionTaskDelegate
extension UploadAPI: URLSessionTaskDelegate {
	public func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
		guard let backgroundTask = backgroundTasks[task.taskIdentifier] else { return }
		
		// remove task
		defer {
			backgroundTask.clear()
			backgroundTasks.removeValue(forKey: task.taskIdentifier)
		}
		
		let statusCode: Int = (task.response as? HTTPURLResponse)?.statusCode ?? 0
		
		if statusCode == 200 {
			let decodedData = try? JSONDecoder().decode([String:String].self, from: backgroundTask.dataBuffer)
			guard let resultData = decodedData else {
				backgroundTask.completionHandler(nil, UploadError.defaultError())
				return
			}
			backgroundTask.completionHandler(resultData, nil)
			return
		}
		
		// error happened
		let defaultErrorMessage = "Error happened or upload was cancelled"
		var message = defaultErrorMessage
		if !backgroundTask.dataBuffer.isEmpty {
			message = String(data: backgroundTask.dataBuffer, encoding: .utf8) ?? defaultErrorMessage
		} else {
			message = error?.localizedDescription ?? defaultErrorMessage
		}
		let error = UploadError(status: statusCode, detail: message)
		backgroundTask.completionHandler(nil, error)
	}
	
	public func urlSession(_ session: URLSession, task: URLSessionTask, didSendBodyData bytesSent: Int64, totalBytesSent: Int64, totalBytesExpectedToSend: Int64) {
		// run progress callback
		if let backgroundTask = backgroundTasks[task.taskIdentifier] {
			var progress: Double = Double(totalBytesSent) / Double(totalBytesExpectedToSend)
			progress = Double(round(100*progress)/100)
			backgroundTask.progressCallback?(progress)
		}
	}
	
	public func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive data: Data) {
		if let backgroundTask = backgroundTasks[dataTask.taskIdentifier] {
			backgroundTask.dataBuffer.append(data)
		}
	}
}
