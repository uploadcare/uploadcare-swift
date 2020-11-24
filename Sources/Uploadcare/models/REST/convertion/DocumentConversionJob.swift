//
//  DocumentConversionJob.swift
//  
//
//  Created by Sergey Armodin on 03.08.2020.
//  Copyright © 2020 Uploadcare, Inc. All rights reserved.
//

import Foundation

public struct DocumentConversionJob: Codable {
	/// Source file identifier including a target format, if present.
	public let originalSource: String
	
	/// A UUID of your converted document.
	public let uuid: String
	
	/// A conversion job token that can be used to get a job status.
	public let token: Int
	
	
	enum CodingKeys: String, CodingKey {
        case originalSource = "original_source"
        case uuid
        case token
    }
	
	public init(from decoder: Decoder) throws {
		let container = try decoder.container(keyedBy: CodingKeys.self)
		
		originalSource = try container.decodeIfPresent(String.self, forKey: .originalSource) ?? ""
		uuid = try container.decodeIfPresent(String.self, forKey: .uuid) ?? ""
		token = try container.decodeIfPresent(Int.self, forKey: .token) ?? 0
	}
}
