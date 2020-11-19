//
//  ConvertDocumentJobStatus.swift
//  
//
//  Created by Sergey Armodin on 26.08.2020.
//  Copyright © 2020 Uploadcare, Inc. All rights reserved.
//

import Foundation

public struct ConvertDocumentJobStatus: Codable {
	/// Conversion job status
	let statusString: String
	
	/// Holds a conversion error if we were unable to handle your file.
	let error: String?
	
	/// Repeats the contents of your processing output. Example: ["uuid": "500196bc-9da5-4aaf-8f3e-70a4ce86edae"]
	public let result: [String: String]
	
	enum CodingKeys: String, CodingKey {
        case statusString = "status"
        case error
        case result
    }
	
	public var status: ConversionStatus {
		switch statusString {
		case "pending": return .pending
		case "processing": return .processing
		case "finished": return .finished
		case "failed": return .failed(error: error ?? "unknown error")
		case "cancelled": return .cancelled
		default: return .unknown
		}
	}
	
	public init(from decoder: Decoder) throws {
		let container = try decoder.container(keyedBy: CodingKeys.self)
		
		statusString = try container.decodeIfPresent(String.self, forKey: .statusString) ?? ""
		error = try container.decodeIfPresent(String.self, forKey: .error)
		result = try container.decodeIfPresent([String: String].self, forKey: .result) ?? [:]
	}
}
