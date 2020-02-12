//
//  CopyFileToLocalStorageResponse.swift
//  
//
//  Created by Sergey Armodin on 05.02.2020.
//

import Foundation


public struct CopyFileToLocalStorageResponse: Codable {
	
	public var type: String
	public var result: File?
	
	
	enum CodingKeys: String, CodingKey {
		case type
		case result
	}
	
	
	init(
		type: String,
		result: File?
	) {
		self.type = type
		self.result = result
	}

	public init(from decoder: Decoder) throws {
		let container = try decoder.container(keyedBy: CodingKeys.self)

		let type = try container.decodeIfPresent(String.self, forKey: .type) ?? "file"
		let result = try container.decodeIfPresent(File.self, forKey: .result)

		self.init(
			type: type,
			result: result
		)
	}
}


extension CopyFileToLocalStorageResponse: CustomDebugStringConvertible {
	public var debugDescription: String {
		return """
		CopyFileToLocalStorageResponse:
			type: \(type)
			result: \(String(describing: result))
		"""
	}
}

