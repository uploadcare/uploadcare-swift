//
//  File.swift
//  
//
//  Created by Sergei Armodin on 01.02.2022.
//

import Foundation

internal enum RequestManagerError: Error {
	case invalidRESTAPIResponse(error: RESTAPIError)
	case invalidUploadAPIResponse(error: UploadError)
	case noResponse
	case parsingError
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
	/// Library name
	private var libraryName = "UploadcareSwift"
	/// Library version
	private var libraryVersion = "0.6.0"
	/// API public key
	private var publicKey: String
	/// Secret Key. Optional. Is used for authorization
	private var secretKey: String?
	/// URL session
	private var urlSession: URLSession = URLSession.shared

	// MARK: - Init
	init(publicKey: String, secretKey: String?) {
		self.publicKey = publicKey
		self.secretKey = secretKey
	}
}

// MARK: - Public methods
extension RequestManager {
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

			let responseData: T
			do {
				try self.validate(response: response, data: data)
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
    
	func validate(response: URLResponse, data: Data?) throws {
		guard let httpResponse = response as? HTTPURLResponse else { return }
		if !(200..<300).contains(httpResponse.statusCode) {
			var apiError = RESTAPIError.defaultError()
			if let data = data, let decodedData = try? JSONDecoder().decode(RESTAPIError.self, from: data) {
				apiError = decodedData
			}
			throw RequestManagerError.invalidRESTAPIResponse(error: apiError)
		}
	}
}
