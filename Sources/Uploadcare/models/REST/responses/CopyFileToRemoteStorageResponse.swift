//
//  CopyFileToRemoteStorageResponse.swift
//  
//
//  Created by Sergey Armodin on 10.02.2020.
//  Copyright © 2020 Uploadcare, Inc. All rights reserved.
//

import Foundation


/// The parameter is used to specify file names Uploadcare passes to a custom storage. In case the parameter is omitted, we use pattern of your custom storage. Use any combination of allowed values.
public enum NamesPattern: String {
	case defaultPattern = "${default}"
	case autoFilename = "${auto_filename}"
	case effects = "${effects}"
	case filename = "${filename}"
	case uuid = "${uuid}"
	case ext = "${ext}"
}


public struct CopyFileToRemoteStorageResponse: Codable {
	
	/// Default: "url".
	public var type: String
		
	/// URL with an s3 scheme. Your bucket name is put as a host, and an s3 object path follows.
	public var result: String
	
	
	enum CodingKeys: String, CodingKey {
		case type, result
	}
	
	
	init(type: String, result: String) {
		self.type = type
		self.result = result
	}

	public init(from decoder: Decoder) throws {
		let container = try decoder.container(keyedBy: CodingKeys.self)

		let type = try container.decodeIfPresent(String.self, forKey: .type) ?? "file"
		let result = try container.decodeIfPresent(String.self, forKey: .result) ?? ""

		self.init(type: type, result: result)
	}
}


extension CopyFileToRemoteStorageResponse: CustomDebugStringConvertible {
	public var debugDescription: String {
		return """
		CopyFileToRemoteStorageResponse:
			type: \(type)
			result: \(String(describing: result))
		"""
	}
}

