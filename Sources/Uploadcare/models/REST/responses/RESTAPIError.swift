//
//  RESTAPIError.swift
//  
//
//  Created by Sergey Armodin on 05.02.2020.
//  Copyright © 2020 Uploadcare, Inc. All rights reserved.
//

import Foundation

public struct RESTAPIError: Error, Codable {
	/// Error message.
	public var detail: String

	enum CodingKeys: String, CodingKey {
		case detail
	}

	// MARK: - Init
	init(detail: String) {
		self.detail = detail
	}

	public init(from decoder: Decoder) throws {
		let container = try decoder.container(keyedBy: CodingKeys.self)
		let detail = try container.decodeIfPresent(String.self, forKey: .detail) ?? ""
		self.init(detail: detail)
	}

	/// Default error.
	static func defaultError() -> RESTAPIError {
		return RESTAPIError(detail: "Unknown error")
	}

	/// Cast from Error.
	/// - Parameter error: Error
	static func fromError(_ error: Error) -> RESTAPIError {
		if case let RequestManagerError.invalidRESTAPIResponse(requestError) = error {
			return requestError
		}

		if case RequestManagerError.timeout = error {
			return RESTAPIError(detail: "Operation timeout")
		}
		return defaultError()
	}
}

// MARK: - CustomDebugStringConvertible
extension RESTAPIError: CustomDebugStringConvertible {
	public var debugDescription: String {
		return """
		\(type(of: self)):
			detail: \(detail)
		"""
	}
}

