//
//  UploadedFilesGroup.swift
//  
//
//  Created by Sergei Armodin on 13.02.2020.
//

import Foundation


/// Uploaded Files group info
public struct UploadedFilesGroup: Codable {
	
	/// Date and time when a group was created.
	public var datetimeCreated: Date
	
	/// Date and time when files in a group were stored.
	public var datetimeStored: Date?
	
	/// Number of files in a group.
	public var filesCount: Int
	
	/// Public CDN URL for a group.
	public var cdnUrl: String
	
	/// List of files in a group. Deleted files are represented as null to always preserve a number of files in a group in line with a group ID. This property is not available for group lists.
	public var files: [UploadedFile]?
	
	/// API resource URL for a group.
	public var url: String
	
	/// Group identifier.
	public var id: String
	
	
	enum CodingKeys: String, CodingKey {
		case datetimeCreated = "datetime_created"
		case datetimeStored = "datetime_stored"
		case filesCount = "files_count"
		case cdnUrl = "cdn_url"
		case files
		case url
		case id
	}
	
	
	init(
		datetimeCreated: Date,
		datetimeStored: Date?,
		filesCount: Int,
		cdnUrl: String,
		files: [UploadedFile]?,
		url: String,
		id: String
	) {
		self.datetimeCreated = datetimeCreated
		self.datetimeStored = datetimeStored
		self.filesCount = filesCount
		self.cdnUrl = cdnUrl
		self.files = files
		self.url = url
		self.id = id
	}
	
	public init(from decoder: Decoder) throws {
		let container = try decoder.container(keyedBy: CodingKeys.self)
		
		var datetimeCreated = Date(timeIntervalSince1970: 0)
		var datetimeStored: Date? = nil
		
		let dateFormatter = DateFormatter()
		dateFormatter.locale = Locale(identifier: "en_US_POSIX")
		dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZ"
		
		let datetimeCreatedString = try container.decodeIfPresent(String.self, forKey: .datetimeCreated)
		let datetimeStoredString = try container.decodeIfPresent(String.self, forKey: .datetimeStored)
		
		if let val = datetimeCreatedString, let date = dateFormatter.date(from: val) {
			datetimeCreated = date
		}
		if let val = datetimeStoredString {
			datetimeStored = dateFormatter.date(from: val)
		}
		
		let filesCount = try container.decodeIfPresent(Int.self, forKey: .filesCount) ?? 1
		let cdnUrl = try container.decodeIfPresent(String.self, forKey: .cdnUrl) ?? ""
		let files = try container.decodeIfPresent([UploadedFile].self, forKey: .files)
		let url = try container.decodeIfPresent(String.self, forKey: .url) ?? ""
		let id = try container.decodeIfPresent(String.self, forKey: .id) ?? ""
		
		self.init(
			datetimeCreated: datetimeCreated,
			datetimeStored: datetimeStored,
			filesCount: filesCount,
			cdnUrl: cdnUrl,
			files: files,
			url: url,
			id: id
		)
	}
	
}



extension UploadedFilesGroup: CustomDebugStringConvertible {
	public var debugDescription: String {
		return """
		\(type(of: self)):
			datetimeCreated: \(datetimeCreated)
			datetimeStored: \(String(describing: datetimeStored))
			filesCount: \(filesCount)
			cdnUrl: \(cdnUrl)
			files: \(String(describing: files))
			url: \(url)
			id: \(id)
		"""
	}
}
