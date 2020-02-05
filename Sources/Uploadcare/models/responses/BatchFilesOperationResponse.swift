//
//  BatchFilesOperationResponse.swift
//  
//
//  Created by Sergey Armodin on 05.02.2020.
//

import Foundation


public struct BatchFilesOperationResponse: Codable {
	
	/// Dictionary of passed files UUIDs and problems associated with these UUIDs.
	public var problems: [String: String]
	
	/// List of file objects that has been updated.
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


extension BatchFilesOperationResponse: CustomStringConvertible {
	public var description: String {
		return """
		BatchFilesOperationResponse:
			problems: \(problems)
			result: \(String(describing: result))
		"""
	}
}

