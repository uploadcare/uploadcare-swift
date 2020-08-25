//
//  DocumentConvertionJob.swift
//  
//
//  Created by Sergei Armodin on 03.08.2020.
//

import Foundation

public struct DocumentConvertionJob: Codable {
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

/// Struct for creating document convertion job request
internal struct ConvertDocumentsRequestData: Codable {
	internal init(paths: [String], store: String) {
		self.paths = paths
		self.store = store
	}
	
	/// An array of UUIDs of your source documents to convert together with the specified target format (see documentation: https://uploadcare.com/docs/transformations/document_conversion/#convert-url-formatting)
	let paths: [String]
	
	/// A flag indicating if we should store your outputs.
	let store: String
	
	enum CodingKeys: String, CodingKey {
        case paths
        case store
    }
	
	init(from decoder: Decoder) throws {
		let container = try decoder.container(keyedBy: CodingKeys.self)
		
		paths = try container.decodeIfPresent([String].self, forKey: .paths) ?? []
		store = try container.decodeIfPresent(String.self, forKey: .store) ?? "1"
	}
}
