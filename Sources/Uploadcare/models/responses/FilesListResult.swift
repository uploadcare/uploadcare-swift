//
//  File.swift
//  
//
//  Created by Sergey Armodin on 03.02.2020.
//

import Foundation


public struct FilesListResult: Codable {
	
	/// Date and time when a file was removed, if any.
	public var datetimeRemoved: Date?
	/// Date and time of the last store request, if any.
	public var datetimeStored: Date?
	/// Date and time when a file was uploaded.
	public var datetimeUploaded: Date?
	/// Publicly available file CDN URL. Available if a file is not deleted.
	public var originalFileUrl: String?
	/// API resource URL for a particular file.
	public var url: String?
	/// Dictionary of other files that has been created using this file as source. Used for video, document and etc. conversion.
	public var variations: [String: String]?
	/// File info
	public var fileInfo: FileInfo?
	
	
	enum CodingKeys: String, CodingKey {
		case datetimeRemoved = "datetime_removed"
		case datetimeStored = "datetime_stored"
		case datetimeUploaded = "datetime_uploaded"
		case originalFileUrl = "original_file_url"
		case url
		case variations
	}
	
	
	init(
		datetimeRemoved: Date?,
		datetimeStored: Date?,
		datetimeUploaded: Date?,
		originalFileUrl: String?,
		url: String?,
		variations: [String: String]?,
		fileInfo: FileInfo?
	) {
		self.datetimeRemoved = datetimeRemoved
		self.datetimeStored = datetimeStored
		self.datetimeUploaded = datetimeUploaded
		self.originalFileUrl = originalFileUrl
		self.url = url
		self.fileInfo = fileInfo
	}

	public init(from decoder: Decoder) throws {
		let container = try decoder.container(keyedBy: CodingKeys.self)

		var datetimeRemoved: Date? = nil
		var datetimeStored: Date? = nil
		var datetimeUploaded: Date? = nil
		
		let dateFormatter = DateFormatter()
		dateFormatter.locale = Locale(identifier: "en_US_POSIX")
		dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZ"
		
		let datetimeRemovedString = try container.decodeIfPresent(String.self, forKey: .datetimeRemoved)
		let datetimeStoredString = try container.decodeIfPresent(String.self, forKey: .datetimeStored)
		let datetimeUploadedString = try container.decodeIfPresent(String.self, forKey: .datetimeUploaded)
		
		if let val = datetimeRemovedString {
			datetimeRemoved = dateFormatter.date(from: val)
		}
		if let val = datetimeStoredString {
			datetimeStored = dateFormatter.date(from: val)
		}
		if let val = datetimeUploadedString {
			datetimeUploaded = dateFormatter.date(from: val)
		}
		
		let originalFileUrl = try container.decodeIfPresent(String.self, forKey: .originalFileUrl)
		let url = try container.decodeIfPresent(String.self, forKey: .url)
		let variations = try container.decodeIfPresent([String: String].self, forKey: .variations)
		
		let fileInfo = try? FileInfo(from: decoder)

		self.init(
			datetimeRemoved: datetimeRemoved,
			datetimeStored: datetimeStored,
			datetimeUploaded: datetimeUploaded,
			originalFileUrl: originalFileUrl,
			url: url,
			variations: variations,
			fileInfo: fileInfo
		)
	}
	
}
