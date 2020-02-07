//
//  RESTAPIError.swift
//  
//
//  Created by Sergey Armodin on 05.02.2020.
//

import Foundation


public struct RESTAPIError: Codable {
	
	/// Error message
	public var detail: String
	
	enum CodingKeys: String, CodingKey {
		case detail
	}
	
	
	init(
		detail: String
	) {
		self.detail = detail
	}

	public init(from decoder: Decoder) throws {
		let container = try decoder.container(keyedBy: CodingKeys.self)

		let detail = try container.decodeIfPresent(String.self, forKey: .detail) ?? ""

		self.init(
			detail: detail
		)
	}
	
	static func defaultError() -> RESTAPIError {
		return RESTAPIError(detail: "Unknown error")
	}
}


extension RESTAPIError: CustomDebugStringConvertible {
	public var debugDescription: String {
		return """
		\(type(of: self)):
			detail: \(detail)
		"""
	}
}

