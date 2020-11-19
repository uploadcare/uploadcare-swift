//
//  StartMulipartUploadResponse.swift
//  
//
//  Created by Sergey Armodin on 16.02.2020.
//  Copyright © 2020 Uploadcare, Inc. All rights reserved.
//

import Foundation


public struct StartMulipartUploadResponse: Codable {
	
	/// Parts urls
	public var parts: [String]
	
	/// Uploaded file UUID.
	public var uuid: String
	
	enum CodingKeys: String, CodingKey {
		case parts
		case uuid
	}
	
	
	init(parts: [String], uuid: String) {
		self.parts = parts
		self.uuid = uuid
	}
	
	public init(from decoder: Decoder) throws {
		let container = try decoder.container(keyedBy: CodingKeys.self)
		
		let parts = try container.decodeIfPresent([String].self, forKey: .parts) ?? []
		let uuid = try container.decodeIfPresent(String.self, forKey: .uuid) ?? ""
		
		self.init(parts: parts, uuid: uuid)
	}
	
}
