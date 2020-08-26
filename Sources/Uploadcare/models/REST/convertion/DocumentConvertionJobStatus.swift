//
//  DocumentConvertionJobStatus.swift
//  
//
//  Created by Sergei Armodin on 26.08.2020.
//

import Foundation

/// Conversion job status
public enum ConvertionStatus {
	case pending
	case processing
	case finished
	case failed(error: String)
	case cancelled
	case unknown
}

public struct DocumentConvertionJobStatus: Codable {
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
	
	public var status: ConvertionStatus {
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
