//
//  ConvertRequestData.swift
//  
//
//  Created by Sergey Armodin on 26.08.2020.
//  Copyright © 2020 Uploadcare, Inc. All rights reserved.
//

import Foundation

/// Struct for creating document conversion job request
internal struct ConvertRequestData: Codable {
	internal init(paths: [String], store: String, saveInGroup: String?) {
		self.paths = paths
		self.store = store
		self.saveInGroup = saveInGroup
	}
	
	/// An array of UUIDs of your source documents to convert together with the specified target format. Documentation:
	/// https://uploadcare.com/docs/transformations/document_conversion/#convert-url-formatting
	/// https://uploadcare.com/docs/transformations/video_encoding/?#process-operations
	let paths: [String]

	/// A flag indicating if we should store your outputs.
	let store: String

	/// When `save_in_group` is set to `true`, multi-page documents additionally will be saved as a file group.
	let saveInGroup: String?
	
	enum CodingKeys: String, CodingKey {
		case paths
		case store
		case saveInGroup = "save_in_group"
	}

	init(from decoder: Decoder) throws {
		let container = try decoder.container(keyedBy: CodingKeys.self)

		paths = try container.decodeIfPresent([String].self, forKey: .paths) ?? []
		store = try container.decodeIfPresent(String.self, forKey: .store) ?? "1"
		saveInGroup = try container.decodeIfPresent(String.self, forKey: .saveInGroup)
	}
}
