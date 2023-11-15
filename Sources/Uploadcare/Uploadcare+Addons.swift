//
//  Uploadcare+Addons.swift
//  
//
//  Created by Sergei Armodin on 16.11.2023.
//

import Foundation


// MARK: - AWS Rekognition
extension Uploadcare {
	#if !os(Linux)
	/// Execute AWS Rekognition.
	///
	/// Example:
	/// ```swift
	/// uploadcare.executeAWSRekognition(fileUUID: "fileUUID") { result in
	///     switch result {
	///     case .failure(let error):
	///         print(error)
	///     case .success(let response):
	///         print(response) // contains requestID
	///     }
	/// }
	/// ```
	///
	/// - Parameters:
	///   - fileUUID: Unique ID of the file to process.
	///   - completionHandler: Completion handler.
	public func executeAWSRekognition(fileUUID: String, _ completionHandler: @escaping (Result<ExecuteAddonResponse, RESTAPIError>) -> Void) {
		let url = urlWithPath("/addons/aws_rekognition_detect_labels/execute/")
		var urlRequest = requestManager.makeUrlRequest(fromURL: url, method: .post)

		let bodyDictionary = [
			"target": fileUUID
		]

		urlRequest.httpBody = try? JSONEncoder().encode(bodyDictionary)

		requestManager.signRequest(&urlRequest)

		requestManager.performRequest(urlRequest) { (result: Result<ExecuteAddonResponse, Error>) in
			switch result {
			case .failure(let error): completionHandler(.failure(RESTAPIError.fromError(error)))
			case .success(let response): completionHandler(.success(response))
			}
		}
	}
	#endif

	/// Execute AWS Rekognition.
	///
	/// Example:
	/// ```swift
	/// let response = try await uploadcare.executeAWSRekognition(fileUUID: "fileUUID")
	/// print(response)
	/// ```
	///
	/// - Parameter fileUUID: Unique ID of the file to process.
	/// - Returns: Execution response.
	@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
	public func executeAWSRekognition(fileUUID: String) async throws -> ExecuteAddonResponse {
		let url = urlWithPath("/addons/aws_rekognition_detect_labels/execute/")
		var urlRequest = requestManager.makeUrlRequest(fromURL: url, method: .post)

		let bodyDictionary = [
			"target": fileUUID
		]
		urlRequest.httpBody = try? JSONEncoder().encode(bodyDictionary)

		requestManager.signRequest(&urlRequest)

		do {
			let response: ExecuteAddonResponse = try await requestManager.performRequest(urlRequest)
			return response
		} catch {
			throw RESTAPIError.fromError(error)
		}
	}

	/// Execute AWS Rekognition and wait for execution completion.
	///
	/// Example:
	/// ```swift
	/// let status = try await uploadcare.performAWSRekognition(fileUUID: "fileUUID")
	/// print(response)
	/// ```
	///
	/// - Parameters:
	///   - fileUUID: Unique ID of the file to process.
	///   - timeout: How long to wait for execution in seconds.
	/// - Returns: Execution status.
	@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
	public func performAWSRekognition(fileUUID: String, timeout: Double = 60*5) async throws -> AddonExecutionStatus {
		do {
			let response = try await executeAWSRekognition(fileUUID: fileUUID)
			var secondsPassed: Double = 0
			while true {
				let status = try await checkAWSRekognitionStatus(requestID: response.requestID)
				if status != .inProgress {
					return status
				}
				try await Task.sleep(nanoseconds: 5 * NSEC_PER_SEC)
				secondsPassed += 5

				if secondsPassed >= timeout {
					throw RequestManagerError.timeout
				}
			}
		} catch {
			throw RESTAPIError.fromError(error)
		}
	}

	#if !os(Linux)
	/// Check AWS Rekognition execution status.
	///
	/// Example:
	/// ```swift
	/// uploadcare.checkAWSRekognitionStatus(requestID: "requestID") { result in
	///     switch result {
	///     case .failure(let error):
	///         print(error)
	///     case .success(let status):
	///         print(status)
	///     }
	/// }
	/// ```
	///
	/// - Parameters:
	///   - requestID: Request ID returned by the Add-On execution request.
	///   - completionHandler: Completion handler.
	public func checkAWSRekognitionStatus(requestID: String, _ completionHandler: @escaping (Result<AddonExecutionStatus, RESTAPIError>) -> Void) {
		let urlString = RESTAPIBaseUrl + "/addons/aws_rekognition_detect_labels/execute/status/?request_id=\(requestID)"

		guard let url = URL(string: urlString) else {
			assertionFailure("Incorrect url")
			completionHandler(.failure(RESTAPIError.init(detail: "Incorrect url")))
			return
		}

		var urlRequest = requestManager.makeUrlRequest(fromURL: url, method: .get)
		requestManager.signRequest(&urlRequest)

		requestManager.performRequest(urlRequest) { (result: Result<ExecuteAddonStatusResponse, Error>) in
			switch result {
			case .failure(let error): completionHandler(.failure(RESTAPIError.fromError(error)))
			case .success(let response): completionHandler(.success(response.status))
			}
		}
	}
	#endif

	/// Check the status of an AWS Rekognition execution request that had been started using ``executeAWSRekognition(fileUUID:)`` method.
	///
	/// Example:
	/// ```swift
	/// let status = try await uploadcare.checkAWSRekognitionStatus(requestID: "requestID")
	/// print(status)
	/// ```
	/// - Parameter requestID: Request ID returned by the Add-On execution request.
	/// - Returns: Execution status.
	@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
	public func checkAWSRekognitionStatus(requestID: String) async throws -> AddonExecutionStatus {
		let urlString = RESTAPIBaseUrl + "/addons/aws_rekognition_detect_labels/execute/status/?request_id=\(requestID)"

		guard let url = URL(string: urlString) else {
			assertionFailure("Incorrect url")
			throw RESTAPIError.init(detail: "Incorrect url")
		}

		var urlRequest = requestManager.makeUrlRequest(fromURL: url, method: .get)
		requestManager.signRequest(&urlRequest)

		do {
			let response: ExecuteAddonStatusResponse = try await requestManager.performRequest(urlRequest)
			return response.status
		} catch {
			throw RESTAPIError.fromError(error)
		}
	}
}

// MARK: - AWS Rekognition Moderation
extension Uploadcare {
	#if !os(Linux)
	/// Execute AWS Rekognition Moderation Add-On for a given target to detect moderation labels in an image. **Note:** Detected moderation labels are stored in the file's appdata.
	///
	/// Example:
	/// ```swift
	/// uploadcare.executeAWSRekognitionModeration(fileUUID: "fileUUID") { result in
	///     switch result {
	///     case .failure(let error):
	///         print(error)
	///     case .success(let response):
	///         print(response) // contains requestID
	///     }
	/// }
	/// ```
	///
	/// - Parameters:
	///   - fileUUID: Unique ID of the file to process.
	///   - completionHandler: Completion handler.
	public func executeAWSRekognitionModeration(fileUUID: String, _ completionHandler: @escaping (Result<ExecuteAddonResponse, RESTAPIError>) -> Void) {

		let url = urlWithPath("/addons/aws_rekognition_detect_moderation_labels/execute/")
		var urlRequest = requestManager.makeUrlRequest(fromURL: url, method: .post)

		let bodyDictionary = [
			"target": fileUUID
		]

		urlRequest.httpBody = try? JSONEncoder().encode(bodyDictionary)

		requestManager.signRequest(&urlRequest)

		requestManager.performRequest(urlRequest) { (result: Result<ExecuteAddonResponse, Error>) in
			switch result {
			case .failure(let error): completionHandler(.failure(RESTAPIError.fromError(error)))
			case .success(let response): completionHandler(.success(response))
			}
		}
	}
	#endif

	/// Execute AWS Rekognition Moderation Add-On for a given target to detect moderation labels in an image. **Note:** Detected moderation labels are stored in the file's appdata.
	///
	/// Example:
	/// ```swift
	/// let response = try await uploadcare.executeAWSRekognitionModeration(fileUUID: "fileUUID")
	/// print(response)
	/// ```
	///
	/// - Parameter fileUUID: Unique ID of the file to process.
	/// - Returns: Execution response.
	@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
	public func executeAWSRekognitionModeration(fileUUID: String) async throws -> ExecuteAddonResponse {
		let url = urlWithPath("/addons/aws_rekognition_detect_moderation_labels/execute/")
		var urlRequest = requestManager.makeUrlRequest(fromURL: url, method: .post)

		let bodyDictionary = [
			"target": fileUUID
		]
		urlRequest.httpBody = try? JSONEncoder().encode(bodyDictionary)

		requestManager.signRequest(&urlRequest)

		do {
			let response: ExecuteAddonResponse = try await requestManager.performRequest(urlRequest)
			return response
		} catch {
			throw RESTAPIError.fromError(error)
		}
	}


	/// Execute AWS Rekognition Moderation Add-On for a given target to detect moderation labels in an image and wait for execution completion. **Note:** Detected moderation labels are stored in the file's appdata.
	///
	/// Example:
	/// ```swift
	/// let response = try await uploadcare.executeAWSRekognitionModeration(fileUUID: "fileUUID")
	/// print(response)
	/// ```
	///
	/// - Parameters:
	///   - fileUUID: Unique ID of the file to process.
	///   - timeout: How long to wait for execution in seconds.
	/// - Returns: Execution status.
	@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
	public func performAWSRekognitionModeration(fileUUID: String, timeout: Double = 60*5) async throws -> AddonExecutionStatus {
		do {
			let response = try await executeAWSRekognitionModeration(fileUUID: fileUUID)
			var secondsPassed: Double = 0
			while true {
				let status = try await checkAWSRekognitionModerationStatus(requestID: response.requestID)
				if status != .inProgress {
					return status
				}
				try await Task.sleep(nanoseconds: 5 * NSEC_PER_SEC)
				secondsPassed += 5

				if secondsPassed >= timeout {
					throw RequestManagerError.timeout
				}
			}
		} catch {
			throw RESTAPIError.fromError(error)
		}
	}

	#if !os(Linux)
	/// Check the status of an Add-On execution request that had been started using the ``executeAWSRekognitionModeration(fileUUID:_:)`` method.
	///
	/// Example:
	/// ```swift
	/// uploadcare.checkAWSRekognitionModerationStatus(requestID: "requestID") { result in
	///     switch result {
	///     case .failure(let error):
	///         print(error)
	///     case .success(let status):
	///         print(status)
	///     }
	/// }
	/// ```
	///
	/// - Parameters:
	///   - requestID: Request ID returned by the Add-On execution request.
	///   - completionHandler: Completion handler.
	public func checkAWSRekognitionModerationStatus(requestID: String, _ completionHandler: @escaping (Result<AddonExecutionStatus, RESTAPIError>) -> Void) {
		let urlString = RESTAPIBaseUrl + "/addons/aws_rekognition_detect_moderation_labels/execute/status/?request_id=\(requestID)"

		guard let url = URL(string: urlString) else {
			assertionFailure("Incorrect url")
			completionHandler(.failure(RESTAPIError.init(detail: "Incorrect url")))
			return
		}

		var urlRequest = requestManager.makeUrlRequest(fromURL: url, method: .get)
		requestManager.signRequest(&urlRequest)

		requestManager.performRequest(urlRequest) { (result: Result<ExecuteAddonStatusResponse, Error>) in
			switch result {
			case .failure(let error): completionHandler(.failure(RESTAPIError.fromError(error)))
			case .success(let response): completionHandler(.success(response.status))
			}
		}
	}
	#endif

	/// Check the status of an Add-On execution request that had been started using the ``executeAWSRekognitionModeration(fileUUID:)`` method.
	///
	/// Example:
	/// ```swift
	/// let status = try await uploadcare.checkAWSRekognitionModerationStatus(requestID: "requestID")
	/// print(status)
	/// ```
	/// - Parameter requestID: Request ID returned by the Add-On execution request.
	/// - Returns: Execution status.
	@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
	public func checkAWSRekognitionModerationStatus(requestID: String) async throws -> AddonExecutionStatus {
		let urlString = RESTAPIBaseUrl + "/addons/aws_rekognition_detect_moderation_labels/execute/status/?request_id=\(requestID)"

		guard let url = URL(string: urlString) else {
			assertionFailure("Incorrect url")
			throw RESTAPIError.init(detail: "Incorrect url")
		}

		var urlRequest = requestManager.makeUrlRequest(fromURL: url, method: .get)
		requestManager.signRequest(&urlRequest)

		do {
			let response: ExecuteAddonStatusResponse = try await requestManager.performRequest(urlRequest)
			return response.status
		} catch {
			throw RESTAPIError.fromError(error)
		}
	}
}

// MARK: - ClamAV virus checking
extension Uploadcare {
	#if !os(Linux)
	/// Execute ClamAV virus checking Add-On for a given target.
	///
	/// Example:
	/// ```swift
	/// let parameters = ClamAVAddonExecutionParams(purgeInfected: true)
	/// uploadcare.executeClamav(fileUUID: "fileUUID", parameters: parameters) { result in
	///     switch result {
	///     case .failure(let error):
	///         print(error)
	///     case .success(let response):
	///         print(response) // contains requestID
	///     }
	/// }
	/// ```
	///
	/// - Parameters:
	///   - fileUUID: Unique ID of the file to process.
	///   - parameters: Optional object with Add-On specific parameters.
	///   - completionHandler: Completion handler.
	public func executeClamav(fileUUID: String, parameters: ClamAVAddonExecutionParams? = nil, _ completionHandler: @escaping (Result<ExecuteAddonResponse, RESTAPIError>) -> Void) {
		let url = urlWithPath("/addons/uc_clamav_virus_scan/execute/")
		var urlRequest = requestManager.makeUrlRequest(fromURL: url, method: .post)

		let requestBody = ClamAVAddonExecutionRequestBody(target: fileUUID, params: parameters)
		urlRequest.httpBody = try? JSONEncoder().encode(requestBody)

		requestManager.signRequest(&urlRequest)

		requestManager.performRequest(urlRequest) { (result: Result<ExecuteAddonResponse, Error>) in
			switch result {
			case .failure(let error): completionHandler(.failure(RESTAPIError.fromError(error)))
			case .success(let response): completionHandler(.success(response))
			}
		}
	}
	#endif

	/// Execute ClamAV virus checking Add-On for a given target.
	///
	/// Example:
	/// ```swift
	/// let parameters = ClamAVAddonExecutionParams(purgeInfected: true)
	/// let response = try await uploadcare.executeClamav(
	///     fileUUID: "fileUUID",
	///     parameters: parameters
	/// )
	///
	/// print(response)
	/// ```
	///
	/// - Parameters:
	///   - fileUUID: Unique ID of the file to process.
	///   - parameters: Optional object with Add-On specific parameters.
	/// - Returns: Execution status.
	@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
	public func executeClamav(fileUUID: String, parameters: ClamAVAddonExecutionParams? = nil) async throws -> ExecuteAddonResponse {
		let url = urlWithPath("/addons/uc_clamav_virus_scan/execute/")
		var urlRequest = requestManager.makeUrlRequest(fromURL: url, method: .post)

		let requestBody = ClamAVAddonExecutionRequestBody(target: fileUUID, params: parameters)
		urlRequest.httpBody = try? JSONEncoder().encode(requestBody)

		requestManager.signRequest(&urlRequest)

		do {
			let response: ExecuteAddonResponse = try await requestManager.performRequest(urlRequest)
			return response
		} catch {
			throw RESTAPIError.fromError(error)
		}
	}


	/// Execute ClamAV virus checking Add-On for a given target and wait for execution completion.
	///
	/// Example:
	/// ```swift
	/// let parameters = ClamAVAddonExecutionParams(purgeInfected: true)
	/// let status = try await uploadcare.performClamav(
	///     fileUUID: "fileUUID",
	///     parameters: parameters
	/// )
	///
	/// print(status)
	/// ```
	///
	/// - Parameters:
	///   - fileUUID: Unique ID of the file to process.
	///   - parameters: Optional object with Add-On specific parameters.
	///   - timeout: How long to wait for execution in seconds.
	/// - Returns: Execution status.
	@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
	public func performClamav(fileUUID: String, parameters: ClamAVAddonExecutionParams? = nil, timeout: Double = 60*5) async throws -> AddonExecutionStatus {
		do {
			let response = try await executeClamav(fileUUID: fileUUID, parameters: parameters)
			var secondsPassed: Double = 0
			while true {
				let status = try await checkClamAVStatus(requestID: response.requestID)
				if status != .inProgress {
					return status
				}
				try await Task.sleep(nanoseconds: 5 * NSEC_PER_SEC)
				secondsPassed += 5

				if secondsPassed >= timeout {
					throw RequestManagerError.timeout
				}
			}
		} catch {
			throw RESTAPIError.fromError(error)
		}
	}

	#if !os(Linux)
	/// Check the status of a ClamAV Add-On execution request that had been started using ``executeClamav(fileUUID:parameters:_:)`` method.
	///
	/// Example:
	/// ```swift
	/// uploadcare.checkClamAVStatus(requestID: "requestID") { result in
	///     switch result {
	///     case .failure(let error):
	///         print(error)
	///     case .success(let status):
	///         print(status)
	///     }
	/// }
	/// ```
	///
	/// - Parameters:
	///   - requestID: Request ID returned by the Add-On execution request described above.
	///   - completionHandler: Completion handler.
	public func checkClamAVStatus(requestID: String, _ completionHandler: @escaping (Result<AddonExecutionStatus, RESTAPIError>) -> Void) {
		let urlString = RESTAPIBaseUrl + "/addons/uc_clamav_virus_scan/execute/status/?request_id=\(requestID)"

		guard let url = URL(string: urlString) else {
			assertionFailure("Incorrect url")
			completionHandler(.failure(RESTAPIError.init(detail: "Incorrect url")))
			return
		}

		var urlRequest = requestManager.makeUrlRequest(fromURL: url, method: .get)
		requestManager.signRequest(&urlRequest)

		requestManager.performRequest(urlRequest) { (result: Result<ExecuteAddonStatusResponse, Error>) in
			switch result {
			case .failure(let error): completionHandler(.failure(RESTAPIError.fromError(error)))
			case .success(let response): completionHandler(.success(response.status))
			}
		}
	}
	#endif

	/// Check the status of a ClamAV Add-On execution request that had been started using ``executeClamav(fileUUID:parameters:)``  method.
	///
	/// Example:
	/// ```swift
	/// let status = try await uploadcare.checkClamAVStatus(requestID: "requestID")
	/// print(status)
	/// ```
	/// - Parameter requestID: Request ID returned by the Add-On execution request described above.
	/// - Returns: Execution status.
	@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
	public func checkClamAVStatus(requestID: String) async throws -> AddonExecutionStatus {
		let urlString = RESTAPIBaseUrl + "/addons/uc_clamav_virus_scan/execute/status/?request_id=\(requestID)"

		guard let url = URL(string: urlString) else {
			assertionFailure("Incorrect url")
			throw RESTAPIError.init(detail: "Incorrect url")
		}

		var urlRequest = requestManager.makeUrlRequest(fromURL: url, method: .get)
		requestManager.signRequest(&urlRequest)

		do {
			let response: ExecuteAddonStatusResponse = try await requestManager.performRequest(urlRequest)
			return response.status
		} catch {
			throw RESTAPIError.fromError(error)
		}
	}
}

// MARK: - remove.bg
extension Uploadcare {
	#if !os(Linux)
	/// Execute remove.bg background image removal Add-On for a given target.
	///
	/// Example:
	/// ```swift
	/// let parameters = RemoveBGAddonExecutionParams(crop: true, typeLevel: .two)
	/// uploadcare.executeRemoveBG(fileUUID: "fileUUID", parameters: parameters) { result in
	///     switch result {
	///     case .failure(let error):
	///         print(error)
	///     case .success(let response):
	///         print(response) // contains requestID
	///     }
	/// }
	/// ```
	///
	/// - Parameters:
	///   - fileUUID: Unique ID of the file to process.
	///   - parameters: Optional object with Add-On specific parameters.
	///   - completionHandler: Completion handler.
	public func executeRemoveBG(fileUUID: String, parameters: RemoveBGAddonExecutionParams? = nil, _ completionHandler: @escaping (Result<ExecuteAddonResponse, RESTAPIError>) -> Void) {
		let url = urlWithPath("/addons/remove_bg/execute/")
		var urlRequest = requestManager.makeUrlRequest(fromURL: url, method: .post)

		let requestBody = RemoveBGAddonExecutionRequestBody(target: fileUUID, params: parameters)
		urlRequest.httpBody = try? JSONEncoder().encode(requestBody)

		requestManager.signRequest(&urlRequest)

		requestManager.performRequest(urlRequest) { (result: Result<ExecuteAddonResponse, Error>) in
			switch result {
			case .failure(let error): completionHandler(.failure(RESTAPIError.fromError(error)))
			case .success(let response): completionHandler(.success(response))
			}
		}
	}
	#endif

	/// Execute remove.bg background image removal Add-On for a given target.
	///
	/// Example:
	/// ```swift
	/// let parameters = RemoveBGAddonExecutionParams(crop: true, typeLevel: .two)
	/// let response = try await uploadcare.executeRemoveBG(
	///     fileUUID: "fileUUID",
	///     parameters: parameters
	/// )
	///
	/// print(response)
	/// ```
	/// - Parameters:
	///   - fileUUID: Unique ID of the file to process.
	///   - parameters: Optional object with Add-On specific parameters.
	/// - Returns: Execution reponse.
	@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
	public func executeRemoveBG(fileUUID: String, parameters: RemoveBGAddonExecutionParams? = nil) async throws -> ExecuteAddonResponse {
		let url = urlWithPath("/addons/remove_bg/execute/")
		var urlRequest = requestManager.makeUrlRequest(fromURL: url, method: .post)

		let requestBody = RemoveBGAddonExecutionRequestBody(target: fileUUID, params: parameters)
		urlRequest.httpBody = try? JSONEncoder().encode(requestBody)

		requestManager.signRequest(&urlRequest)

		do {
			let response: ExecuteAddonResponse = try await requestManager.performRequest(urlRequest)
			return response
		} catch {
			throw RESTAPIError.fromError(error)
		}
	}


	/// Execute remove.bg background image removal Add-On for a given target and wait for execution completion.
	///
	/// Example:
	/// ```swift
	/// let parameters = RemoveBGAddonExecutionParams(crop: true, typeLevel: .two)
	/// let response = try await uploadcare.performRemoveBG(
	///     fileUUID: "fileUUID",
	///     parameters: parameters
	/// )
	///
	/// print(response)
	/// ```
	///
	/// - Parameters:
	///   - fileUUID: Unique ID of the file to process.
	///   - parameters: Optional object with Add-On specific parameters.
	///   - timeout: How long to wait for execution in seconds.
	/// - Returns: Execution status.
	@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
	public func performRemoveBG(fileUUID: String, parameters: RemoveBGAddonExecutionParams? = nil, timeout: Double = 60*5) async throws -> RemoveBGAddonAddonExecutionStatus {
		do {
			let response = try await executeRemoveBG(fileUUID: fileUUID, parameters: parameters)
			var secondsPassed: Double = 0
			while true {
				let response = try await checkRemoveBGStatus(requestID: response.requestID)
				if response.status != .inProgress {
					return response
				}
				try await Task.sleep(nanoseconds: 5 * NSEC_PER_SEC)
				secondsPassed += 5

				if secondsPassed >= timeout {
					throw RequestManagerError.timeout
				}
			}
		} catch {
			throw RESTAPIError.fromError(error)
		}
	}

	#if !os(Linux)
	/// Check the status of a Remove.bg Add-On execution request that had been started using ``executeRemoveBG(fileUUID:parameters:_:)`` method.
	///
	/// Example:
	/// ```swift
	/// uploadcare.checkRemoveBGStatus(requestID: "requestID") { result in
	///     switch result {
	///     case .failure(let error):
	///         print(error)
	///     case .success(let status):
	///         print(status)
	///     }
	/// }
	/// ```
	///
	/// - Parameters:
	///   - requestID: Request ID returned by the Add-On execution request described above.
	///   - completionHandler: Completion handler.
	public func checkRemoveBGStatus(requestID: String, _ completionHandler: @escaping (Result<RemoveBGAddonAddonExecutionStatus, RESTAPIError>) -> Void) {
		let urlString = RESTAPIBaseUrl + "/addons/remove_bg/execute/status/?request_id=\(requestID)"

		guard let url = URL(string: urlString) else {
			assertionFailure("Incorrect url")
			completionHandler(.failure(RESTAPIError.init(detail: "Incorrect url")))
			return
		}

		var urlRequest = requestManager.makeUrlRequest(fromURL: url, method: .get)
		requestManager.signRequest(&urlRequest)

		requestManager.performRequest(urlRequest) { (result: Result<RemoveBGAddonAddonExecutionStatus, Error>) in
			switch result {
			case .failure(let error): completionHandler(.failure(RESTAPIError.fromError(error)))
			case .success(let response): completionHandler(.success(response))
			}
		}
	}
	#endif

	/// Check the status of a Remove.bg Add-On execution request that had been started using ``executeRemoveBG(fileUUID:parameters:)`` method.
	///
	/// Example:
	/// ```swift
	/// let status = try await uploadcare.checkRemoveBGStatus(requestID: "requestID")
	/// print(status)
	/// ```
	///
	/// - Parameter requestID: Request ID returned by the Add-On execution request described above.
	/// - Returns: Execution status.
	@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
	public func checkRemoveBGStatus(requestID: String) async throws -> RemoveBGAddonAddonExecutionStatus {
		let urlString = RESTAPIBaseUrl + "/addons/remove_bg/execute/status/?request_id=\(requestID)"

		guard let url = URL(string: urlString) else {
			assertionFailure("Incorrect url")
			throw RESTAPIError.init(detail: "Incorrect url")
		}

		var urlRequest = requestManager.makeUrlRequest(fromURL: url, method: .get)
		requestManager.signRequest(&urlRequest)

		do {
			let response: RemoveBGAddonAddonExecutionStatus = try await requestManager.performRequest(urlRequest)
			return response
		} catch {
			throw RESTAPIError.fromError(error)
		}
	}
}
