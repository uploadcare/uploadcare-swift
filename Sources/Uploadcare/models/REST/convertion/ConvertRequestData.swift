//
//  ConvertRequestData.swift
//  
//
//  Created by Sergei Armodin on 26.08.2020.
//

import Foundation

/// Struct for creating document conversion job request
internal struct ConvertRequestData: Codable {
	internal init(paths: [String], store: String) {
		self.paths = paths
		self.store = store
	}
	
	/// An array of UUIDs of your source documents to convert together with the specified target format. Documentation:
	/// https://uploadcare.com/docs/transformations/document_conversion/#convert-url-formatting
	/// https://uploadcare.com/docs/transformations/video_encoding/?#process-operations
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
