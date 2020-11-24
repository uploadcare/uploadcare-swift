//
//  UploadFromURLStatus.swift
//  
//
//  Created by Sergey Armodin on 25.01.2020.
//  Copyright © 2020 Uploadcare, Inc. All rights reserved.
//

import Foundation


/// Status of a file uploaded from URL.
public struct UploadFromURLStatus: Codable {
	
	public enum Status: String, Codable {
		case unknown
		case waiting
		case progress
		case error
		case success
	}

	
	/// Uplpad status
	public var status: UploadFromURLStatus.Status
	
	/// Currently uploaded file size in bytes (for status "progress)
	public var done: Int?
	
	/// Total downloading file bytes count (for status "progress)
	public var total: Int?
	
	/// File download error description (for status "error")
	public var error: String?
	
	/// Uploaded file info. Not nil if status is "success"
	public var fileInfo: UploadedFile?
	
	
	enum CodingKeys: String, CodingKey {
		case status
		case done
		case total
		case error
	}
	
	
	init(
		status: UploadFromURLStatus.Status,
		done: Int?,
		total: Int?,
		error: String?,
		fileInfo: UploadedFile?
	) {
		self.status = status
		self.done = done
		self.total = total
		self.error = error
		self.fileInfo = fileInfo
	}
	
	public init(from decoder: Decoder) throws {
		let container = try decoder.container(keyedBy: CodingKeys.self)
		
		let status = try container.decodeIfPresent(UploadFromURLStatus.Status.self, forKey: .status) ?? .unknown
		let done = try container.decodeIfPresent(Int.self, forKey: .done)
		let total = try container.decodeIfPresent(Int.self, forKey: .total)
		let error = try container.decodeIfPresent(String.self, forKey: .error)
		
		let fileInfo = try? UploadedFile(from: decoder)

		self.init(
			status: status,
			done: done,
			total: total,
			error: error,
			fileInfo: fileInfo
		)
	}
	
}


extension UploadFromURLStatus: CustomDebugStringConvertible {
	public var debugDescription: String {
		return """
		\(type(of: self)):
			status: \(status),
			done: \(String(describing: done)),
			total: \(String(describing: total)),
			error: \(String(describing: error)),
			fileInfo: \(String(describing: fileInfo))
		"""
	}
}
