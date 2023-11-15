//
//  RequestManager.swift
//  
//
//  Created by Sergei Armodin on 01.02.2022.
//  Copyright © 2022 Uploadcare, Inc. All rights reserved.
//

import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

#if canImport(AsyncHTTPClient)
import AsyncHTTPClient
import NIOHTTP1
#endif

internal enum RequestManagerError: Error {
	case invalidRESTAPIResponse(error: RESTAPIError)
	case invalidUploadAPIResponse(error: UploadError)
	case noResponse
	case parsingError
	case emptyResponse
	case timeout
}

internal class RequestManager {
	enum HTTPMethod: String {
		case connect = "CONNECT"
		case delete = "DELETE"
		case get = "GET"
		case head = "HEAD"
		case options = "OPTIONS"
		case patch = "PATCH"
		case post = "POST"
		case put = "PUT"
		case trace = "TRACE"
	}

	// MARK: - Public properties
	var authScheme: Uploadcare.AuthScheme = .signed

	// MARK: - Private properties
	/// API public key
	private let publicKey: String
	/// Secret Key. Optional. Is used for authorization
	private let secretKey: String?
	/// URL session
	private let urlSession: URLSession = URLSession.shared
	
	/// Request timeout
	private let requestsTimeout: Int64 = 30

	// MARK: - Init
	init(publicKey: String, secretKey: String?) {
		self.publicKey = publicKey
		self.secretKey = secretKey
	}
}

// MARK: - Internal methods
internal extension RequestManager {
	/// Build URL request.
	/// - Parameters:
	///   - url: Request url.
	///   - method: HTTP method.
	/// - Returns: Request object.
	func makeUrlRequest(fromURL url: URL, method: HTTPMethod) -> URLRequest {
		var urlRequest = URLRequest(url: url)
		urlRequest.httpMethod = method.rawValue
		urlRequest.addValue("application/json", forHTTPHeaderField: "Content-Type")
		urlRequest.addValue("application/vnd.uploadcare-v\(APIVersion)+json", forHTTPHeaderField: "Accept")

		let userAgent = "\(libraryName)/\(libraryVersion)/\(publicKey) (Swift/\(getSwiftVersion()))"
		urlRequest.addValue(userAgent, forHTTPHeaderField: "User-Agent")

		return urlRequest
	}

	/// Adds signature to network request for secure authorization.
	/// - Parameter urlRequest: URL request object.
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
    

	#if !os(Linux)
	@discardableResult
	func performRequest<T: Codable>(_ request: URLRequest, _ completion: @escaping(Result<T, Error>) -> Void) -> URLSessionDataTask? {
		let task = urlSession.dataTask(with: request) { [weak self] (data, response, error) in
			guard let self = self else { return }

			if let error = error {
				completion(.failure(error))
				return
			}

			guard let response = response, let data = data else {
				completion(.failure(RequestManagerError.noResponse))
				return
			}

			if data.count == 0, true is T {
				completion(.success(true as! T))
				return
			}

			if data.count == 0 {
				completion(.failure(RequestManagerError.emptyResponse))
				return
			}

			if T.self is String.Type, let string = String(data: data, encoding: .utf8) {
				completion(.success(string as! T))
				return
			}

			let responseData: T
			do {
				if request.url?.host == RESTAPIHost {
					try self.validateRESTAPIResponse(statusCode: (response as? HTTPURLResponse)?.statusCode ?? 0, data: data)
				}
				if request.url?.host == uploadAPIHost {
					try self.validateUploadAPIResponse(statusCode: (response as? HTTPURLResponse)?.statusCode ?? 0, data: data)
				}
				responseData = try JSONDecoder().decode(T.self, from: data)
			} catch let error {
				completion(.failure(error))
				return
			}

			completion(.success(responseData))
		}
		task.resume()
		return task
	}
	#endif

	#if os(Linux)
	@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
	func catchRedirect(_ request: URLRequest) async throws -> String {
		let config = HTTPClient.Configuration(redirectConfiguration: .disallow)
		let httpClient: HTTPClient = HTTPClient(eventLoopGroupProvider: .createNew, configuration: config)

		defer {
			DispatchQueue.main.async {
				try? httpClient.syncShutdown()
			}
		}

		let method =  NIOHTTP1.HTTPMethod(rawValue: request.httpMethod ?? "GET")
		var headers = HTTPHeaders()
		if let requestHeaders = request.allHTTPHeaderFields {
			for header in requestHeaders {
				headers.add(name: header.key, value: header.value)
			}
		}

		var body: HTTPClient.Body?
		if let requestBody = request.httpBody {
			body = .data(requestBody)
		}

		let req = try HTTPClient.Request(
			url: request.url?.absoluteString ?? "",
			method: method,
			headers: headers,
			body: body
		)

		let response = try await httpClient
			.execute(request: req)
			.get()

		return response.headers.first(name: "location") ?? ""
	}
	#endif

	@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
	@discardableResult
	func performRequest<T: Codable>(_ request: URLRequest) async throws -> T {
		#if !os(Linux)
		let (data, response) = try await URLSession.shared.data(for: request)

		if data.count == 0, true is T {
			return true as! T
		}

		guard data.count > 0 else {
			throw RequestManagerError.emptyResponse
		}

		if T.self is String.Type, let string = String(data: data, encoding: .utf8) {
			return string as! T
		}

		if request.url?.host == RESTAPIHost {
			try self.validateRESTAPIResponse(statusCode: (response as? HTTPURLResponse)?.statusCode ?? 0, data: data)
		}
		if request.url?.host == uploadAPIHost {
			try self.validateUploadAPIResponse(statusCode: (response as? HTTPURLResponse)?.statusCode ?? 0, data: data)
		}
		return try JSONDecoder().decode(T.self, from: data)

		#else

		let httpClient: HTTPClient = HTTPClient(eventLoopGroupProvider: .createNew)
		defer {
			DispatchQueue.main.async {
				try? httpClient.syncShutdown()
			}
		}

		let method =  NIOHTTP1.HTTPMethod(rawValue: request.httpMethod ?? "GET")
		var headers = HTTPHeaders()
		if let requestHeaders = request.allHTTPHeaderFields {
			for header in requestHeaders {
				headers.add(name: header.key, value: header.value)
			}
		}

		var body: HTTPClient.Body?
		if let requestBody = request.httpBody {
			body = .data(requestBody)
		}

		let req = try HTTPClient.Request(
			url: request.url?.absoluteString ?? "",
			method: method,
			headers: headers,
			body: body
		)
		let response = try await httpClient
			.execute(request: req)
			.get()

		var data = Data()
		if var body = response.body, let bytes = body.readBytes(length: body.readableBytes) {
			data = Data(bytes)
		}

		if data.count == 0, true is T {
		   return true as! T
		}

		if T.self is Data.Type {
			return data as! T
		}

		guard data.count > 0 else {
		   throw RequestManagerError.emptyResponse
		}

		if T.self is String.Type, let string = String(data: data, encoding: .utf8) {
		   return string as! T
		}

		if request.url?.host == RESTAPIHost {
			try self.validateRESTAPIResponse(statusCode: Int(response.status.code), data: data)
		}
		if request.url?.host == uploadAPIHost {
			try self.validateUploadAPIResponse(statusCode: Int(response.status.code), data: data)
		}
		return try JSONDecoder().decode(T.self, from: data)
		#endif
	}

	func validateRESTAPIResponse(statusCode: Int, data: Data?) throws {
		if !(200..<300).contains(statusCode) {
			#if DEBUG
			if let data = data {
				DLog(data.toString() ?? "")
			}
			#endif

			if let data = data, let decodedData = try? JSONDecoder().decode(RESTAPIError.self, from: data) {
				throw RequestManagerError.invalidRESTAPIResponse(error: decodedData)
			}

			throw RequestManagerError.invalidRESTAPIResponse(error: RESTAPIError.defaultError())
		}
	}

	func validateUploadAPIResponse(statusCode: Int, data: Data?) throws {
		if !(200..<300).contains(statusCode) {

			if let detail = data?.toString() {
				throw RequestManagerError.invalidUploadAPIResponse(error: UploadError(status: statusCode, detail: detail))
			}

			let error = UploadError.defaultError(withStatus: statusCode)
			throw RequestManagerError.invalidUploadAPIResponse(error: error)
		}
	}
}
