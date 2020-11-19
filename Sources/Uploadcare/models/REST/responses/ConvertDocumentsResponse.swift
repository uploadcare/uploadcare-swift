//
//  ConvertDocumentsResponse.swift
//  
//
//  Created by Sergey Armodin on 03.08.2020.
//  Copyright © 2020 Uploadcare, Inc. All rights reserved.
//

import Foundation

public struct ConvertDocumentsResponse: Codable {
	/// Dictionary of problems related to your processing job, if any. Key is the path you requested.
	public let problems: [String: String]
	
	/// Result for each requested path, in case of no errors for that path.
	public let result: [DocumentConversionJob]
	
	
	enum CodingKeys: String, CodingKey {
        case problems
        case result
    }
	
	
	public init(from decoder: Decoder) throws {
		let container = try decoder.container(keyedBy: CodingKeys.self)
		
		problems = try container.decodeIfPresent([String: String].self, forKey: .problems) ?? [:]
		result = try container.decodeIfPresent([DocumentConversionJob].self, forKey: .result) ?? []
	}
}
