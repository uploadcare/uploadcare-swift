//
//  BatchFilesOperationResponse.swift
//  
//
//  Created by Sergey Armodin on 05.02.2020.
//  Copyright © 2020 Uploadcare, Inc. All rights reserved.
//

import Foundation


public struct BatchFilesOperationResponse: Codable {
	
	/// Dictionary of passed files UUIDs and problems associated with these UUIDs.
	public var problems: [String: String]
	
	/// List of file objects that has been updated.
	public var result: [File]
	
	
	enum CodingKeys: String, CodingKey {
		case problems
		case result
	}
	
	
	init(
		problems: [String: String],
		result: [File]
	) {
		self.problems = problems
		self.result = result
	}

	public init(from decoder: Decoder) throws {
		let container = try decoder.container(keyedBy: CodingKeys.self)

		let problems = try container.decodeIfPresent([String: String].self, forKey: .problems) ?? [:]
		let result = try container.decodeIfPresent([File].self, forKey: .result) ?? [File]()

		self.init(
			problems: problems,
			result: result
		)
	}
}


extension BatchFilesOperationResponse: CustomDebugStringConvertible {
	public var debugDescription: String {
		return """
		\(type(of: self)):
			problems: \(problems)
			result: \(String(describing: result))
		"""
	}
}

