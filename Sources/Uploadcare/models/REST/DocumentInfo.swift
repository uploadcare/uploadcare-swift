//
//  DocumentInfo.swift
//  
//
//  Created by Sergei Armodin on 23.05.2024.
//  Copyright © 2024 Uploadcare, Inc. All rights reserved.
//

import Foundation

public struct ConversionFormat: Codable {
	/// Supported target document format.
	public let name: String

	enum CodingKeys: String, CodingKey {
		case name
	}

	public init(from decoder: Decoder) throws {
		let container = try decoder.container(keyedBy: CodingKeys.self)

		self.name = try container.decodeIfPresent(String.self, forKey: .name) ?? ""
	}
}

public struct DocumentFormat: Codable {
	internal init(name: String, conversionFormats: [ConversionFormat]) {
		self.name = name
		self.conversionFormats = conversionFormats
	}
	
	/// A detected document format.
	public let name: String
	
	/// The conversions that are supported for the document.
	public let conversionFormats: [ConversionFormat]

	enum CodingKeys: String, CodingKey {
		case name
		case conversionFormats = "conversion_formats"
	}

	public init(from decoder: Decoder) throws {
		let container = try decoder.container(keyedBy: CodingKeys.self)
		
		self.name = try container.decodeIfPresent(String.self, forKey: .name) ?? ""
		self.conversionFormats = try container.decodeIfPresent([ConversionFormat].self, forKey: .conversionFormats) ?? []
	}
}

public struct DocumentInfo: Codable {
	/// Holds an error if your document can't be handled.
	public let error: String?
	
	/// Document format details.
	public let format: DocumentFormat
	
	/// Information about already converted groups.
	public let convertedGroups: [String: String]?

	enum CodingKeys: String, CodingKey {
		case error
		case format
		case convertedGroups = "converted_groups"
	}

	public init(from decoder: Decoder) throws {
		let container = try decoder.container(keyedBy: CodingKeys.self)

		self.error = try container.decodeIfPresent(String.self, forKey: .error)
		self.format = try container.decodeIfPresent(DocumentFormat.self, forKey: .format) ?? DocumentFormat(name: "", conversionFormats: [])
		self.convertedGroups = try container.decodeIfPresent([String: String].self, forKey: .convertedGroups)
	}
}
