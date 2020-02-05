//
//  BatchFileStoringResponse.swift
//  
//
//  Created by Sergey Armodin on 05.02.2020.
//

import Foundation


public struct BatchFileStoringResponse: Codable {
	
	/// Dictionary of passed files UUIDs and problems associated with these UUIDs.
	public var problems: [String: String]
	
	/// List of file objects that has been stored.
	public var result: [FileInfo]
	
	
	enum CodingKeys: String, CodingKey {
		case problems
		case result
	}
	
	
	init(
		problems: [String: String],
		result: [FileInfo]
	) {
		self.problems = problems
		self.result = result
	}

	public init(from decoder: Decoder) throws {
		let container = try decoder.container(keyedBy: CodingKeys.self)

		let problems = try container.decodeIfPresent([String: String].self, forKey: .problems) ?? [:]
		let result = try container.decodeIfPresent([FileInfo].self, forKey: .result) ?? [FileInfo]()

		self.init(
			problems: problems,
			result: result
		)
	}
}


extension BatchFileStoringResponse: CustomStringConvertible {
	public var description: String {
		return """
		BatchFileStoringResponse:
			problems: \(problems)
			result: \(String(describing: result))
		"""
	}
}

