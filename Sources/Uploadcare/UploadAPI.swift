//
//  UploadAPI.swift
//  
//
//  Created by Sergey Armodin on 13.02.2020.
//  Copyright © 2020 Uploadcare, Inc. All rights reserved.
//

import Foundation

public typealias TaskCompletionHandler = ([String: String]?, UploadError?) -> Void
public typealias TaskResultCompletionHandler = (Result<[String: String], UploadError>) -> Void
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
	
	/// Upload queue for multipart uploading
	private var uploadQueue = DispatchQueue(label: "com.uploadcare.upload", qos: .utility, attributes: .concurrent)
	
	/// Performs network requests
	private let requestManager: RequestManager

    /// URL session
	private lazy var foregroundUploadURLSession: URLSession = {
		let config = URLSessionConfiguration.default
		return URLSession(configuration: config, delegate: self, delegateQueue: nil)
	}()
	
	
	/// Initialization
	/// - Parameter publicKey: Public Key.  It is required when using Upload API.
	/// - Parameter secretKey: Secret Key
	public init(withPublicKey publicKey: String, secretKey: String? = nil) {
		self.publicKey = publicKey
		self.secretKey = secretKey

		self.requestManager = RequestManager(publicKey: publicKey, secretKey: secretKey)

		super.init()

		BackgroundSessionManager.instance.sessionDelegate = self
	}

	/// Init with request manager
	/// - Parameters:
	///   - publicKey: Public Key.  It is required when using Upload API.
	///   - secretKey: Secret Key
	///   - requestManager: requests manager
	internal init(withPublicKey publicKey: String, secretKey: String? = nil, requestManager: RequestManager? = nil) {
		self.publicKey = publicKey
		self.secretKey = secretKey

		self.requestManager = requestManager ?? RequestManager(publicKey: publicKey, secretKey: secretKey)

		super.init()

		BackgroundSessionManager.instance.sessionDelegate = self
	}
}


// MARK: - Private methods
private extension UploadAPI {
	/// /// Build url request for Upload API
	/// - Parameter fromURL: request url
	func makeUploadAPIURLRequest(fromURL url: URL, method: RequestManager.HTTPMethod) -> URLRequest {
		var urlRequest = URLRequest(url: url)
		urlRequest.httpMethod = method.rawValue
		urlRequest.addValue("application/json", forHTTPHeaderField: "Content-Type")
		return urlRequest
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

	/// Make URL with path
	/// - Parameter path: path string
	/// - Returns: URL
	func urlWithPath(_ path: String) -> URL {
		var urlComponents = URLComponents()
		urlComponents.scheme = "https"
		urlComponents.host = uploadAPIHost
		urlComponents.path = path
		
		guard let url = urlComponents.url else {
			fatalError("incorrect url")
		}
		return url
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
		_ completionHandler: @escaping (Result<UploadedFile, UploadError>) -> Void
	) {
		var components = URLComponents()
		components.scheme = "https"
		components.host = uploadAPIHost
		components.path = "/info"
		components.queryItems = [
			URLQueryItem(name: "pub_key", value: publicKey),
			URLQueryItem(name: "file_id", value: fileId)
		]

		guard let url = components.url else {
			assertionFailure("Incorrect url")
			return
		}
		let urlRequest = makeUploadAPIURLRequest(fromURL: url, method: .get)

		requestManager.performRequest(urlRequest) { (result: Result<UploadedFile, Error>) in
			switch result {
			case .failure(let error): completionHandler(.failure(UploadError.fromError(error)))
			case .success(let file): completionHandler(.success(file))
			}
		}
	}
}

// MARK: - Upload from URL
extension UploadAPI {
	/// Upload file from url
	/// - Parameters:
	///   - task: upload settings
	///   - uploadSignature: Sets the signature for the upload request
	///   - completionHandler: callback
	public func upload(
		task: UploadFromURLTask,
		uploadSignature: UploadSignature? = nil,
		_ completionHandler: @escaping (Result<UploadFromURLResponse, UploadError>) -> Void
	) {
		var components = URLComponents()
		components.scheme = "https"
		components.host = uploadAPIHost
		components.path = "/from_url"

		var queryItems = [
			URLQueryItem(name: "pub_key", value: publicKey),
			URLQueryItem(name: "source_url", value: task.sourceUrl.absoluteString),
			URLQueryItem(name: "store", value: task.store.rawValue)
		]

		if let filenameVal = task.filename {
			let name = filenameVal.isEmpty ? "noname.ext" : filenameVal
			queryItems.append(
				URLQueryItem(name: "filename", value: name)
			)
		}
		if let checkURLDuplicatesVal = task.checkURLDuplicates {
			let val = checkURLDuplicatesVal == true ? "1" : "0"
			queryItems.append(
				URLQueryItem(name: "check_URL_duplicates", value: val)
			)
		}
		if let saveURLDuplicatesVal = task.saveURLDuplicates {
			let val = saveURLDuplicatesVal == true ? "1" : "0"
			queryItems.append(
				URLQueryItem(name: "save_URL_duplicates", value: val)
			)
		}

		if let metadata = task.metadata {
			for meta in metadata {
				queryItems.append(
					URLQueryItem(name: "metadata[\(meta.key)]", value: meta.value)
				)
			}
		}

		if let uploadSignature = uploadSignature ?? getSignature() {
			queryItems.append(contentsOf: [
				URLQueryItem(name: "signature", value: uploadSignature.signature),
				URLQueryItem(name: "expire", value: "\(uploadSignature.expire)")
			])
		}

		components.queryItems = queryItems
		guard let url = components.url else {
			assertionFailure("Incorrect url")
			return
		}
		let urlRequest = makeUploadAPIURLRequest(fromURL: url, method: .post)

		requestManager.performRequest(urlRequest) { (result: Result<UploadFromURLResponse, Error>) in
			switch result {
			case .failure(let error): completionHandler(.failure(UploadError.fromError(error)))
			case .success(let responseData): completionHandler(.success(responseData))
			}
		}
	}

	/// Get status for file upload from URL
	/// - Parameters:
	///   - token: token recieved from upload method
	///   - completionHandler: callback
	public func uploadStatus(
		forToken token: String,
		_ completionHandler: @escaping (Result<UploadFromURLStatus, UploadError>) -> Void
	) {
        var components = URLComponents()
        components.scheme = "https"
        components.host = uploadAPIHost
        components.path = "/from_url/status/"
        components.queryItems = [
            URLQueryItem(name: "token", value: token)
        ]

        guard let url = components.url else {
            assertionFailure("Incorrect url")
            return
        }

		let urlRequest = makeUploadAPIURLRequest(fromURL: url, method: .get)

        requestManager.performRequest(urlRequest) { (result: Result<UploadFromURLStatus, Error>) in
            switch result {
			case .failure(let error): completionHandler(.failure(UploadError.fromError(error)))
			case .success(let status): completionHandler(.success(status))
            }
        }
	}
}

// MARK: - Direct upload
extension UploadAPI {
	enum DirectUploadType {
		case foreground, background
	}

	/// Direct upload comply with the RFC 7578 standard and work by making POST requests via HTTPS.
	/// This method uploads data using background URLSession. Uploading will continue even if your app will be closed
	/// - Parameters:
	///   - files: Files dictionary where key is filename, value file in Data format
	///   - store: Sets the file storing behavior
	///   - uploadSignature: Sets the signature for the upload request
	///   - completionHandler: callback
	@discardableResult
	public func directUpload(
		files: [String: Data],
		store: StoringBehavior? = nil,
		uploadSignature: UploadSignature? = nil,
		_ onProgress: TaskProgressBlock? = nil,
		_ completionHandler: @escaping TaskResultCompletionHandler
	) -> UploadTaskable {
		return directUpload(files: files, uploadType: .background, store: store, uploadSignature: uploadSignature, onProgress, completionHandler)
	}

    @discardableResult
    internal func directUpload(
		files: [String: Data],
		uploadType: DirectUploadType,
		store: StoringBehavior? = nil,
		uploadSignature: UploadSignature? = nil,
		_ onProgress: TaskProgressBlock? = nil,
		_ completionHandler: @escaping TaskResultCompletionHandler
	) -> UploadTaskable {
        let url = urlWithPath("/base/")
        var urlRequest = makeUploadAPIURLRequest(fromURL: url, method: .post)

        // Making request body
        let builder = MultipartRequestBuilder(request: urlRequest)
        builder.addMultiformValue(publicKey, forName: "UPLOADCARE_PUB_KEY")

        if let storeVal = store {
            builder.addMultiformValue(storeVal.rawValue, forName: "UPLOADCARE_STORE")
        }

		if let uploadSignature = uploadSignature ?? getSignature() {
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

        let uploadTask: URLSessionUploadTask

        switch uploadType {
        case .foreground:
            uploadTask = foregroundUploadURLSession.uploadTask(with: urlRequest, fromFile: localURL) { data, response, error in
                if (response as? HTTPURLResponse)?.statusCode == 200, let data = data {
                    let decodedData = try? JSONDecoder().decode([String:String].self, from: data)
                    guard let resultData = decodedData else {
						completionHandler(.failure(UploadError.defaultError()))
                        return
                    }
					completionHandler(.success(resultData))
                    return
                }

                // error happened
                let status: Int = (response as? HTTPURLResponse)?.statusCode ?? 0
                let defaultErrorMessage = "Error happened or upload was cancelled"
                var message = defaultErrorMessage
                if let data = data {
                    message = String(data: data, encoding: .utf8) ?? defaultErrorMessage
                }
                let error = UploadError(status: status, detail: message)
				completionHandler(.failure(error))
            }
        case .background:
            uploadTask = BackgroundSessionManager.instance.session.uploadTask(with: urlRequest, fromFile: localURL)
        }

        uploadTask.earliestBeginDate = Date()
        uploadTask.countOfBytesClientExpectsToSend = Int64(urlRequest.httpBody?.count ?? 0)

		let backgroundUploadTask = UploadTask(task: uploadTask, completionHandler: completionHandler, progressCallback: onProgress)
        backgroundUploadTask.localDataUrl = localURL
        BackgroundSessionManager.instance.backgroundTasks[uploadTask.taskIdentifier] = backgroundUploadTask

        uploadTask.resume()
        return backgroundUploadTask
    }
	
	/// Direct upload comply with the RFC 7578 standard and work by making POST requests via HTTPS.
	/// - Parameters:
	///   - files: Files dictionary where key is filename, value file in Data format
	///   - store: Sets the file storing behavior
	///   - completionHandler: callback
	@discardableResult
	internal func directUploadInForeground(
		files: [String: Data],
		store: StoringBehavior? = nil,
		_ onProgress: ((Double) -> Void)? = nil,
		_ completionHandler: @escaping TaskResultCompletionHandler
	) -> UploadTaskable {
		return directUpload(files: files, uploadType: .foreground, onProgress, completionHandler)
	}
}

// MARK: - Multipart uploading
extension UploadAPI {
	@discardableResult
	/// Multipart file uploading
	/// - Parameters:
	///   - data: File data
	///   - name: File name
	///   - store: Sets the file storing behavior
	///   - uploadSignature: Sets the signature for the upload request
	///   - onProgress: A callback that will be used to report upload progress
	///   - completionHandler: Completion handler
	/// - Returns: Upload task. You can use that task to pause, resume or cancel uploading.
	public func multipartUpload(
		_ data: Data,
		withName name: String,
		store: StoringBehavior? = nil,
		uploadSignature: UploadSignature? = nil,
		_ onProgress: TaskProgressBlock? = nil,
		_ completionHandler: @escaping (Result<UploadedFile, UploadError>) -> Void
	) -> UploadTaskResumable {
		let totalSize = data.count
		let fileMimeType = detectMimeType(for: data)
		let filename = name.isEmpty ? "noname.ext" : name
		
		let task = MultipartUploadTask()
		task.queue = self.uploadQueue

		// Starting a multipart upload transaction
		startMulipartUpload(
			withName: filename,
			size: totalSize,
			mimeType: fileMimeType,
			store: store ?? .store,
			uploadSignature: uploadSignature) { [weak self] result in
				guard let self = self else { return }

				switch result {
				case .failure(let error):
					completionHandler(.failure(error))
				case .success(let response):
					// Uploading individual file parts
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
							completionHandler(.failure(UploadError.defaultError()))
							return
						}
						let chunk = data.subdata(in: dataRange)

						// presigned upload url
						let partUrl = response.parts[i]

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

								let total = Double(response.parts.count)
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
							completionHandler(.failure(UploadError(status: 0, detail: "Upload cancelled")))
							return
						}
						task.complete()
						self.completeMultipartUpload(forFileUIID: response.uuid, completionHandler)
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
	///   - uploadSignature: Sets the signature for the upload request
	///   - completionHandler: callback
	private func startMulipartUpload(
		withName filename: String,
		size: Int,
		mimeType: String,
		store: StoringBehavior,
		uploadSignature: UploadSignature? = nil,
		_ completionHandler: @escaping (Result<StartMulipartUploadResponse, UploadError>) -> Void
	) {
		let url = urlWithPath("/multipart/start/")
		var urlRequest = makeUploadAPIURLRequest(fromURL: url, method: .post)

		// Making request body
		let builder = MultipartRequestBuilder(request: urlRequest)
		builder.addMultiformValue(filename, forName: "filename")
		builder.addMultiformValue("\(size)", forName: "size")
		builder.addMultiformValue(mimeType, forName: "content_type")
		builder.addMultiformValue(publicKey, forName: "UPLOADCARE_PUB_KEY")
		builder.addMultiformValue(store.rawValue, forName: "UPLOADCARE_STORE")

		if let uploadSignature = uploadSignature ?? getSignature() {
			builder.addMultiformValue(uploadSignature.signature, forName: "signature")
			builder.addMultiformValue("\(uploadSignature.expire)", forName: "expire")
		}

		urlRequest = builder.finalize()

		requestManager.performRequest(urlRequest) { (result: Result<StartMulipartUploadResponse, Error>) in
			switch result {
			case .failure(let error): completionHandler(.failure(UploadError.fromError(error)))
			case .success(let responseData): completionHandler(.success(responseData))
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
		onComplete: (() -> Void)? = nil
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
            urlRequest.httpMethod = RequestManager.HTTPMethod.put.rawValue
			urlRequest.addValue(mimeType, forHTTPHeaderField: "Content-Type")
			urlRequest.httpBody = part

            let dataTask = URLSession.shared.dataTask(with: urlRequest) { [weak self] (data, response, error) in
                guard let self = self else { return }

                if let error = error {
                    DLog(error.localizedDescription)
                    return
                }

                guard let response = response as? HTTPURLResponse else {
                    assertionFailure("No response")
                    return
                }

                if response.statusCode == 200 {
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

                    // Print error
                    if let data = data {
                        let errorMessage = String(data: data, encoding: .utf8) ?? "Unknown error"
                        DLog("Error with status \(response.statusCode): \(errorMessage)")
                    }

                    self.uploadIndividualFilePart(part, toPresignedUrl: urlString, withMimeType: mimeType, task: task, group: group)
                }
            }

            task.appendRequest(dataTask)
            dataTask.resume()
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
		_ completionHandler: @escaping (Result<UploadedFile, UploadError>) -> Void
	) {
        let url = urlWithPath("/multipart/complete/")
        var urlRequest = makeUploadAPIURLRequest(fromURL: url, method: .post)

        // Making request body
        let builder = MultipartRequestBuilder(request: urlRequest)
        builder.addMultiformValue(forFileUIID, forName: "uuid")
        builder.addMultiformValue(publicKey, forName: "UPLOADCARE_PUB_KEY")

        urlRequest = builder.finalize()

        requestManager.performRequest(urlRequest) { (result: Result<UploadedFile, Error>) in
            switch result {
			case .failure(let error): completionHandler(.failure(UploadError.fromError(error)))
			case .success(let file): completionHandler(.success(file))
            }
        }
	}
}


// MARK: - Groups
extension UploadAPI {
	/// Create files group from a set of files
	/// - Parameters:
	///   - files: files array
	///   - uploadSignature: Sets the signature for the upload request
	///   - completionHandler: callback
	public func createFilesGroup(
		files: [UploadedFile],
		uploadSignature: UploadSignature? = nil,
		_ completionHandler: @escaping (Result<UploadedFilesGroup, UploadError>) -> Void
	) {
		let fileIds: [String] = files.map { $0.fileId }
		createFilesGroup(fileIds: fileIds, uploadSignature: uploadSignature, completionHandler)
	}

	/// Create files group from a set of files UUIDs.
	/// - Parameters:
	///   - fileIds: That parameter defines a set of files you want to join in a group. Each parameter can be a file UUID or a CDN URL, with or without applied Media Processing operations.
	///   - uploadSignature: Sets the signature for the upload request
	///   - completionHandler: callback
	public func createFilesGroup(
		fileIds: [String],
		uploadSignature: UploadSignature? = nil,
		_ completionHandler: @escaping (Result<UploadedFilesGroup, UploadError>) -> Void
	) {
        var urlComponents = URLComponents()
        urlComponents.scheme = "https"
        urlComponents.host = uploadAPIHost
        urlComponents.path = "/group/"
        urlComponents.queryItems = [
            URLQueryItem(name: "pub_key", value: publicKey)
        ]

        for (index, fileId) in fileIds.enumerated() {
            urlComponents.queryItems?.append(
                URLQueryItem(name: "files[\(index)]", value: fileId)
            )
        }

		if let uploadSignature = uploadSignature ?? getSignature() {
            urlComponents.queryItems?.append(contentsOf: [
                URLQueryItem(name: "signature", value: uploadSignature.signature),
                URLQueryItem(name: "expire", value: "\(uploadSignature.expire)")
            ])
        }

        guard let url = urlComponents.url else {
			assertionFailure("Incorrect url")
			return
		}
		let urlRequest = makeUploadAPIURLRequest(fromURL: url, method: .post)

        requestManager.performRequest(urlRequest) { (result: Result<UploadedFilesGroup, Error>) in
            switch result {
			case .failure(let error): completionHandler(.failure(UploadError.fromError(error)))
			case .success(let filesGroup): completionHandler(.success(filesGroup))
            }
        }
	}
	
	/// Files group info
	/// - Parameters:
	///   - groupId: Group ID. Group IDs look like UUID~N.
	///   - uploadSignature: Sets the signature for the upload request
	///   - completionHandler: callback
	public func filesGroupInfo(
		groupId: String,
		uploadSignature: UploadSignature? = nil,
		_ completionHandler: @escaping (Result<UploadedFilesGroup, UploadError>) -> Void
	) {
        var urlComponents = URLComponents()
        urlComponents.scheme = "https"
        urlComponents.host = uploadAPIHost
        urlComponents.path = "/group/info/"
        urlComponents.queryItems = [
            URLQueryItem(name: "pub_key", value: publicKey),
            URLQueryItem(name: "group_id", value: groupId)
        ]
		
		if let uploadSignature = uploadSignature ?? getSignature() {
            urlComponents.queryItems?.append(contentsOf: [
                URLQueryItem(name: "signature", value: uploadSignature.signature),
                URLQueryItem(name: "expire", value: "\(uploadSignature.expire)")
            ])
        }
		
        guard let url = urlComponents.url else {
			assertionFailure("Incorrect url")
			return
		}
		let urlRequest = makeUploadAPIURLRequest(fromURL: url, method: .get)

        requestManager.performRequest(urlRequest) { (result: Result<UploadedFilesGroup, Error>) in
            switch result {
			case .failure(let error): completionHandler(.failure(UploadError.fromError(error)))
			case .success(let filesGroup): completionHandler(.success(filesGroup))
            }
        }
	}
}

// MARK: - URLSessionTaskDelegate
extension UploadAPI: URLSessionDataDelegate {
	public func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive response: URLResponse, completionHandler: @escaping (URLSession.ResponseDisposition) -> Void) {
        completionHandler(.allow)

		// without adding this method background task will not trigger urlSession(_:dataTask:didReceive:completionHandler:)
//		if ProcessInfo.processInfo.environment["XCTestConfigurationFilePath"] != nil {
//			guard let backgroundTask = BackgroundSessionManager.instance.backgroundTasks[dataTask.taskIdentifier] else { return }
//
//			// remove task
//			defer {
//				backgroundTask.clear()
//				BackgroundSessionManager.instance.backgroundTasks.removeValue(forKey: dataTask.taskIdentifier)
//			}
//
//			let statusCode: Int = (dataTask.response as? HTTPURLResponse)?.statusCode ?? 0
//
//			if statusCode == 200 {
//				backgroundTask.completionHandler([String:String](), nil)
//			}
//		}
	}
}

// MARK: - URLSessionTaskDelegate
extension UploadAPI: URLSessionTaskDelegate {
	public func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
		guard let backgroundTask = BackgroundSessionManager.instance.backgroundTasks[task.taskIdentifier] else { return }
		
		// remove task
		defer {
			backgroundTask.clear()
			BackgroundSessionManager.instance.backgroundTasks.removeValue(forKey: task.taskIdentifier)
		}
		
		let statusCode: Int = (task.response as? HTTPURLResponse)?.statusCode ?? 0
		
		if statusCode == 200 {
			let decodedData = try? JSONDecoder().decode([String:String].self, from: backgroundTask.dataBuffer)
			guard let resultData = decodedData else {
				backgroundTask.completionHandler(.failure(UploadError.defaultError()))
				return
			}
			backgroundTask.completionHandler(.success(resultData))
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
		backgroundTask.completionHandler(.failure(error))
	}
	
	public func urlSession(_ session: URLSession, task: URLSessionTask, didSendBodyData bytesSent: Int64, totalBytesSent: Int64, totalBytesExpectedToSend: Int64) {
		// run progress callback
		if let backgroundTask = BackgroundSessionManager.instance.backgroundTasks[task.taskIdentifier] {
			var progress: Double = Double(totalBytesSent) / Double(totalBytesExpectedToSend)
			progress = Double(round(100 * progress) / 100)
			backgroundTask.progressCallback?(progress)
		}
	}
	
	public func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive data: Data) {
		if let backgroundTask = BackgroundSessionManager.instance.backgroundTasks[dataTask.taskIdentifier] {
			backgroundTask.dataBuffer.append(data)
		}
	}
}
